import 'package:drift/drift.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/database/app_database.dart';
import '../../transactions/data/operation_repository.dart';

/// Safely reverses an applied financial operation.
///
/// Undo only covers operations that were created through the assistant
/// confirmation flow. It removes ledger rows and their source records in one
/// database transaction, and refuses when dependent records would be orphaned.
class UndoService {
  UndoService(this._db, this._operations);

  final AppDatabase _db;
  final OperationRepository _operations;

  Future<bool> canUndo(String operationId) async {
    final operation = await _operations.find(operationId);
    if (operation == null || operation.isUndone) return false;
    return operation.kind == FinancialOperationKind.addAccount ||
        operation.kind == FinancialOperationKind.addTransaction ||
        operation.kind == FinancialOperationKind.addTransfer ||
        operation.kind == FinancialOperationKind.addLoan ||
        operation.kind == FinancialOperationKind.markInstallmentPaid;
  }

  Future<void> undo(String operationId) async {
    final operation = await _operations.find(operationId);
    if (operation == null) throw const NotFoundException('عملیات پیدا نشد.');
    if (operation.isUndone) {
      throw const ValidationException('این عملیات قبلاً برگشت داده شده است.');
    }

    switch (operation.kind) {
      case FinancialOperationKind.addTransaction:
        await _undoTransaction(operation.entityId);
      case FinancialOperationKind.addTransfer:
        await _undoTransfer(operation.entityId, operationId);
      case FinancialOperationKind.addAccount:
        await _undoAccount(operation.entityId);
      case FinancialOperationKind.addLoan:
        await _undoLoan(operation.entityId);
      case FinancialOperationKind.markInstallmentPaid:
        await _undoInstallmentPayment(operation.entityId);
      case FinancialOperationKind.updateTransaction ||
          FinancialOperationKind.deleteTransaction ||
          FinancialOperationKind.updateAccount ||
          FinancialOperationKind.archiveAccount ||
          FinancialOperationKind.unarchiveAccount ||
          FinancialOperationKind.updateTransfer ||
          FinancialOperationKind.deleteTransfer ||
          FinancialOperationKind.updateLoan ||
          FinancialOperationKind.archiveLoan ||
          FinancialOperationKind.deleteLoan ||
          FinancialOperationKind.addAsset ||
          FinancialOperationKind.updateAsset ||
          FinancialOperationKind.deleteAsset ||
          FinancialOperationKind.addObligation ||
          FinancialOperationKind.updateObligation ||
          FinancialOperationKind.deleteObligation ||
          FinancialOperationKind.obligationPayment ||
          FinancialOperationKind.addCategory:
        throw const ValidationException(
          'این تغییر از مسیر گفتگو انجام نشده و برگشت خودکار ندارد.',
        );
    }

    await _operations.markUndone(operationId);
  }

  Future<void> _undoTransaction(String transactionId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.ledgerEntries)..where(
            (table) =>
                table.sourceType.equalsValue(LedgerSource.transaction) &
                table.sourceId.equals(transactionId),
          ))
          .go();
      await (_db.delete(
        _db.transactions,
      )..where((table) => table.id.equals(transactionId))).go();
    });
  }

  Future<void> _undoTransfer(String transferId, String operationId) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.ledgerEntries,
      )..where((table) => table.sourceId.equals(transferId))).go();
      await (_db.delete(
        _db.transactions,
      )..where((table) => table.operationId.equals('$operationId:fee'))).go();
      await (_db.delete(
        _db.transfers,
      )..where((table) => table.id.equals(transferId))).go();
    });
  }

  Future<void> _undoAccount(String accountId) async {
    final ledgerCount = await _db
        .customSelect(
          'SELECT COUNT(*) AS count FROM ledger_entries WHERE account_id = ?',
          variables: [Variable.withString(accountId)],
          readsFrom: {_db.ledgerEntries},
        )
        .getSingle();
    final transactionCount = await _db
        .customSelect(
          'SELECT COUNT(*) AS count FROM transactions WHERE account_id = ?',
          variables: [Variable.withString(accountId)],
          readsFrom: {_db.transactions},
        )
        .getSingle();
    final loanCount = await _db
        .customSelect(
          'SELECT COUNT(*) AS count FROM loans WHERE account_id = ?',
          variables: [Variable.withString(accountId)],
          readsFrom: {_db.loans},
        )
        .getSingle();

    if (ledgerCount.read<int>('count') > 0 ||
        transactionCount.read<int>('count') > 0 ||
        loanCount.read<int>('count') > 0) {
      throw const ValidationException(
        'این حساب تراکنش یا وام مرتبط دارد و حذف آن امن نیست. می‌توانی آن را بایگانی کنی.',
      );
    }

    await (_db.delete(
      _db.accounts,
    )..where((table) => table.id.equals(accountId))).go();
  }

  Future<void> _undoLoan(String loanId) async {
    final installments = await (_db.select(
      _db.installments,
    )..where((table) => table.loanId.equals(loanId))).get();
    if (installments.any((row) => row.status == InstallmentStatus.paid)) {
      throw const ValidationException(
        'برای این وام قسط پرداخت‌شده ثبت شده است؛ برگشت کامل وام امن نیست.',
      );
    }

    await _db.transaction(() async {
      await (_db.delete(
        _db.ledgerEntries,
      )..where((table) => table.sourceId.equals(loanId))).go();
      await (_db.delete(
        _db.installments,
      )..where((table) => table.loanId.equals(loanId))).go();
      await (_db.delete(
        _db.loans,
      )..where((table) => table.id.equals(loanId))).go();
    });
  }

  Future<void> _undoInstallmentPayment(String installmentId) async {
    final row = await (_db.select(
      _db.installments,
    )..where((table) => table.id.equals(installmentId))).getSingleOrNull();
    if (row == null) throw const NotFoundException('قسط پیدا نشد.');

    await _db.transaction(() async {
      await (_db.update(
        _db.installments,
      )..where((table) => table.id.equals(installmentId))).write(
        const InstallmentsCompanion(
          status: Value(InstallmentStatus.pending),
          paidAmountRial: Value(0),
          paidAt: Value(null),
        ),
      );
      await (_db.delete(_db.ledgerEntries)..where(
            (table) =>
                table.sourceType.equalsValue(LedgerSource.installmentPayment) &
                table.sourceId.equals(installmentId),
          ))
          .go();
      await (_db.update(_db.loans)
            ..where((table) => table.id.equals(row.loanId)))
          .write(const LoansCompanion(status: Value(LoanStatus.active)));
    });
  }
}
