import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../../accounts/data/account_repository.dart';
import '../../ai/domain/tool.dart';
import '../../assets/data/asset_repository.dart';
import '../../assets/domain/asset_quantity.dart';
import '../../loans/data/loan_repository.dart';
import '../../obligations/data/obligation_repository.dart';
import '../../transactions/data/operation_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/data/transfer_repository.dart';
import '../domain/chat_models.dart';
import '../domain/drafts.dart';
import 'chat_repository.dart';

/// Turns a confirmed pending action into database writes.
///
/// This is the only path that writes AI-proposed data, and it always runs the
/// same validations as a manual entry. Drafts can create records, edit them,
/// archive them or delete them; nothing is written before the user confirms.
class ConfirmationService {
  ConfirmationService({
    required AppDatabase db,
    required ChatRepository chat,
    required AccountRepository accounts,
    required TransactionRepository transactions,
    required TransferRepository transfers,
    required LoanRepository loans,
    required AssetRepository assets,
    required ObligationRepository obligations,
    required OperationRepository operations,
  }) : _db = db,
       _chat = chat,
       _accounts = accounts,
       _transactions = transactions,
       _transfers = transfers,
       _loans = loans,
       _assets = assets,
       _obligations = obligations,
       _operations = operations;

  final AppDatabase _db;
  final ChatRepository _chat;
  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final TransferRepository _transfers;
  final LoanRepository _loans;
  final AssetRepository _assets;
  final ObligationRepository _obligations;
  final OperationRepository _operations;

  /// Executes [action] after replacing its payload with [payload] when the user
  /// edited the draft. Returns the operation id used for undo.
  Future<String> confirm(
    String actionId, {
    Map<String, Object?>? payload,
  }) async {
    try {
      return await _db.transaction(() => _confirm(actionId, payload));
    } on AppException catch (error) {
      await _recordError(actionId, payload, error.message);
      rethrow;
    } on Object {
      await _recordError(actionId, payload, 'ثبت این پیش‌نویس ممکن نشد.');
      rethrow;
    }
  }

