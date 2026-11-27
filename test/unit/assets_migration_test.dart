import 'dart:io';

import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/assets/domain/asset_quantity.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _insert =
    'INSERT INTO asset_holdings '
    '(id, name, kind, currency_code, quantity_micros, rate_rial, rate_date, '
    'is_market_rate, created_at) VALUES ';

void main() {
  test('a version 5 database gains crypto holdings and keeps its rows', () async {
    final directory = await Directory.systemTemp.createTemp('daram-assets-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/daram.sqlite');

    // Capture the current schema, then rebuild the table with the pre-crypto
    // rule so reopening the file exercises the 5 -> 6 migration.
    final probe = AppDatabase(NativeDatabase(file));
    final String createV6;
    try {
      createV6 =
          (await probe
                  .customSelect(
                    "SELECT sql FROM sqlite_master WHERE type = 'table' "
                    "AND name = 'asset_holdings'",
                  )
                  .getSingle())
              .read<String>('sql');
    } finally {
      await probe.close();
    }
    final createV5 = createV6.replaceFirst(
      RegExp(r" OR \(kind = 'crypto'[^()]*\)"),
      '',
    );
    expect(createV5, isNot(contains('crypto')));

    final before = AppDatabase(NativeDatabase(file));
    try {
      await before.customStatement('DROP TABLE asset_holdings');
      await before.customStatement(createV5);
      await before.customStatement(
        '$_insert'
        "('gold', 'طلای من', 'gold', NULL, 2500000, NULL, NULL, 0, 1730000000)",
      );
      await before.customStatement(
        '$_insert'
        "('usd', 'دلار', 'currency', 'USD', 10000000, NULL, NULL, 0, 1730000000)",
      );
      await before.customStatement('PRAGMA user_version = 5');
    } finally {
      await before.close();
    }

    final migrated = AppDatabase(NativeDatabase(file));
    addTearDown(migrated.close);
    final rows = await migrated.select(migrated.assetHoldings).get();
    expect(rows.map((row) => row.name), ['طلای من', 'دلار']);
    expect(rows.map((row) => row.currencyCode), [null, 'USD']);
    expect(rows.first.quantityMicros, 2500000);

    // The rebuilt table accepts crypto codes...
    await migrated.customStatement(
      '$_insert'
      "('btc', 'بیت‌کوین', 'crypto', 'BTC', 50000, NULL, NULL, 0, 1730000000)",
    );
    final coin = (await migrated.select(migrated.assetHoldings).get())
        .singleWhere((row) => row.kind == AssetKind.crypto);
    expect(coin.currencyCode, 'BTC');

    // ...but still requires one.
    await expectLater(
      migrated.customStatement(
        '$_insert'
        "('bad', 'بدون کد', 'crypto', NULL, 1000000, NULL, NULL, 0, 1730000000)",
      ),
      throwsA(anything),
    );
  });
}
