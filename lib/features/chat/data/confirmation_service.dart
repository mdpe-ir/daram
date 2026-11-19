import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../../accounts/data/account_repository.dart';
import '../../ai/domain/tool.dart';
import '../../loans/data/loan_repository.dart';
import '../../transactions/data/transfer_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../domain/chat_models.dart';
import '../domain/drafts.dart';
import 'chat_repository.dart';

/// Turns a confirmed pending action into financial records.
///
/// This is the only path that writes AI-proposed data, and it always runs the
/// same validations as a manual entry.
class ConfirmationService {
  ConfirmationService({
    required AppDatabase db,
    required ChatRepository chat,
    required AccountRepository accounts,
    required TransactionRepository transactions,
    required TransferRepository transfers,
    required LoanRepository loans,
  }) : _db = db,
       _chat = chat,
       _accounts = accounts,
       _transactions = transactions,
       _transfers = transfers,
       _loans = loans;

  final AppDatabase _db;
  final ChatRepository _chat;
  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final TransferRepository _transfers;
  final LoanRepository _loans;

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

    switch (DaramTool.fromName(action.actionType)) {
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
      case DaramTool.manageCategory ||
          DaramTool.queryTransactions ||
          DaramTool.generateReport ||
          null:
        throw const ValidationException('این پیش‌نویس قابل تأیید نیست.');
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
