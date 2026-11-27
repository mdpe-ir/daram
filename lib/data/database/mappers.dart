import 'package:shamsi_date/shamsi_date.dart';

import '../../core/money/rial.dart';
import '../../core/time/calendar_date.dart';
import '../../features/accounts/domain/account.dart';
import '../../features/assets/domain/asset_holding.dart';
import '../../features/assets/domain/asset_quantity.dart';
import '../../features/categories/domain/category.dart';
import '../../features/chat/domain/chat_models.dart';
import '../../features/loans/domain/loan.dart';
import '../../features/transactions/domain/transaction_record.dart';
import 'app_database.dart';

/// Conversions between Drift rows and immutable domain entities.
///
/// Keeping this in one file prevents database details from leaking into the
/// presentation layer.
extension AccountRowX on AccountRow {
  Account toDomain() => Account(
    id: id,
    bankId: bankId,
    bankName: bankName,
    accountName: accountName,
    accountType: accountType,
    initialBalanceRial: Rial(initialBalanceRial),
    cardLastFour: cardLastFour,
    description: description,
    createdAt: createdAt,
    archivedAt: archivedAt,
  );
}

extension CategoryRowX on CategoryRow {
  Category toDomain() => Category(
    id: id,
    name: name,
    type: type,
    icon: icon,
    colorHex: colorHex,
    isDefault: isDefault,
    sortOrder: sortOrder,
    createdAt: createdAt,
  );
}

extension TransactionRowX on TransactionRow {
  TransactionRecord toDomain({String? accountName, CategoryRow? category}) =>
      TransactionRecord(
        id: id,
        type: type,
        amountRial: Rial(amountRial),
        categoryId: categoryId,
        accountId: accountId,
        transactionDate: transactionDate,
        description: description,
        operationId: operationId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        accountName: accountName,
        categoryName: category?.name,
        categoryColorHex: category?.colorHex,
        categoryIcon: category?.icon,
      );
}

extension TransferRowX on TransferRow {
  TransferRecord toDomain({
    String? sourceAccountName,
    String? destinationAccountName,
  }) => TransferRecord(
    id: id,
    sourceAccountId: sourceAccountId,
    destinationAccountId: destinationAccountId,
    amountRial: Rial(amountRial),
    feeRial: Rial(feeRial),
    transferDate: transferDate,
    description: description,
    createdAt: createdAt,
    sourceAccountName: sourceAccountName,
    destinationAccountName: destinationAccountName,
  );
}

extension LoanRowX on LoanRow {
  Loan toDomain({
    String? accountName,
    int paidInstallments = 0,
    Rial totalPaidRial = Rial.zero,
    Rial? outstandingRial,
    DateTime? nextDueDate,
  }) => Loan(
    id: id,
    title: title,
    principalAmountRial: Rial(principalAmountRial),
    interestAmountRial: Rial(interestAmountRial),
    installmentCount: installmentCount,
    installmentAmountRial: Rial(installmentAmountRial),
    accountId: accountId,
    startDate: startDate,
    status: status,
    description: description,
    createdAt: createdAt,
    accountName: accountName,
    paidInstallments: paidInstallments,
    totalPaidRial: totalPaidRial,
    outstandingRial: outstandingRial ?? Rial(principalAmountRial),
    nextDueDate: nextDueDate,
  );
}

extension InstallmentRowX on InstallmentRow {
  Installment toDomain({String? loanTitle}) => Installment(
    id: id,
    loanId: loanId,
    number: installmentNumber,
    dueDate: dueDate,
    amountRial: Rial(amountRial),
    principalRial: Rial(principalRial),
    interestRial: Rial(interestRial),
    status: status,
    paidAmountRial: Rial(paidAmountRial),
    paidAt: paidAt,
    loanTitle: loanTitle,
  );
}

extension ChatSessionRowX on ChatSessionRow {
  ChatSession toDomain({int messageCount = 0, String? preview}) => ChatSession(
    id: id,
    title: title,
    createdAt: createdAt,
    updatedAt: updatedAt,
    messageCount: messageCount,
    preview: preview,
  );
}

extension ChatMessageRowX on ChatMessageRow {
  ChatMessage toDomain() => ChatMessage(
    id: id,
    sessionId: sessionId,
    role: role,
    content: content,
    type: messageType,
    metadata: decodeMetadata(metadataJson),
    createdAt: createdAt,
  );
}

extension PendingActionRowX on PendingActionRow {
  PendingAction toDomain() => PendingAction(
    id: id,
    sessionId: sessionId,
    messageId: messageId,
    actionType: actionType,
    payload: decodeMetadata(payloadJson),
    status: status,
    operationId: operationId,
    errorMessage: errorMessage,
    createdAt: createdAt,
    resolvedAt: resolvedAt,
  );
}

extension FinancialOperationRowX on FinancialOperationRow {
  FinancialOperation toDomain() => FinancialOperation(
    id: id,
    kind: kind,
    entityId: entityId,
    summary: summary,
    payload: decodeMetadata(payloadJson),
    status: status,
    createdAt: createdAt,
    undoneAt: undoneAt,
  );
}

extension AssetHoldingRowX on AssetHoldingRow {
  AssetHolding toDomain() => AssetHolding(
    id: id,
    name: name,
    kind: kind,
    currencyCode: currencyCode,
    quantity: AssetQuantity.fromMicros(quantityMicros),
    rateRial: rateRial == null ? null : Rial(rateRial!),
    rateDate: rateDate,
    isMarketRate: isMarketRate,
    createdAt: createdAt,
  );
}

/// The stored UTC date for a Jalali/Gregorian calendar date.
DateTime storedDate(CalendarDate date) => date.stored;

/// A readable Jalali label for a stored date.
String storedJalaliLabel(DateTime date) {
  final local = date.toUtc();
  final jalali = Jalali(local.year, local.month, local.day);
  return '${jalali.year}/${jalali.month.toString().padLeft(2, '0')}/${jalali.day.toString().padLeft(2, '0')}';
}