  Future<String> _confirm(
    String actionId,
    Map<String, Object?>? payload,
  ) async {
    final action = await _chat.findPendingAction(actionId);
    if (action == null) throw const NotFoundException('پیش‌نویس پیدا نشد.');
    if (!action.isPending) {
      throw ValidationException(
        'این پیش‌نویس قبلاً ${action.status.labelFa} شده است.',
      );
    }
    final effectivePayload = payload ?? action.payload;
    final tool = DaramTool.fromName(action.actionType);
    final recordType = effectivePayload['recordType'] as String?;
    final recordAction = effectivePayload['action'] as String?;
    final fields = _fields(effectivePayload);

    switch (tool) {
      case DaramTool.addAccount:
        final draft = AccountDraft.fromPayload(effectivePayload);
        await _accounts.create(
          bankId: draft.bankId,
          bankName: draft.bankName,
          accountName: draft.accountName,
          accountType: draft.accountType,
          initialBalance: draft.initialBalanceRial,
          cardLastFour: draft.cardLastFour,
          description: draft.description,
          operationId: action.operationId,
        );
      case DaramTool.addTransaction:
        final draft = TransactionDraft.fromPayload(effectivePayload);
        await _transactions.create(
          type: draft.type,
          amount: draft.amountRial,
          accountId: draft.accountId,
          categoryId: draft.categoryId,
          date: draft.date,
          description: draft.description,
          operationId: action.operationId,
        );
      case DaramTool.addTransfer:
        final draft = TransferDraft.fromPayload(effectivePayload);
        await _transfers.create(
          sourceAccountId: draft.sourceAccountId,
          destinationAccountId: draft.destinationAccountId,
          amount: draft.amountRial,
          fee: draft.feeRial,
          date: draft.date,
          description: draft.description,
          operationId: action.operationId,
        );
      case DaramTool.addLoan:
        final draft = LoanDraft.fromPayload(effectivePayload);
        await _loans.create(
          title: draft.loanTitle,
          principal: draft.principalRial,
          interest: draft.interestRial,
          installmentCount: draft.installmentCount,
          accountId: draft.accountId,
          startDate: draft.startDate,
          dueDates: draft.dueDates,
          expectedInstallmentAmount: draft.installmentAmountRial,
          description: draft.description,
          operationId: action.operationId,
        );
      case DaramTool.markInstallmentPaid:
        final draft = InstallmentPaymentDraft.fromPayload(effectivePayload);
        await _loans.markInstallmentPaid(
          loanId: draft.loanId,
          installmentId: draft.installmentId,
          paymentDate: draft.paymentDate,
          paidAmount: draft.paidAmountRial,
          operationId: action.operationId,
        );
      case DaramTool.manageAccount:
        await _applyAccount(recordAction, effectivePayload, fields);
      case DaramTool.manageTransaction:
        await _applyTransaction(recordAction, effectivePayload, fields);
      case DaramTool.manageTransfer:
        await _applyTransfer(recordAction, effectivePayload, fields);
      case DaramTool.manageLoan:
        await _applyLoan(recordAction, effectivePayload, fields);
      case DaramTool.manageAsset:
        await _applyAsset(recordAction, effectivePayload, fields);
      case DaramTool.manageObligation:
        await _applyObligation(recordAction, effectivePayload, fields);
      case DaramTool.manageCategory ||
          DaramTool.queryTransactions ||
          DaramTool.queryRecords ||
          DaramTool.financialOverview ||
          DaramTool.generateReport ||
          DaramTool.reviewSmsSuggestions ||
          DaramTool.confirmSmsSuggestion ||
          DaramTool.editSmsSuggestion ||
          DaramTool.dismissSmsSuggestion ||
          DaramTool.updatePendingDraft ||
          DaramTool.cancelPendingDraft ||
          DaramTool.updateSettings ||
          null:
        throw const ValidationException('این پیش‌نویس قابل تأیید نیست.');
    }

    if (tool != null && recordType != null) {
      await _operations.record(
        operationId: action.operationId,
        kind: _operationKind(tool, recordAction),
        entityId: (effectivePayload['recordId'] ?? '') as String,
        summary: (effectivePayload['summary'] ?? 'تغییر رکورد') as String,
        payload: effectivePayload,
      );
    }

    await _chat.updatePendingAction(
      action.copyWith(
        payload: effectivePayload,
        status: PendingActionStatus.confirmed,
        resolvedAt: DateTime.now().toUtc(),
      ),
    );
    return action.operationId;
  }

  Future<void> _applyAccount(
    String? action,
    Map<String, Object?> payload,
    Map<String, Object?> fields,
  ) async {
    final id = _requireId(payload);
    switch (action) {
      case 'archive':
        await _accounts.archive(id);
      case 'unarchive':
        await _accounts.unarchive(id);
      case 'update':
        final typeName = fields['accountType'] as String?;
        await _accounts.update(
          id: id,
          accountName: fields['accountName'] as String?,
          accountType: typeName == null
              ? null
              : AccountType.fromStorage(typeName),
          cardLastFour: fields['cardLastFour'] as String?,
          description: fields['description'] as String?,
          bankId: fields['bankId'] as String?,
          bankName: fields['bankName'] as String?,
        );
      default:
        throw const ValidationException('عملیات حساب شناخته نشد.');
    }
  }

  Future<void> _applyTransaction(
    String? action,
    Map<String, Object?> payload,
    Map<String, Object?> fields,
  ) async {
    final id = _requireId(payload);
    if (action == 'delete') {
      await _transactions.delete(id);
      return;
    }
    if (action != 'update') {
      throw const ValidationException('عملیات تراکنش شناخته نشد.');
    }
    await _transactions.update(
      id: id,
      type: TransactionType.tryParse(fields['type']),
      amount: _money(fields, 'amountRial'),
      accountId: fields['accountId'] as String?,
      categoryId: fields['categoryId'] as String?,
      clearCategory: fields['categoryId'] == null,
      date: _date(fields, 'date'),
      description: fields['description'] as String?,
      clearDescription: fields['description'] == null,
    );
  }

