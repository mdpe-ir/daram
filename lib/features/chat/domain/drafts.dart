import '../../../core/domain/enums.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../ai/domain/tool.dart';
import 'chat_models.dart';

/// Typed view over a pending action payload.
///
/// Payloads are stored as canonical JSON (Rial integers, ISO dates) so that the
/// same data can be shown, edited and re-validated on confirmation.
sealed class FinancialDraft {
  const FinancialDraft();

  DaramTool get tool;
  String get title;
  List<String> get notes;
  Map<String, Object?> toPayload();

  static FinancialDraft? fromPendingAction(PendingAction action) {
    final tool = DaramTool.fromName(action.actionType);
    if (tool == null) return null;
    try {
      return switch (tool) {
        DaramTool.addAccount => AccountDraft.fromPayload(action.payload),
        DaramTool.addTransaction => TransactionDraft.fromPayload(
          action.payload,
        ),
        DaramTool.addTransfer => TransferDraft.fromPayload(action.payload),
        DaramTool.addLoan => LoanDraft.fromPayload(action.payload),
        DaramTool.markInstallmentPaid => InstallmentPaymentDraft.fromPayload(
          action.payload,
        ),
        _ => null,
      };
    } on Object {
      return null;
    }
  }
}

int _int(Map<String, Object?> map, String key, {int fallback = 0}) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _intOrNull(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value == null) return null;
  return _int(map, key);
}

String _string(Map<String, Object?> map, String key, {String fallback = ''}) {
  final value = map[key];
  return value is String ? value : fallback;
}

String? _stringOrNull(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is String && value.isNotEmpty) return value;
  return null;
}

bool _bool(Map<String, Object?> map, String key) => map[key] == true;

CalendarDate _date(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String) throw const FormatException('missing date');
  return CalendarDate.parseIso(value);
}

CalendarDate? _dateOrNull(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! String || value.isEmpty) return null;
  return CalendarDate.parseIso(value);
}

class AccountDraft extends FinancialDraft {
  const AccountDraft({
    required this.bankId,
    required this.bankName,
    required this.accountName,
    required this.accountType,
    required this.initialBalanceRial,
    this.cardLastFour,
    this.description,
  });

  factory AccountDraft.fromPayload(Map<String, Object?> payload) =>
      AccountDraft(
        bankId: _string(payload, 'bankId'),
        bankName: _string(payload, 'bankName'),
        accountName: _string(payload, 'accountName'),
        accountType: AccountType.fromStorage(
          _string(payload, 'accountType', fallback: 'bank'),
        ),
        initialBalanceRial: Rial(_int(payload, 'initialBalanceRial')),
        cardLastFour: _stringOrNull(payload, 'cardLastFour'),
        description: _stringOrNull(payload, 'description'),
      );

  final String bankId;
  final String bankName;
  final String accountName;
  final AccountType accountType;
  final Rial initialBalanceRial;
  final String? cardLastFour;
  final String? description;

  @override
  DaramTool get tool => DaramTool.addAccount;

  @override
  String get title => 'حساب جدید — $accountName';

  @override
  List<String> get notes => const [];

  AccountDraft copyWith({
    String? bankId,
    String? bankName,
    String? accountName,
    AccountType? accountType,
    Rial? initialBalanceRial,
    String? cardLastFour,
    String? description,
  }) => AccountDraft(
    bankId: bankId ?? this.bankId,
    bankName: bankName ?? this.bankName,
    accountName: accountName ?? this.accountName,
    accountType: accountType ?? this.accountType,
    initialBalanceRial: initialBalanceRial ?? this.initialBalanceRial,
    cardLastFour: cardLastFour ?? this.cardLastFour,
    description: description ?? this.description,
  );

  @override
  Map<String, Object?> toPayload() => {
    'bankId': bankId,
    'bankName': bankName,
    'accountName': accountName,
    'accountType': accountType.name,
    'initialBalanceRial': initialBalanceRial.value,
    'cardLastFour': cardLastFour,
    'description': description,
  };
}

class TransactionDraft extends FinancialDraft {
  const TransactionDraft({
    required this.type,
    required this.amountRial,
    required this.accountId,
    required this.accountName,
    required this.date,
    this.categoryId,
    this.categoryName,
    this.description,
    this.assumedCategory = false,
    this.assumedDate = false,
  });

  factory TransactionDraft.fromPayload(
    Map<String, Object?> payload,
  ) => TransactionDraft(
    type: TransactionType.tryParse(payload['type']) ?? TransactionType.expense,
    amountRial: Rial(_int(payload, 'amountRial')),
    accountId: _string(payload, 'accountId'),
    accountName: _string(payload, 'accountName'),
    categoryId: _stringOrNull(payload, 'categoryId'),
    categoryName: _stringOrNull(payload, 'categoryName'),
    date: _date(payload, 'date'),
    description: _stringOrNull(payload, 'description'),
    assumedCategory: _bool(payload, 'assumedCategory'),
    assumedDate: _bool(payload, 'assumedDate'),
  );

