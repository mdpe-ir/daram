import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/mappers.dart';
import '../domain/loan.dart';
import '../domain/loan_calculator.dart';
import '../../transactions/data/operation_repository.dart';

/// Reads and writes loans, their schedule and installment payments.
class LoanRepository {
  LoanRepository(this._db, this._operations);

  final AppDatabase _db;
  final OperationRepository _operations;
  static const _uuid = Uuid();

  /// Creates a loan and its schedule atomically.
  ///
  /// The disbursed principal increases the account balance through the ledger
  /// but is never counted as income.
  Future<Loan> create({
    required String title,
    required Rial principal,
    required int installmentCount,
    required CalendarDate startDate,
    required String operationId,
    Rial interest = Rial.zero,
    String? accountId,
    String? description,
    List<CalendarDate> dueDates = const [],
    Rial? expectedInstallmentAmount,
    String? id,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw const ValidationException('عنوان وام را وارد کنید.');
    }
    if (accountId != null) {
      await _account(accountId);
    }

    final schedule = LoanCalculator.buildSchedule(
      principal: principal,
      interest: interest,
      installmentCount: installmentCount,
      startDate: startDate,
      dueDates: dueDates,
    );

    final base = LoanCalculator.baseInstallment(
      principal: principal,
      interest: interest,
      installmentCount: installmentCount,
    );
    if (expectedInstallmentAmount != null &&
        expectedInstallmentAmount > Rial.zero) {
      final difference = (base - expectedInstallmentAmount).abs.value;
      if (difference > installmentCount) {
        throw ValidationException(
          'مبلغ قسط با تقسیم اصل و سود هم‌خوانی ندارد؛ مبلغ محاسبه‌شده ${MoneyFormatter().format(base)} است.',
        );
      }
    }

    final loanId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();

    return _db.transaction(() async {
      final existing = await _operations.find(operationId);
      if (existing != null) {
        final loan = await findById(existing.entityId);
        if (loan != null) return loan;
      }

      await _db
          .into(_db.loans)
          .insert(
            LoansCompanion.insert(
              id: loanId,
              title: trimmedTitle,
              principalAmountRial: principal.value,
              interestAmountRial: Value(interest.value),
              installmentCount: installmentCount,
              installmentAmountRial: base.value,
              accountId: Value(accountId),
              startDate: startDate.stored,
              status: LoanStatus.active,
              description: Value(description?.trim()),
              operationId: operationId,
              createdAt: now,
            ),
          );

      await _db.batch((batch) {
        batch.insertAll(_db.installments, [
          for (final draft in schedule)
            InstallmentsCompanion.insert(
              id: '${loanId}_${draft.number}',
              loanId: loanId,
              installmentNumber: draft.number,
              dueDate: draft.dueDate,
              amountRial: draft.amountRial.value,
              principalRial: draft.principalRial.value,
              interestRial: Value(draft.interestRial.value),
              status: InstallmentStatus.pending,
              createdAt: now,
            ),
        ]);
      });

      if (accountId != null) {
        await _db
            .into(_db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                accountId: accountId,
                deltaRial: principal.value,
                entryDate: startDate.stored,
                sourceType: LedgerSource.loanDisbursement,
                sourceId: loanId,
                operationId: operationId,
                createdAt: now,
              ),
            );
      }

      final account = accountId == null ? null : await _account(accountId);
      await _operations.record(
        operationId: operationId,
        kind: FinancialOperationKind.addLoan,
        entityId: loanId,
        summary:
            'وام ${MoneyFormatter().format(principal)} — $trimmedTitle${account == null ? '' : ' در ${account.accountName}'}',
        payload: {'loanId': loanId, 'accountId': accountId},
      );

      return (await findById(loanId))!;
    });
  }

  Future<List<Loan>> list() async {
    final rows = await (_db.select(
      _db.loans,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).get();
    final installmentRows = await _db.select(_db.installments).get();
    final accounts = await _db.select(_db.accounts).get();
    final accountNames = {
      for (final account in accounts) account.id: account.accountName,
    };
    final byLoan = <String, List<InstallmentRow>>{};
    for (final installment in installmentRows) {
      byLoan.putIfAbsent(installment.loanId, () => []).add(installment);
    }
    return [
      for (final row in rows)
        _derive(row, byLoan[row.id] ?? const [], accountNames[row.accountId]),
    ];
  }

  Stream<List<Loan>> watch() {
    // Watching a cheap projection of both tables lets the loan cards refresh
    // when either the loan or one of its installments changes.
    return _db
        .customSelect(
          'SELECT id FROM loans',
          readsFrom: {_db.loans, _db.installments},
        )
        .watch()
        .asyncMap((_) => list());
  }

  Future<Loan?> findById(String id) async {
    final row = await (_db.select(
      _db.loans,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final installments = await (_db.select(
      _db.installments,
    )..where((table) => table.loanId.equals(id))).get();
    final account = row.accountId == null
        ? null
        : await _accountById(row.accountId!);
    return _derive(row, installments, account?.accountName);
  }

  Future<List<Installment>> installmentsOf(String loanId) async {
    final rows =
        await (_db.select(_db.installments)
              ..where((table) => table.loanId.equals(loanId))
              ..orderBy([(table) => OrderingTerm.asc(table.installmentNumber)]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Marks an installment as paid, writes the ledger movement and records the
  /// operation so it can be undone.
  Future<Installment> markInstallmentPaid({
    required String loanId,
    required String installmentId,
    required CalendarDate paymentDate,
    required String operationId,
    Rial? paidAmount,
  }) async {
    final loanRow = await (_db.select(
      _db.loans,
    )..where((table) => table.id.equals(loanId))).getSingleOrNull();
    if (loanRow == null) throw const NotFoundException('وام پیدا نشد.');
    final row = await (_db.select(
      _db.installments,
    )..where((table) => table.id.equals(installmentId))).getSingleOrNull();
    if (row == null || row.loanId != loanId) {
      throw const NotFoundException('قسط پیدا نشد.');
    }
    if (row.status == InstallmentStatus.paid) {
      throw const ValidationException('این قسط قبلاً پرداخت شده است.');
    }

    final amount = paidAmount ?? Rial(row.amountRial);
    if (amount <= Rial.zero) {
      throw const ValidationException('مبلغ پرداخت باید بزرگ‌تر از صفر باشد.');
    }
    if (amount < Rial(row.amountRial)) {
      throw ValidationException(
        'مبلغ پرداختی (${amount.value} ریال) کمتر از مبلغ قسط (${row.amountRial} ریال) است. '
        'پرداخت جزئی در این نسخه پشتیبانی نمی‌شود.',
      );
    }
    final now = DateTime.now().toUtc();

    return _db.transaction(() async {
      final existing = await _operations.find(operationId);
      if (existing != null) {
        final existingRow =
            await (_db.select(_db.installments)
                  ..where((table) => table.id.equals(existing.entityId)))
                .getSingleOrNull();
        if (existingRow != null) return existingRow.toDomain();
      }

      await (_db.update(
        _db.installments,
      )..where((table) => table.id.equals(installmentId))).write(
        InstallmentsCompanion(
          status: const Value(InstallmentStatus.paid),
          paidAmountRial: Value(amount.value),
          paidAt: Value(paymentDate.stored),
        ),
      );

      if (loanRow.accountId != null) {
        await _db
            .into(_db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                accountId: loanRow.accountId!,
                deltaRial: -amount.value,
                entryDate: paymentDate.stored,
                sourceType: LedgerSource.installmentPayment,
                sourceId: installmentId,
                operationId: operationId,
                createdAt: now,
              ),
            );
      }

      final remaining =
          await (_db.select(_db.installments)..where(
                (table) =>
                    table.loanId.equals(loanId) &
                    table.status.equalsValue(InstallmentStatus.pending),
              ))
              .get();
      if (remaining.isEmpty) {
        await (_db.update(_db.loans)..where((table) => table.id.equals(loanId)))
            .write(const LoansCompanion(status: Value(LoanStatus.closed)));
      }

      await _operations.record(
        operationId: operationId,
        kind: FinancialOperationKind.markInstallmentPaid,
        entityId: installmentId,
        summary:
            'پرداخت قسط ${row.installmentNumber} وام ${loanRow.title} — ${MoneyFormatter().format(amount)}',
        payload: {
          'loanId': loanId,
          'installmentId': installmentId,
          'accountId': loanRow.accountId,
          'amountRial': amount.value,
        },
      );

      final updated = await (_db.select(
        _db.installments,
      )..where((table) => table.id.equals(installmentId))).getSingle();
      return updated.toDomain(loanTitle: loanRow.title);
    });
  }

  Future<void> archive(String loanId) async {
    await (_db.update(_db.loans)..where((table) => table.id.equals(loanId)))
        .write(const LoansCompanion(status: Value(LoanStatus.archived)));
  }

  /// Edits the descriptive fields of a loan.
  ///
  /// The principal, schedule and payments are immutable here: changing them
  /// would silently rewrite already-paid installments, so the assistant
  /// deletes and re-creates a loan instead.
  Future<void> update({
    required String loanId,
    String? title,
    String? description,
    bool clearDescription = false,
    LoanStatus? status,
  }) async {
    final row = await (_db.select(
      _db.loans,
    )..where((table) => table.id.equals(loanId))).getSingleOrNull();
    if (row == null) throw const NotFoundException('وام پیدا نشد.');
    final trimmedTitle = title?.trim();
    if (trimmedTitle != null && trimmedTitle.isEmpty) {
      throw const ValidationException('عنوان وام را وارد کنید.');
    }
    await (_db.update(
      _db.loans,
    )..where((table) => table.id.equals(loanId))).write(
      LoansCompanion(
        title: trimmedTitle == null
            ? const Value.absent()
            : Value(trimmedTitle),
        description: clearDescription
            ? const Value(null)
            : description == null
            ? const Value.absent()
            : Value(description.trim()),
        status: status == null ? const Value.absent() : Value(status),
      ),
    );
  }

  /// Deletes a loan, its schedule and every ledger movement it produced.
  ///
  /// Removing the disbursement and installment-payment ledger rows restores
  /// the account balances to what they would be without the loan.
  Future<void> delete(String loanId) async {
    final row = await (_db.select(
      _db.loans,
    )..where((table) => table.id.equals(loanId))).getSingleOrNull();
    if (row == null) throw const NotFoundException('وام پیدا نشد.');
    final installments = await (_db.select(
      _db.installments,
    )..where((table) => table.loanId.equals(loanId))).get();
    final installmentIds = {for (final item in installments) item.id};

    await _db.transaction(() async {
      await (_db.delete(_db.ledgerEntries)..where(
            (table) =>
                (table.sourceType.equalsValue(LedgerSource.loanDisbursement) &
                    table.sourceId.equals(loanId)) |
                (table.sourceType.equalsValue(LedgerSource.installmentPayment) &
                    table.sourceId.isIn(installmentIds)),
          ))
          .go();
      await (_db.delete(
        _db.installments,
      )..where((table) => table.loanId.equals(loanId))).go();
      await (_db.delete(
        _db.loans,
      )..where((table) => table.id.equals(loanId))).go();
    });
  }

  /// Installments due soon across all active loans, for the dashboard.
  Future<List<Installment>> upcoming({int limit = 5, DateTime? from}) async {
    final start = from ?? DateTime.now();
    final startDate = DateTime.utc(start.year, start.month, start.day);
    final loans = await _db.select(_db.loans).get();
    final titles = {for (final loan in loans) loan.id: loan.title};
    final query = _db.select(_db.installments)
      ..where(
        (table) =>
            table.status.equalsValue(InstallmentStatus.pending) &
            table.dueDate.isBiggerOrEqualValue(
              startDate.subtract(const Duration(days: 30)),
            ),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.dueDate)])
      ..limit(limit);
    final rows = await query.get();
    return rows
        .where((row) => titles.containsKey(row.loanId))
        .map((row) => row.toDomain(loanTitle: titles[row.loanId]))
        .toList();
  }

  Loan _derive(
    LoanRow row,
    List<InstallmentRow> installments,
    String? accountName,
  ) {
    final paid = installments
        .where((item) => item.status == InstallmentStatus.paid)
        .toList();
    final paidPrincipal = paid.map((item) => Rial(item.principalRial));
    final outstanding = LoanCalculator.outstanding(
      principal: Rial(row.principalAmountRial),
      paidPrincipalParts: paidPrincipal,
    );
    final pending =
        installments
            .where((item) => item.status != InstallmentStatus.paid)
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return row.toDomain(
      accountName: accountName,
      paidInstallments: paid.length,
      totalPaidRial: Rial.sum(paid.map((item) => Rial(item.paidAmountRial))),
      outstandingRial: outstanding,
      nextDueDate: pending.isEmpty ? null : pending.first.dueDate,
    );
  }

  Future<AccountRow> _account(String id) async {
    final row = await _accountById(id);
    if (row == null) throw const NotFoundException('حساب انتخاب‌شده پیدا نشد.');
    if (row.archivedAt != null) {
      throw const ValidationException('حساب انتخاب‌شده بایگانی شده است.');
    }
    return row;
  }

  Future<AccountRow?> _accountById(String id) => (_db.select(
    _db.accounts,
  )..where((table) => table.id.equals(id))).getSingleOrNull();
}