  Future<void> _applyTransfer(
    String? action,
    Map<String, Object?> payload,
    Map<String, Object?> fields,
  ) async {
    final id = _requireId(payload);
    if (action == 'delete') {
      await _transfers.delete(id);
      return;
    }
    if (action != 'update') {
      throw const ValidationException('عملیات انتقال شناخته نشد.');
    }
    await _transfers.update(
      id: id,
      sourceAccountId: fields['sourceAccountId'] as String?,
      destinationAccountId: fields['destinationAccountId'] as String?,
      amount: _money(fields, 'amountRial'),
      fee: _money(fields, 'feeRial'),
      date: _date(fields, 'date'),
      description: fields['description'] as String?,
      clearDescription: fields['description'] == null,
    );
  }

  Future<void> _applyLoan(
    String? action,
    Map<String, Object?> payload,
    Map<String, Object?> fields,
  ) async {
    final id = _requireId(payload);
    switch (action) {
      case 'archive':
        await _loans.archive(id);
      case 'delete':
        await _loans.delete(id);
      case 'update':
        final statusName = fields['status'] as String?;
        await _loans.update(
          loanId: id,
          title: fields['title'] as String?,
          description: fields['description'] as String?,
          clearDescription: fields['description'] == null,
          status: statusName == null
              ? null
              : LoanStatus.values.firstWhere(
                  (item) => item.name == statusName,
                  orElse: () => LoanStatus.active,
                ),
        );
      default:
        throw const ValidationException('عملیات وام شناخته نشد.');
    }
  }

  Future<void> _applyAsset(
    String? action,
    Map<String, Object?> payload,
    Map<String, Object?> fields,
  ) async {
    if (action == 'delete') {
      await _assets.delete(_requireId(payload));
      return;
    }
    if (action != 'create' && action != 'update') {
      throw const ValidationException('عملیات دارایی شناخته نشد.');
    }
    final kindName = fields['kind'] as String?;
    final kind = AssetKind.values.firstWhere(
      (item) => item.name == kindName,
      orElse: () => AssetKind.gold,
    );
    final quantityMicros = fields['quantityMicros'];
    if (quantityMicros is! int) {
      throw const ValidationException('مقدار دارایی معتبر نیست.');
    }
    final rateRial = fields['rateRial'];
    final rateDateRaw = fields['rateDate'] as String?;
    await _assets.save(
      id: action == 'create' ? null : _requireId(payload),
      name: (fields['name'] ?? '') as String,
      kind: kind,
      quantity: AssetQuantity.fromMicros(quantityMicros),
      currencyCode: fields['currencyCode'] as String?,
      rate: rateRial is int ? Rial(rateRial) : null,
      rateDate: rateRial == null || rateDateRaw == null
          ? null
          : DateTime.parse(rateDateRaw),
      isMarketRate: fields['isMarketRate'] == true && rateRial != null,
    );
  }

  Future<void> _applyObligation(
    String? action,
    Map<String, Object?> payload,
    Map<String, Object?> fields,
  ) async {
    switch (action) {
      case 'delete':
        await _obligations.delete(_requireId(payload));
      case 'add_payment':
        final obligationId = fields['obligationId'] as String?;
        if (obligationId == null) {
          throw const ValidationException('شناسه طلب/بدهی مشخص نیست.');
        }
        await _obligations.addPayment(
          obligationId,
          _money(fields, 'amountRial'),
          _date(fields, 'date'),
        );
      case 'create' || 'update':
        final amount = _money(fields, 'amountRial');
        await _obligations.save(
          id: action == 'create' ? null : _requireId(payload),
          counterparty: (fields['counterparty'] ?? '') as String,
          isReceivable: fields['isReceivable'] == true,
          amount: amount,
          dueDate: fields['dueDate'] == null
              ? null
              : CalendarDate.parseIso(fields['dueDate'] as String),
          note: fields['note'] as String?,
        );
      default:
        throw const ValidationException('عملیات طلب/بدهی شناخته نشد.');
    }
  }