  final TransactionType type;
  final Rial amountRial;
  final String accountId;
  final String accountName;
  final String? categoryId;
  final String? categoryName;
  final CalendarDate date;
  final String? description;
  final bool assumedCategory;
  final bool assumedDate;

  @override
  DaramTool get tool => DaramTool.addTransaction;

  @override
  String get title =>
      type == TransactionType.income ? 'درآمد جدید' : 'هزینه جدید';

  @override
  List<String> get notes => [
    if (assumedCategory)
      'دسته‌بندی از میان دسته‌های موجود انتخاب شد؛ می‌توانی تغییرش بدهی.',
    if (assumedDate)
      'سال تاریخ ذکر نشده بود؛ نزدیک‌ترین تاریخ در گذشته انتخاب شد.',
  ];

  TransactionDraft copyWith({
    TransactionType? type,
    Rial? amountRial,
    String? accountId,
    String? accountName,
    String? categoryId,
    String? categoryName,
    CalendarDate? date,
    String? description,
  }) => TransactionDraft(
    type: type ?? this.type,
    amountRial: amountRial ?? this.amountRial,
    accountId: accountId ?? this.accountId,
    accountName: accountName ?? this.accountName,
    categoryId: categoryId ?? this.categoryId,
    categoryName: categoryName ?? this.categoryName,
    date: date ?? this.date,
    description: description ?? this.description,
    assumedCategory: assumedCategory,
    assumedDate: assumedDate,
  );

  @override
  Map<String, Object?> toPayload() => {
    'type': type.name,
    'amountRial': amountRial.value,
    'accountId': accountId,
    'accountName': accountName,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'date': date.toIso(),
    'description': description,
    'assumedCategory': assumedCategory,
    'assumedDate': assumedDate,
  };
}

class TransferDraft extends FinancialDraft {
  const TransferDraft({
    required this.sourceAccountId,
    required this.sourceAccountName,
    required this.destinationAccountId,
    required this.destinationAccountName,
    required this.amountRial,
    required this.date,
    this.feeRial = Rial.zero,
    this.description,
  });

  factory TransferDraft.fromPayload(Map<String, Object?> payload) =>
      TransferDraft(
        sourceAccountId: _string(payload, 'sourceAccountId'),
        sourceAccountName: _string(payload, 'sourceAccountName'),
        destinationAccountId: _string(payload, 'destinationAccountId'),
        destinationAccountName: _string(payload, 'destinationAccountName'),
        amountRial: Rial(_int(payload, 'amountRial')),
        feeRial: Rial(_int(payload, 'feeRial')),
        date: _date(payload, 'date'),
        description: _stringOrNull(payload, 'description'),
      );

  final String sourceAccountId;
  final String sourceAccountName;
  final String destinationAccountId;
  final String destinationAccountName;
  final Rial amountRial;
  final Rial feeRial;
  final CalendarDate date;
  final String? description;

  @override
  DaramTool get tool => DaramTool.addTransfer;

  @override
  String get title => 'انتقال بین حساب‌ها';

  @override
  List<String> get notes => const [];

  TransferDraft copyWith({
    String? sourceAccountId,
    String? sourceAccountName,
    String? destinationAccountId,
    String? destinationAccountName,
    Rial? amountRial,
    Rial? feeRial,
    CalendarDate? date,
    String? description,
  }) => TransferDraft(
    sourceAccountId: sourceAccountId ?? this.sourceAccountId,
    sourceAccountName: sourceAccountName ?? this.sourceAccountName,
    destinationAccountId: destinationAccountId ?? this.destinationAccountId,
    destinationAccountName:
        destinationAccountName ?? this.destinationAccountName,
    amountRial: amountRial ?? this.amountRial,
    feeRial: feeRial ?? this.feeRial,
    date: date ?? this.date,
    description: description ?? this.description,
  );

  @override
  Map<String, Object?> toPayload() => {
    'sourceAccountId': sourceAccountId,
    'sourceAccountName': sourceAccountName,
    'destinationAccountId': destinationAccountId,
    'destinationAccountName': destinationAccountName,
    'amountRial': amountRial.value,
    'feeRial': feeRial.value,
    'date': date.toIso(),
    'description': description,
  };
}

class LoanDraft extends FinancialDraft {
  const LoanDraft({
    required this.loanTitle,
    required this.principalRial,
    required this.installmentCount,
    required this.startDate,
    required this.dueDates,
    this.interestRial = Rial.zero,
    this.installmentAmountRial,
    this.accountId,
    this.accountName,
    this.description,
  });

