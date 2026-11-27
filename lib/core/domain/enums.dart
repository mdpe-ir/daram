/// Shared domain enums. These are persisted by name through Drift's
/// `textEnum`, so their identifiers are part of the database contract and
/// must not be renamed without a migration.
library;

/// Kind of account the user owns.
enum AccountType {
  bank('حساب بانکی'),
  cash('نقدی'),
  digitalWallet('کیف پول دیجیتال'),
  savings('پس‌انداز'),
  other('سایر');

  const AccountType(this.labelFa);

  final String labelFa;

  static AccountType fromStorage(String value) => AccountType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => AccountType.other,
  );
}

/// Direction of a transaction in the profit & loss sense.
///
/// Transfers are not transactions: they never appear as income or expense.
enum TransactionType {
  income('درآمد'),
  expense('هزینه');

  const TransactionType(this.labelFa);

  final String labelFa;

  static TransactionType? tryParse(Object? value) {
    if (value is! String) return null;
    return switch (value.trim().toLowerCase()) {
      'income' || 'درآمد' || 'درامد' || 'credit' => TransactionType.income,
      'expense' || 'هزینه' || 'خرچ' || 'debit' => TransactionType.expense,
      _ => null,
    };
  }

  static TransactionType fromStorage(String value) =>
      TransactionType.values.firstWhere((type) => type.name == value);
}

/// Whether a category belongs to the income or expense side.
enum CategoryType {
  income('درآمد'),
  expense('هزینه');

  const CategoryType(this.labelFa);

  final String labelFa;

  static CategoryType? tryParse(Object? value) {
    if (value is! String) return null;
    return switch (value.trim().toLowerCase()) {
      'income' || 'درآمد' || 'درامد' => CategoryType.income,
      'expense' || 'هزینه' => CategoryType.expense,
      _ => null,
    };
  }
}

/// Lifecycle of a loan.
enum LoanStatus {
  active('در جریان'),
  closed('تسویه شده'),
  archived('بایگانی');

  const LoanStatus(this.labelFa);

  final String labelFa;
}

/// Lifecycle of a single installment.
enum InstallmentStatus {
  pending('پرداخت نشده'),
  paid('پرداخت شده'),
  overdue('سررسید گذشته');

  const InstallmentStatus(this.labelFa);

  final String labelFa;

  static InstallmentStatus fromStorage(String value) =>
      InstallmentStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => InstallmentStatus.pending,
      );
}

/// Origin of a ledger movement. Needed for auditability and safe undo.
enum LedgerSource {
  transaction,
  transferOut,
  transferIn,
  loanDisbursement,
  installmentPayment,
}

/// What kind of user operation produced a financial record.
enum FinancialOperationKind {
  addAccount('افزودن حساب'),
  updateAccount('ویرایش حساب'),
  archiveAccount('بایگانی حساب'),
  unarchiveAccount('بازگردانی حساب'),
  addTransaction('ثبت تراکنش'),
  updateTransaction('ویرایش تراکنش'),
  deleteTransaction('حذف تراکنش'),
  addTransfer('انتقال بین حساب'),
  updateTransfer('ویرایش انتقال'),
  deleteTransfer('حذف انتقال'),
  addLoan('ثبت وام'),
  updateLoan('ویرایش وام'),
  archiveLoan('بایگانی وام'),
  deleteLoan('حذف وام'),
  markInstallmentPaid('پرداخت قسط'),
  addAsset('افزودن دارایی'),
  updateAsset('ویرایش دارایی'),
  deleteAsset('حذف دارایی'),
  addObligation('افزودن طلب/بدهی'),
  updateObligation('ویرایش طلب/بدهی'),
  deleteObligation('حذف طلب/بدهی'),
  obligationPayment('پرداخت طلب/بدهی'),
  addCategory('افزودن دسته‌بندی');

  const FinancialOperationKind(this.labelFa);

  final String labelFa;
}

/// State of a financial draft awaiting user confirmation.
enum PendingActionStatus {
  pending('در انتظار تأیید'),
  confirmed('تأیید شده'),
  rejected('رد شده'),
  failed('ناموفق');

  const PendingActionStatus(this.labelFa);

  final String labelFa;

  static PendingActionStatus fromStorage(String value) =>
      PendingActionStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => PendingActionStatus.pending,
      );
}

/// Who produced a chat message.
enum ChatRole {
  user,
  assistant,
  system,
  tool;

  static ChatRole fromStorage(String value) => ChatRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => ChatRole.assistant,
  );
}

/// Rendering hint for a chat message part.
enum ChatMessageType {
  text,
  draft,
  report,
  error,
  info,
  confirmation;

  static ChatMessageType fromStorage(String value) =>
      ChatMessageType.values.firstWhere(
        (type) => type.name == value,
        orElse: () => ChatMessageType.text,
      );
}
