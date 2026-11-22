import 'package:drift/drift.dart';

import '../../../features/assets/domain/asset_quantity.dart';

// Drift requires literal SQL checks. These bounds match Rial and AssetQuantity.
@DataClassName('ObligationRow')
class Obligations extends Table {
  TextColumn get id => text()();
  TextColumn get counterparty => text().withLength(min: 1, max: 100)();
  BoolColumn get isReceivable => boolean()();
  IntColumn get amountRial => integer()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (typeof(amount_rial) = 'integer' AND "
        'amount_rial BETWEEN 1 AND 900000000000000000)',
  ];
}

@DataClassName('ObligationPaymentRow')
@TableIndex(name: 'idx_obligation_payments_parent', columns: {#obligationId})
class ObligationPayments extends Table {
  TextColumn get id => text()();
  TextColumn get obligationId =>
      text().references(Obligations, #id, onDelete: KeyAction.cascade)();
  IntColumn get amountRial => integer()();
  DateTimeColumn get paidOn => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (typeof(amount_rial) = 'integer' AND "
        'amount_rial BETWEEN 1 AND 900000000000000000)',
  ];
}

@DataClassName('AssetHoldingRow')
class AssetHoldings extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get kind => textEnum<AssetKind>()();
  TextColumn get currencyCode => text().nullable()();
  IntColumn get quantityMicros => integer()();
  IntColumn get rateRial => integer().nullable()();
  DateTimeColumn get rateDate => dateTime().nullable()();
  BoolColumn get isMarketRate => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<String> get customConstraints => [
    "CHECK (typeof(quantity_micros) = 'integer' AND "
        'quantity_micros BETWEEN 1 AND 9000000000000000)',
    "CHECK (rate_rial IS NULL OR (typeof(rate_rial) = 'integer' AND "
        'rate_rial BETWEEN 1 AND 900000000000000000))',
    "CHECK ((kind IN ('gold', 'silver') AND currency_code IS NULL) OR "
        "(kind = 'currency' AND currency_code IS NOT NULL AND "
        "currency_code GLOB '[A-Z][A-Z][A-Z]') OR "
        "(kind = 'crypto' AND currency_code IS NOT NULL AND "
        "currency_code GLOB '[A-Z][A-Z][A-Z]*'))",
    'CHECK ((rate_rial IS NULL) = (rate_date IS NULL))',
    'CHECK (is_market_rate = 0 OR rate_rial IS NOT NULL)',
  ];

  @override
  Set<Column<Object>> get primaryKey => {id};
}
