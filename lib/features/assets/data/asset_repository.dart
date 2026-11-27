import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/mappers.dart';
import '../domain/asset_holding.dart';
import '../domain/asset_quantity.dart';

class AssetRepository {
  AssetRepository(this._db);

  final AppDatabase _db;

  Stream<List<AssetHoldingRow>> watch() =>
      (_db.select(_db.assetHoldings)..orderBy([
            (row) => OrderingTerm.desc(row.createdAt),
            (row) => OrderingTerm.asc(row.id),
          ]))
          .watch();

  /// Domain holdings ordered like the assets screen.
  Future<List<AssetHolding>> list() async {
    final rows =
        await (_db.select(_db.assetHoldings)..orderBy([
              (row) => OrderingTerm.desc(row.createdAt),
              (row) => OrderingTerm.asc(row.id),
            ]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<AssetHolding?> findById(String id) async {
    final row = await (_db.select(
      _db.assetHoldings,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<void> save({
    String? id,
    required String name,
    required AssetKind kind,
    required AssetQuantity quantity,
    String? currencyCode,
    Rial? rate,
    DateTime? rateDate,
    bool isMarketRate = false,
  }) async {
    final title = name.trim();
    if (title.isEmpty || title.length > 100) {
      throw const ValidationException('نام دارایی را وارد کنید.');
    }
    final code = kind.hasCode ? currencyCode?.trim().toUpperCase() : null;
    if (kind == AssetKind.currency &&
        (code == null || !RegExp(r'^[A-Z]{3}$').hasMatch(code))) {
      throw const ValidationException('کد سه‌حرفی ارز را وارد کنید.');
    }
    if (kind == AssetKind.crypto &&
        (code == null || !RegExp(r'^[A-Z]{3,10}$').hasMatch(code))) {
      throw const ValidationException('نماد رمزارز را وارد کنید.');
    }
    if ((rate == null) != (rateDate == null) ||
        (rate != null && rate.value <= 0) ||
        (isMarketRate && rate == null)) {
      throw const ValidationException('نرخ و تاریخ آن را بررسی کنید.');
    }
    if (rate != null) quantity.valueAt(rate);

    final values = AssetHoldingsCompanion(
      name: Value(title),
      kind: Value(kind),
      currencyCode: Value(code),
      quantityMicros: Value(quantity.micros),
      rateRial: Value(rate?.value),
      rateDate: Value(rateDate?.toUtc()),
      isMarketRate: Value(isMarketRate),
    );
    if (id == null) {
      await _db
          .into(_db.assetHoldings)
          .insert(
            values.copyWith(
              id: Value(const Uuid().v4()),
              createdAt: Value(DateTime.now().toUtc()),
            ),
          );
    } else {
      final updated = await (_db.update(
        _db.assetHoldings,
      )..where((row) => row.id.equals(id))).write(values);
      if (updated == 0) {
        throw const NotFoundException('این دارایی پیدا نشد.');
      }
    }
  }

  Future<void> delete(String id) async {
    await (_db.delete(
      _db.assetHoldings,
    )..where((row) => row.id.equals(id))).go();
  }
}
