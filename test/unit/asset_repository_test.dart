import 'package:daram/core/errors/app_exception.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/assets/data/asset_repository.dart';
import 'package:daram/features/assets/domain/asset_quantity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AssetRepository repository;

  setUp(() {
    db = AppDatabase.memory();
    repository = AssetRepository(db);
  });

  tearDown(() => db.close());

  test('saves bullion, currency and crypto holdings', () async {
    await repository.save(
      name: 'طلای من',
      kind: AssetKind.gold,
      quantity: AssetQuantity.tryParse('2.5')!,
      rate: Rial(1000),
      rateDate: DateTime.utc(2026, 11, 20),
    );
    await repository.save(
      name: 'دلار',
      kind: AssetKind.currency,
      currencyCode: 'usd',
      quantity: AssetQuantity.tryParse('10')!,
    );
    await repository.save(
      name: 'بیت‌کوین',
      kind: AssetKind.crypto,
      currencyCode: 'btc',
      quantity: AssetQuantity.tryParse('0.05')!,
      rate: Rial(20000000000),
      rateDate: DateTime.utc(2026, 11, 20),
    );
    await repository.save(
      name: 'تتر',
      kind: AssetKind.crypto,
      currencyCode: 'USDT',
      quantity: AssetQuantity.tryParse('100')!,
    );

    final rows = await repository.watch().first;
    expect(rows, hasLength(4));
    final gold = rows.singleWhere((row) => row.kind == AssetKind.gold);
    expect(gold.currencyCode, isNull);
    final usd = rows.singleWhere((row) => row.currencyCode == 'USD');
    expect(usd.kind, AssetKind.currency);
    final btc = rows.singleWhere((row) => row.currencyCode == 'BTC');
    expect(btc.kind, AssetKind.crypto);
    expect(btc.name, 'بیت‌کوین');
    expect(btc.rateRial, 20000000000);
    expect(rows.any((row) => row.currencyCode == 'USDT'), isTrue);
  });

  test('rejects codes that do not match the kind', () async {
    final quantity = AssetQuantity.tryParse('1')!;
    await expectLater(
      repository.save(
        name: 'ارز',
        kind: AssetKind.currency,
        currencyCode: 'USDT',
        quantity: quantity,
      ),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      repository.save(
        name: 'رمزارز',
        kind: AssetKind.crypto,
        currencyCode: 'US',
        quantity: quantity,
      ),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      repository.save(
        name: 'رمزارز',
        kind: AssetKind.crypto,
        quantity: quantity,
      ),
      throwsA(isA<ValidationException>()),
    );
    await expectLater(
      repository.save(
        name: 'رمزارز',
        kind: AssetKind.crypto,
        currencyCode: 'ABCDEFGHIJK',
        quantity: quantity,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('crypto rows survive a delete and keep their symbol', () async {
    await repository.save(
      name: 'سولانا',
      kind: AssetKind.crypto,
      currencyCode: 'sol',
      quantity: AssetQuantity.tryParse('3')!,
    );
    final row = (await repository.watch().first).single;
    expect(row.currencyCode, 'SOL');
    await repository.delete(row.id);
    expect(await repository.watch().first, isEmpty);
  });
}