  FinancialOperationKind _operationKind(DaramTool tool, String? action) {
    switch (tool) {
      case DaramTool.manageAccount:
        return switch (action) {
          'archive' => FinancialOperationKind.archiveAccount,
          'unarchive' => FinancialOperationKind.unarchiveAccount,
          _ => FinancialOperationKind.updateAccount,
        };
      case DaramTool.manageTransaction:
        return action == 'delete'
            ? FinancialOperationKind.deleteTransaction
            : FinancialOperationKind.updateTransaction;
      case DaramTool.manageTransfer:
        return action == 'delete'
            ? FinancialOperationKind.deleteTransfer
            : FinancialOperationKind.updateTransfer;
      case DaramTool.manageLoan:
        return switch (action) {
          'archive' => FinancialOperationKind.archiveLoan,
          'delete' => FinancialOperationKind.deleteLoan,
          _ => FinancialOperationKind.updateLoan,
        };
      case DaramTool.manageAsset:
        return switch (action) {
          'create' => FinancialOperationKind.addAsset,
          'delete' => FinancialOperationKind.deleteAsset,
          _ => FinancialOperationKind.updateAsset,
        };
      case DaramTool.manageObligation:
        return switch (action) {
          'create' => FinancialOperationKind.addObligation,
          'delete' => FinancialOperationKind.deleteObligation,
          'add_payment' => FinancialOperationKind.obligationPayment,
          _ => FinancialOperationKind.updateObligation,
        };
      default:
        return FinancialOperationKind.addCategory;
    }
  }

  Map<String, Object?> _fields(Map<String, Object?> payload) {
    final raw = payload['fields'];
    if (raw is! Map) return const <String, Object?>{};
    return raw.map((key, value) => MapEntry('$key', value));
  }

  String _requireId(Map<String, Object?> payload) {
    final id = payload['recordId'];
    if (id is! String || id.isEmpty) {
      throw const ValidationException('شناسه رکورد مشخص نیست.');
    }
    return id;
  }

  Rial _money(Map<String, Object?> fields, String key) {
    final value = fields[key];
    if (value is int) return Rial(value);
    if (value is num) return Rial(value.toInt());
    throw const ValidationException('مبلغ معتبر نیست.');
  }

  CalendarDate _date(Map<String, Object?> fields, String key) {
    final value = fields[key];
    if (value is! String || value.isEmpty) {
      throw const ValidationException('تاریخ معتبر نیست.');
    }
    return CalendarDate.parseIso(value);
  }

  Future<void> _recordError(
    String actionId,
    Map<String, Object?>? payload,
    String message,
  ) => _db.transaction(() async {
    final current = await _chat.findPendingAction(actionId);
    if (current == null || !current.isPending) return;
    await _chat.updatePendingAction(
      current.copyWith(payload: payload, errorMessage: message),
    );
  });

  Future<void> reject(String actionId) => _db.transaction(() async {
    final action = await _chat.findPendingAction(actionId);
    if (action == null) throw const NotFoundException('پیش‌نویس پیدا نشد.');
    if (!action.isPending) return;
    await _chat.updatePendingAction(
      action.copyWith(
        status: PendingActionStatus.rejected,
        resolvedAt: DateTime.now().toUtc(),
      ),
    );
  });

  /// Rejects every still-pending draft attached to [messageId].
  Future<void> rejectAllForMessage(String messageId) async {
    final actions = await _chat.pendingActionsForMessage(messageId);
    for (final action in actions) {
      if (action.isPending) await reject(action.id);
    }
  }

  /// Confirms all pending drafts in order, stopping at the first failure.
  Future<List<String>> confirmAll(List<String> actionIds) async {
    final operations = <String>[];
    for (final id in actionIds) {
      operations.add(await confirm(id));
    }
    return operations;
  }

  /// Reads a canonical date payload value.
  CalendarDate dateOf(Map<String, Object?> payload, String key) =>
      CalendarDate.parseIso(payload[key] as String);

  Future<void> markMessageConfirmed(String messageId) async {
    final message = await (_db.select(
      _db.chatMessages,
    )..where((table) => table.id.equals(messageId))).getSingleOrNull();
    if (message == null) return;
    await _chat.updateMessage(
      messageId,
      metadata: {...decodeMetadata(message.metadataJson), 'confirmed': true},
    );
  }
}
