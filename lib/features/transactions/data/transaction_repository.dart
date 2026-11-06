import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/mappers.dart';
import '../../accounts/domain/account.dart';
import '../domain/transaction_record.dart';
import 'operation_repository.dart';

/// Reads and writes income/expense records and their ledger movements.
class TransactionRepository {
  TransactionRepository(this._db, this._operations);

  final AppDatabase _db;
  final OperationRepository _operations;
  static const _uuid = Uuid();

  /// Creates a transaction idempotently, inside one database transaction.
  Future<TransactionRecord> create({
    required TransactionType type,
    required Rial amount,
    required String accountId,
    required CalendarDate date,
    required String operationId,
    String? categoryId,
    String? description,
    String? id,
  }) async {
    if (amount <= Rial.zero) {
      throw const ValidationException('مبلغ باید بزرگ‌تر از صفر باشد.');
    }
    final account = await _account(accountId);
    final category = await _validateCategory(categoryId, type);
    final transactionId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();

    return _db.transaction(() async {
      final existing = await _operations.find(operationId);
      if (existing != null) {
        final record = await findById(existing.entityId);
        if (record != null) return record;
      }

      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: transactionId,
              type: type,
              amountRial: amount.value,
              categoryId: Value(category?.id),
              accountId: accountId,
              transactionDate: date.stored,
              description: Value(description?.trim()),
              operationId: operationId,
              createdAt: now,
              updatedAt: now,
            ),
          );

      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              accountId: accountId,
              deltaRial: type == TransactionType.income
                  ? amount.value
                  : -amount.value,
              entryDate: date.stored,
              sourceType: LedgerSource.transaction,
              sourceId: transactionId,
              operationId: operationId,
              createdAt: now,
            ),
          );

      final summary =
          '${type.labelFa} ${MoneyFormatter().format(amount)} در ${account.accountName}';
      await _operations.record(
        operationId: operationId,
        kind: FinancialOperationKind.addTransaction,
        entityId: transactionId,
        summary: summary,
        payload: {
          'transactionId': transactionId,
          'accountId': accountId,
          'amountRial': amount.value,
          'type': type.name,
          'date': date.toIso(),
        },
      );

      return TransactionRecord(
        id: transactionId,
        type: type,
        amountRial: amount,
        categoryId: category?.id,
        accountId: accountId,
        transactionDate: date.stored,
        description: description?.trim(),
        operationId: operationId,
        createdAt: now,
        updatedAt: now,
        accountName: account.accountName,
        categoryName: category?.name,
        categoryColorHex: category?.colorHex,
        categoryIcon: category?.icon,
      );
    });
  }

  /// Edits a transaction and rewrites its ledger entry atomically.
  Future<void> update({
    required String id,
    TransactionType? type,
    Rial? amount,
    String? accountId,
    String? categoryId,
    CalendarDate? date,
    String? description,
    bool clearCategory = false,
  }) async {
    final current = await findById(id);
    if (current == null) throw const NotFoundException('تراکنش پیدا نشد.');
    if (current.operationId?.endsWith(':fee') ?? false) {
      throw const ValidationException(
        'کارمزد بخشی از یک انتقال است؛ برای اصلاح، انتقال را حذف و دوباره ثبت کن.',
      );
    }

    final newType = type ?? current.type;
    final newAmount = amount ?? current.amountRial;
    final newAccountId = accountId ?? current.accountId;
    final newDate = date ?? CalendarDate.fromStored(current.transactionDate);
    final newCategoryId = clearCategory
        ? null
        : (categoryId ?? current.categoryId);

    if (newAmount <= Rial.zero) {
      throw const ValidationException('مبلغ باید بزرگ‌تر از صفر باشد.');
    }
    await _account(newAccountId);
    final category = await _validateCategory(newCategoryId, newType);
    final now = DateTime.now().toUtc();

    await _db.transaction(() async {
      await (_db.delete(_db.ledgerEntries)..where(
            (table) =>
                table.sourceType.equalsValue(LedgerSource.transaction) &
                table.sourceId.equals(id),
          ))
          .go();

      await (_db.update(
        _db.transactions,
      )..where((table) => table.id.equals(id))).write(
        TransactionsCompanion(
          type: Value(newType),
          amountRial: Value(newAmount.value),
          accountId: Value(newAccountId),
          categoryId: Value(category?.id),
          transactionDate: Value(newDate.stored),
          description: Value(description?.trim() ?? current.description),
          updatedAt: Value(now),
        ),
      );

      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              accountId: newAccountId,
              deltaRial: newType == TransactionType.income
                  ? newAmount.value
                  : -newAmount.value,
              entryDate: newDate.stored,
              sourceType: LedgerSource.transaction,
              sourceId: id,
              operationId: 'edit_$id-${now.millisecondsSinceEpoch}',
              createdAt: now,
            ),
          );
    });
  }

  /// Deletes a transaction and its ledger movement.
  Future<void> delete(String id) async {
    final current = await findById(id);
    if (current == null) throw const NotFoundException('تراکنش پیدا نشد.');
    if (current.operationId?.endsWith(':fee') ?? false) {
      throw const ValidationException(
        'کارمزد بخشی از یک انتقال است؛ برای حذف آن، انتقال را حذف کن.',
      );
    }
    await _db.transaction(() async {
      await (_db.delete(_db.ledgerEntries)..where(
            (table) =>
                table.sourceType.equalsValue(LedgerSource.transaction) &
                table.sourceId.equals(id),
          ))
          .go();
      await (_db.delete(
        _db.transactions,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<TransactionRecord?> findById(String id) async {
    final query = _joinQuery()..where(_db.transactions.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _map(row);
  }

  Future<List<TransactionRecord>> list(TransactionFilter filter) async {
    final rows = await _filteredQuery(filter).get();
    return rows.map(_map).toList();
  }

  Stream<List<TransactionRecord>> watch(TransactionFilter filter) =>
      _filteredQuery(filter).watch().map((rows) => rows.map(_map).toList());

  Future<List<TransactionRecord>> recent({int limit = 5}) =>
      list(TransactionFilter(limit: limit));

  JoinedSelectStatement _joinQuery() {
    return _db.select(_db.transactions).join([
      innerJoin(
        _db.accounts,
        _db.accounts.id.equalsExp(_db.transactions.accountId),
      ),
      leftOuterJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.transactions.categoryId),
      ),
    ]);
  }

  JoinedSelectStatement _filteredQuery(TransactionFilter filter) {
    final query = _joinQuery();
    final conditions = <Expression<bool>>[];

    if (filter.start != null) {
      conditions.add(
        _db.transactions.transactionDate.isBiggerOrEqualValue(
          _dateOnly(filter.start!),
        ),
      );
    }
    if (filter.end != null) {
      conditions.add(
        _db.transactions.transactionDate.isSmallerThanValue(
          _dateOnly(filter.end!).add(const Duration(days: 1)),
        ),
      );
    }
    if (filter.type != null) {
      conditions.add(_db.transactions.type.equalsValue(filter.type!));
    }
    if (filter.accountId != null) {
      conditions.add(_db.transactions.accountId.equals(filter.accountId!));
    }
    if (filter.categoryId != null) {
      conditions.add(_db.transactions.categoryId.equals(filter.categoryId!));
    }
    if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
      final term = '%${filter.searchQuery!.trim()}%';
      conditions.add(
        _db.transactions.description.like(term) |
            _db.accounts.accountName.like(term) |
            _db.categories.name.like(term),
      );
    }

    for (final condition in conditions) {
      query.where(condition);
    }
    query.orderBy([
      OrderingTerm.desc(_db.transactions.transactionDate),
      OrderingTerm.desc(_db.transactions.createdAt),
    ]);
    if (filter.limit != null) {
      query.limit(filter.limit!, offset: filter.offset);
    }
    return query;
  }

  TransactionRecord _map(TypedResult row) {
    final transaction = row.readTable(_db.transactions);
    final account = row.readTable(_db.accounts);
    final category = row.readTableOrNull(_db.categories);
    return transaction.toDomain(
      accountName: account.accountName,
      category: category,
    );
  }

  Future<Account> _account(String id) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundException('حساب انتخاب‌شده پیدا نشد.');
    if (row.archivedAt != null) {
      throw const ValidationException('حساب انتخاب‌شده بایگانی شده است.');
    }
    return row.toDomain();
  }

  Future<CategoryRow?> _validateCategory(
    String? categoryId,
    TransactionType type,
  ) async {
    if (categoryId == null) return null;
    final row = await (_db.select(
      _db.categories,
    )..where((table) => table.id.equals(categoryId))).getSingleOrNull();
    if (row == null) {
      throw const NotFoundException('دسته‌بندی انتخاب‌شده پیدا نشد.');
    }
    final expected = type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    if (row.type != expected) {
      throw const ValidationException(
        'دسته‌بندی انتخاب‌شده با نوع تراکنش هم‌خوانی ندارد.',
      );
    }
    return row;
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime.utc(value.year, value.month, value.day);
}
