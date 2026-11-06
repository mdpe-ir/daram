import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/iranian_banks.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/mappers.dart';
import '../../transactions/data/operation_repository.dart';
import '../domain/account.dart';

/// Reads and writes accounts. Balances come from the ledger, never from a
/// duplicated column.
class AccountRepository {
  AccountRepository(this._db, this._operations);

  final AppDatabase _db;
  final OperationRepository _operations;
  static const _uuid = Uuid();

  Future<List<AccountWithBalance>> listWithBalances({
    bool includeArchived = false,
  }) async {
    final rows = await _balanceQuery(includeArchived: includeArchived).get();
    return rows.map(_mapBalanceRow).toList();
  }

  Stream<List<AccountWithBalance>> watchWithBalances({
    bool includeArchived = false,
  }) =>
      _balanceQuery(includeArchived: includeArchived)
          .watch()
          .map((rows) => rows.map(_mapBalanceRow).toList());

  Selectable<QueryRow> _balanceQuery({required bool includeArchived}) {
    final where = includeArchived ? '' : 'WHERE a.archived_at IS NULL';
    return _db.customSelect(
      '''
      SELECT a.*, (a.initial_balance_rial + COALESCE(SUM(l.delta_rial), 0)) AS balance_rial
      FROM accounts a
      LEFT JOIN ledger_entries l ON l.account_id = a.id
      $where
      GROUP BY a.id
      ORDER BY a.created_at ASC
      ''',
      readsFrom: {_db.accounts, _db.ledgerEntries},
    );
  }

  AccountWithBalance _mapBalanceRow(QueryRow row) {
    final account = Account(
      id: row.read<String>('id'),
      bankId: row.read<String>('bank_id'),
      bankName: row.read<String>('bank_name'),
      accountName: row.read<String>('account_name'),
      accountType: AccountType.fromStorage(row.read<String>('account_type')),
      initialBalanceRial: Rial(row.read<int>('initial_balance_rial')),
      cardLastFour: row.read<String?>('card_last_four'),
      description: row.read<String?>('description'),
      createdAt: row.read<DateTime>('created_at').toUtc(),
      archivedAt: row.read<DateTime?>('archived_at')?.toUtc(),
    );
    return AccountWithBalance(
      account: account,
      balance: Rial(row.read<int>('balance_rial')),
    );
  }

