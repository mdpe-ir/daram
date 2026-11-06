import 'package:drift/drift.dart';

import '../../../core/domain/enums.dart';

/// User-owned accounts. Balances are never stored here: they are derived from
/// [LedgerEntries] plus [initialBalanceRial].
@DataClassName('AccountRow')
@TableIndex(name: 'idx_accounts_bank', columns: {#bankId})
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get bankId => text()();
  TextColumn get bankName => text()();
  TextColumn get accountName => text()();
  TextColumn get accountType => textEnum<AccountType>()();
  IntColumn get initialBalanceRial => integer()();
  TextColumn get cardLastFour => text().nullable()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Editable income/expense categories; defaults are seeded on first launch.
@DataClassName('CategoryRow')
@TableIndex(name: 'idx_categories_type', columns: {#type})
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<CategoryType>()();
  TextColumn get icon => text()();
  TextColumn get colorHex => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Income and expense records. Transfers live in [Transfers].
@DataClassName('TransactionRow')
@TableIndex(name: 'idx_transactions_date', columns: {#transactionDate})
@TableIndex(name: 'idx_transactions_account', columns: {#accountId})
@TableIndex(name: 'idx_transactions_category', columns: {#categoryId})
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<TransactionType>()();
  IntColumn get amountRial => integer()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get description => text().nullable()();

  /// Idempotency key of the operation that created this row.
  TextColumn get operationId => text().unique()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Transfers between two accounts owned by the user.
@DataClassName('TransferRow')
@TableIndex(name: 'idx_transfers_date', columns: {#transferDate})
class Transfers extends Table {
  TextColumn get id => text()();
  @ReferenceName('outgoingTransfers')
  TextColumn get sourceAccountId => text().references(Accounts, #id)();
  @ReferenceName('incomingTransfers')
  TextColumn get destinationAccountId => text().references(Accounts, #id)();
  IntColumn get amountRial => integer()();
  IntColumn get feeRial => integer().withDefault(const Constant(0))();
  DateTimeColumn get transferDate => dateTime()();
  TextColumn get description => text().nullable()();
  TextColumn get operationId => text().unique()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Every balance movement, written atomically with its source record.
///
/// This is the single source of truth for account balances; it keeps the
/// ledger auditable and makes undo a matter of removing one operation's rows.
@DataClassName('LedgerEntryRow')
@TableIndex(name: 'idx_ledger_account', columns: {#accountId})
@TableIndex(name: 'idx_ledger_source', columns: {#sourceType, #sourceId})
@TableIndex(name: 'idx_ledger_operation', columns: {#operationId})
class LedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get accountId => text().references(Accounts, #id)();
  IntColumn get deltaRial => integer()();
  DateTimeColumn get entryDate => dateTime()();
  TextColumn get sourceType => textEnum<LedgerSource>()();
  TextColumn get sourceId => text()();
  TextColumn get operationId => text()();
  DateTimeColumn get createdAt => dateTime()();
}

/// Loans. Principal and outstanding liability are tracked separately from
/// income, and disbursement is never classified as income.
@DataClassName('LoanRow')
class Loans extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get principalAmountRial => integer()();
  IntColumn get interestAmountRial =>
      integer().withDefault(const Constant(0))();
  IntColumn get installmentCount => integer()();
  IntColumn get installmentAmountRial => integer()();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  DateTimeColumn get startDate => dateTime()();
  TextColumn get status => textEnum<LoanStatus>()();
  TextColumn get description => text().nullable()();
  TextColumn get operationId => text().unique()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Installments generated deterministically when a loan is created.
@DataClassName('InstallmentRow')
@TableIndex(name: 'idx_installments_loan', columns: {#loanId})
@TableIndex(name: 'idx_installments_due', columns: {#dueDate})
class Installments extends Table {
  TextColumn get id => text()();
  TextColumn get loanId => text().references(Loans, #id)();
  IntColumn get installmentNumber => integer()();
  DateTimeColumn get dueDate => dateTime()();
  IntColumn get amountRial => integer()();
  IntColumn get principalRial => integer()();
  IntColumn get interestRial => integer().withDefault(const Constant(0))();
  TextColumn get status => textEnum<InstallmentStatus>()();
  IntColumn get paidAmountRial => integer().withDefault(const Constant(0))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