  factory LoanDraft.fromPayload(Map<String, Object?> payload) {
    final rawDates = payload['dueDates'];
    return LoanDraft(
      loanTitle: _string(payload, 'title'),
      principalRial: Rial(_int(payload, 'principalRial')),
      interestRial: Rial(_int(payload, 'interestRial')),
      installmentCount: _int(payload, 'installmentCount'),
      installmentAmountRial:
          _intOrNull(payload, 'installmentAmountRial') == null
          ? null
          : Rial(_int(payload, 'installmentAmountRial')),
      accountId: _stringOrNull(payload, 'accountId'),
      accountName: _stringOrNull(payload, 'accountName'),
      startDate: _date(payload, 'startDate'),
      dueDates: rawDates is List
          ? rawDates.whereType<String>().map(CalendarDate.parseIso).toList()
          : const [],
      description: _stringOrNull(payload, 'description'),
    );
  }

  final String loanTitle;
  final Rial principalRial;
  final Rial interestRial;
  final int installmentCount;
  final Rial? installmentAmountRial;
  final String? accountId;
  final String? accountName;
  final CalendarDate startDate;
  final List<CalendarDate> dueDates;
  final String? description;

  @override
  DaramTool get tool => DaramTool.addLoan;

  @override
  String get title => 'وام جدید — $loanTitle';

  @override
  List<String> get notes => const [
    'پول وام به‌عنوان درآمد ثبت نمی‌شود؛ فقط بدهی و موجودی حساب تغییر می‌کند.',
  ];

  LoanDraft copyWith({
    String? loanTitle,
    Rial? principalRial,
    Rial? interestRial,
    int? installmentCount,
    Rial? installmentAmountRial,
    String? accountId,
    String? accountName,
    CalendarDate? startDate,
    List<CalendarDate>? dueDates,
    String? description,
  }) => LoanDraft(
    loanTitle: loanTitle ?? this.loanTitle,
    principalRial: principalRial ?? this.principalRial,
    interestRial: interestRial ?? this.interestRial,
    installmentCount: installmentCount ?? this.installmentCount,
    installmentAmountRial: installmentAmountRial ?? this.installmentAmountRial,
    accountId: accountId ?? this.accountId,
    accountName: accountName ?? this.accountName,
    startDate: startDate ?? this.startDate,
    dueDates: dueDates ?? this.dueDates,
    description: description ?? this.description,
  );

  @override
  Map<String, Object?> toPayload() => {
    'title': loanTitle,
    'principalRial': principalRial.value,
    'interestRial': interestRial.value,
    'installmentCount': installmentCount,
    'installmentAmountRial': installmentAmountRial?.value,
    'accountId': accountId,
    'accountName': accountName,
    'startDate': startDate.toIso(),
    'dueDates': dueDates.map((date) => date.toIso()).toList(),
    'description': description,
  };
}

class InstallmentPaymentDraft extends FinancialDraft {
  const InstallmentPaymentDraft({
    required this.loanId,
    required this.loanTitle,
    required this.installmentId,
    required this.installmentNumber,
    required this.paymentDate,
    required this.paidAmountRial,
    this.scheduledAmountRial = Rial.zero,
    this.dueDate,
  });

  factory InstallmentPaymentDraft.fromPayload(Map<String, Object?> payload) =>
      InstallmentPaymentDraft(
        loanId: _string(payload, 'loanId'),
        loanTitle: _string(payload, 'loanTitle'),
        installmentId: _string(payload, 'installmentId'),
        installmentNumber: _int(payload, 'installmentNumber'),
        paymentDate: _date(payload, 'paymentDate'),
        paidAmountRial: Rial(_int(payload, 'paidAmountRial')),
        scheduledAmountRial: Rial(_int(payload, 'scheduledAmountRial')),
        dueDate: _dateOrNull(payload, 'dueDate'),
      );

  final String loanId;
  final String loanTitle;
  final String installmentId;
  final int installmentNumber;
  final CalendarDate paymentDate;
  final Rial paidAmountRial;
  final Rial scheduledAmountRial;
  final CalendarDate? dueDate;

  @override
  DaramTool get tool => DaramTool.markInstallmentPaid;

  @override
  String get title => 'پرداخت قسط $installmentNumber — $loanTitle';

  @override
  List<String> get notes => const [];

  InstallmentPaymentDraft copyWith({
    CalendarDate? paymentDate,
    Rial? paidAmountRial,
  }) => InstallmentPaymentDraft(
    loanId: loanId,
    loanTitle: loanTitle,
    installmentId: installmentId,
    installmentNumber: installmentNumber,
    paymentDate: paymentDate ?? this.paymentDate,
    paidAmountRial: paidAmountRial ?? this.paidAmountRial,
    scheduledAmountRial: scheduledAmountRial,
    dueDate: dueDate,
  );

  @override
  Map<String, Object?> toPayload() => {
    'loanId': loanId,
    'loanTitle': loanTitle,
    'installmentId': installmentId,
    'installmentNumber': installmentNumber,
    'paymentDate': paymentDate.toIso(),
    'paidAmountRial': paidAmountRial.value,
    'scheduledAmountRial': scheduledAmountRial.value,
    'dueDate': dueDate?.toIso(),
  };
}