  Future<List<Account>> list({bool includeArchived = false}) async {
    final query = _db.select(_db.accounts)
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    if (!includeArchived) {
      query.where((table) => table.archivedAt.isNull());
    }
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Stream<List<Account>> watch({bool includeArchived = false}) {
    final query = _db.select(_db.accounts)
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    if (!includeArchived) {
      query.where((table) => table.archivedAt.isNull());
    }
    return query.watch().map(
      (rows) => rows.map((row) => row.toDomain()).toList(),
    );
  }

  Future<Account?> findById(String? id) async {
    if (id == null) return null;
    final row = await (_db.select(
      _db.accounts,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<AccountWithBalance?> balanceOf(String id) async {
    final rows = await _balanceQuery(includeArchived: true).get();
    for (final row in rows) {
      if (row.read<String>('id') == id) return _mapBalanceRow(row);
    }
    return null;
  }

  /// Resolves an account from an id, name fragment or bank name.
  ///
  /// Used by the AI tools, which may receive "ملت" instead of an account id.
  Future<Account?> resolve(String? reference) async {
    if (reference == null || reference.trim().isEmpty) return null;
    final direct = await findById(reference);
    if (direct != null) return direct;

    final normalized = _normalize(reference);
    final accounts = await list();
    for (final account in accounts) {
      if (_normalize(account.accountName) == normalized) return account;
    }
    for (final account in accounts) {
      final name = _normalize(account.accountName);
      final bank = _normalize(account.bankName);
      if (name.contains(normalized) || normalized.contains(name)) {
        return account;
      }
      if (bank.contains(normalized) || normalized.contains(bank)) {
        return account;
      }
    }
    final bank = bankByName(reference);
    if (bank != null) {
      for (final account in accounts) {
        if (account.bankId == bank.id) return account;
      }
    }
    return null;
  }

  /// Creates an account idempotently, keyed by [operationId].
  Future<Account> create({
    required String bankId,
    required String bankName,
    required String accountName,
    required AccountType accountType,
    required Rial initialBalance,
    required String operationId,
    String? cardLastFour,
    String? description,
    String? id,
  }) async {
    final trimmedName = accountName.trim();
    if (trimmedName.isEmpty) {
      throw const ValidationException('نام حساب را وارد کنید.');
    }
    final digits = cardLastFour?.trim();
    if (digits != null &&
        digits.isNotEmpty &&
        !RegExp(r'^\d{4}$').hasMatch(digits)) {
      throw const ValidationException('چهار رقم آخر کارت باید عدد باشد.');
    }

    final trimmedBankName = bankName.trim();
    final knownBank =
        bankByName(trimmedBankName) ??
        (bankId == 'other' ? null : bankByName(bankById(bankId).nameFa));
    final bank = knownBank ?? bankById(bankId);
    final resolvedBankName =
        knownBank?.nameFa ??
        (trimmedBankName.isNotEmpty ? trimmedBankName : bank.nameFa);
    final accountId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();

    return _db.transaction(() async {
      final existing = await _operations.find(operationId);
      if (existing != null) {
        final account = await findById(existing.entityId);
        if (account != null) return account;
      }

      await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: accountId,
              bankId: bank.id,
              bankName: resolvedBankName,
              accountName: trimmedName,
              accountType: accountType,
              initialBalanceRial: initialBalance.value,
              cardLastFour: Value(digits?.isEmpty ?? true ? null : digits),
              description: Value(description?.trim()),
              createdAt: now,
            ),
          );

      await _operations.record(
        operationId: operationId,
        kind: FinancialOperationKind.addAccount,
        entityId: accountId,
        summary: 'افزودن حساب $trimmedName ($resolvedBankName)',
        payload: {'accountId': accountId},
      );

      return Account(
        id: accountId,
        bankId: bank.id,
        bankName: resolvedBankName,
        accountName: trimmedName,
        accountType: accountType,
        initialBalanceRial: initialBalance,
        cardLastFour: (digits?.isEmpty ?? true) ? null : digits,
        description: description?.trim(),
        createdAt: now,
      );
    });
  }

  Future<void> update({
    required String id,
    String? accountName,
    AccountType? accountType,
    String? cardLastFour,
    String? description,
    String? bankId,
    String? bankName,
  }) async {
    final account = await findById(id);
    if (account == null) throw const NotFoundException('حساب پیدا نشد.');
    final targetBankId = bankId ?? account.bankId;
    final targetBankName = (bankName ?? account.bankName).trim();
    final knownBank =
        bankByName(targetBankName) ??
        (targetBankId == 'other'
            ? null
            : bankByName(bankById(targetBankId).nameFa));
    final targetBank = knownBank ?? bankById(targetBankId);
    final resolvedBankName =
        knownBank?.nameFa ??
        (targetBankName.isNotEmpty ? targetBankName : targetBank.nameFa);
    final name = accountName?.trim();
    if (name != null && name.isEmpty) {
      throw const ValidationException('نام حساب را وارد کنید.');
    }
    final digits = cardLastFour?.trim();
    if (digits != null &&
        digits.isNotEmpty &&
        !RegExp(r'^\d{4}$').hasMatch(digits)) {
      throw const ValidationException('چهار رقم آخر کارت باید عدد باشد.');
    }
    await (_db.update(
      _db.accounts,
    )..where((table) => table.id.equals(id))).write(
      AccountsCompanion(
        accountName: name != null ? Value(name) : const Value.absent(),
        accountType: accountType != null
            ? Value(accountType)
            : const Value.absent(),
        cardLastFour: Value((digits?.isEmpty ?? true) ? null : digits),
        description: Value(description?.trim()),
        bankId: Value(targetBank.id),
        bankName: Value(resolvedBankName),
      ),
    );
  }

  /// Archives an account. Transactions stay intact for history.
  Future<void> archive(String id) async {
    final account = await findById(id);
    if (account == null) throw const NotFoundException('حساب پیدا نشد.');
    await (_db.update(_db.accounts)..where((table) => table.id.equals(id)))
        .write(AccountsCompanion(archivedAt: Value(DateTime.now().toUtc())));
  }

  Future<void> unarchive(String id) async {
    await (_db.update(_db.accounts)..where((table) => table.id.equals(id)))
        .write(const AccountsCompanion(archivedAt: Value(null)));
  }

  String _normalize(String value) => value
      .replaceAll('بانک', '')
      .replaceAll('حساب', '')
      .replaceAll('‌', '')
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(' ', '')
      .trim();
}
