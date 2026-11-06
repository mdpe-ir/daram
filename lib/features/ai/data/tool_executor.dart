import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/iranian_banks.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/persian_date_parser.dart';
import '../../accounts/data/account_repository.dart';
import '../../chat/domain/chat_models.dart';
import '../../accounts/domain/account.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart';
import '../../dashboard/data/analytics_repository.dart';
import '../../dashboard/domain/analytics.dart';
import '../../loans/data/loan_repository.dart';
import '../../loans/domain/loan.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_record.dart';
import '../domain/ai_models.dart';
import '../domain/tool.dart';
import 'argument_parser.dart';
import 'tool_registry.dart';

/// Output of executing one tool call.
class ToolExecution {
  const ToolExecution({
    required this.toolCallId,
    required this.toolName,
    required this.ok,
    required this.content,
    this.pendingAction,
    this.report,
    this.userMessage,
  });

  final String toolCallId;
  final String toolName;
  final bool ok;

  /// JSON string sent back to the model as the tool result.
  final String content;

  /// The draft created by a write tool (awaiting user confirmation).
  final PendingAction? pendingAction;

  /// Serialised report attached to the assistant message for the chat card.
  final Map<String, Object?>? report;

  /// Short Persian sentence the UI may show while the model composes its reply.
  final String? userMessage;
}

/// Validates tool arguments against the local domain and turns write tools into
/// pending drafts.
///
/// This class is the boundary between "the model proposed something" and
/// "the app is willing to save something". Nothing here writes financial data.
class ToolExecutor {
  ToolExecutor({
    required ToolRegistry registry,
    required AccountRepository accounts,
    required CategoryRepository categories,
    required TransactionRepository transactions,
    required LoanRepository loans,
    required AnalyticsRepository analytics,
    ArgumentParser? parser,
  }) : _registry = registry,
       _accounts = accounts,
       _categories = categories,
       _transactions = transactions,
       _loans = loans,
       _analytics = analytics,
       _parser = parser ?? const ArgumentParser();

  final ToolRegistry _registry;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final LoanRepository _loans;
  final AnalyticsRepository _analytics;
  final ArgumentParser _parser;
  static const _uuid = Uuid();

  Future<ToolExecution> execute(
    ToolCall call, {
    required String sessionId,
    required CurrencyUnit defaultCurrency,
  }) async {
    final definition = _registry.byName(call.name);
    if (definition == null) {
      return _error(call, 'ابزار «${call.name}» در دسترس نیست.');
    }
    final validation = _registry.validateArguments(call.name, call.arguments);
    if (validation != null) {
      return _error(call, validation);
    }

    try {
      return await switch (DaramTool.fromName(call.name)) {
        DaramTool.addAccount => _addAccount(call, sessionId, defaultCurrency),
        DaramTool.addTransaction => _addTransaction(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.addTransfer => _addTransfer(call, sessionId, defaultCurrency),
        DaramTool.addLoan => _addLoan(call, sessionId, defaultCurrency),
        DaramTool.markInstallmentPaid => _markInstallmentPaid(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.queryTransactions => _queryTransactions(call),
        DaramTool.generateReport => _generateReport(call),
        null => _error(call, 'ابزار «${call.name}» شناخته نشد.'),
      };
    } on AppException catch (error) {
      return _error(call, error.message);
    } on MoneyException catch (error) {
      return _error(call, error.message);
    } on FormatException catch (error) {
      return _error(call, 'اطلاعات ارسالی معتبر نیست: ${error.message}');
    } on Object {
      return _error(
        call,
        'پردازش این درخواست ممکن نشد. لطفاً اطلاعات را دقیق‌تر بگو.',
      );
    }
  }

  Future<ToolExecution> _addAccount(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final args = call.arguments;
    final bankName = _parser.requireString(
      args['bank_name'],
      field: 'نام بانک',
    );
    final knownBank = bankByName(bankName);
    final bankId = knownBank?.id ?? 'other';
    final resolvedBankName = knownBank?.nameFa ?? bankName;
    final accountName = _parser.requireString(
      args['account_name'],
      field: 'نام حساب',
    );
    final type = _accountType(args['account_type']);
    if (args['initial_balance'] == null) {
      throw const ValidationException(
        'موجودی اولیه حساب مشخص نیست؛ لطفاً موجودی فعلی حساب را بگویید.',
      );
    }
    final balance = _parser.parseMoney(
      args['initial_balance'],
      args['amount_unit'],
      fallbackUnit: defaultCurrency,
      field: 'موجودی اولیه',
      allowZero: true,
    );
    final card = _optionalString(args['card_last_four_digits']);
    if (card != null && !RegExp(r'^\d{4}$').hasMatch(card)) {
      throw const ValidationException(
        'چهار رقم آخر کارت باید دقیقاً چهار رقم باشد.',
      );
    }

    final payload = <String, Object?>{
      'bankId': bankId,
      'bankName': resolvedBankName,
      'accountName': accountName,
      'accountType': type.name,
      'initialBalanceRial': balance.value,
      'cardLastFour': card,
      'description': _optionalString(args['description']),
    };
    return _propose(
      call,
      sessionId,
      DaramTool.addAccount,
      payload,
      'حساب «$accountName» در $resolvedBankName',
      'حساب جدید آماده تأیید است.',
    );
  }

  Future<ToolExecution> _addTransaction(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final args = call.arguments;
    final type = TransactionType.tryParse(args['type']);
    if (type == null) {
      throw const ValidationException('نوع تراکنش باید درآمد یا هزینه باشد.');
    }
    final amount = _parser.parseMoney(
      args['amount'],
      args['amount_unit'],
      fallbackUnit: defaultCurrency,
    );
    final date = _parser.parseDate(args['date'], field: 'تاریخ تراکنش');
    final account = await _resolveAccount(
      _parser.requireString(args['account'], field: 'حساب'),
    );

    var assumedCategory = false;
    final categoryName = _optionalString(args['category']);
    Category? category;
    if (categoryName != null) {
      category = await _categories.resolve(
        categoryName,
        type == TransactionType.income
            ? CategoryType.income
            : CategoryType.expense,
      );
    }
    if (category == null) {
      assumedCategory = true;
      final fallbackId = type == TransactionType.income
          ? 'cat_other_income'
          : 'cat_other_expense';
      category =
          await _categories.findById(fallbackId) ??
          (await _categories.list(
            type: type == TransactionType.income
                ? CategoryType.income
                : CategoryType.expense,
          )).firstOrNull;
    }

    final payload = <String, Object?>{
      'type': type.name,
      'amountRial': amount.value,
      'accountId': account.id,
      'accountName': account.accountName,
      'categoryId': category?.id,
      'categoryName': category?.name,
      'date': date.date.toIso(),
      'description': _optionalString(args['description']),
      'assumedCategory': assumedCategory,
      'assumedDate': date.ambiguous,
    };
    return _propose(
      call,
      sessionId,
      DaramTool.addTransaction,
      payload,
      '${type.labelFa} ${amount.value} ریال در ${account.accountName}',
      'پیش‌نویس ${type.labelFa} آماده تأیید است.',
    );
  }

  Future<ToolExecution> _addTransfer(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final args = call.arguments;
    final source = await _resolveAccount(
      _parser.requireString(args['source_account'], field: 'حساب مبدأ'),
    );
    final destination = await _resolveAccount(
      _parser.requireString(args['destination_account'], field: 'حساب مقصد'),
    );
    if (source.id == destination.id) {
      throw const ValidationException('حساب مبدأ و مقصد باید متفاوت باشند.');
    }
    final amount = _parser.parseMoney(
      args['amount'],
      args['amount_unit'],
      fallbackUnit: defaultCurrency,
    );
    final date = _parser.parseDate(args['date'], field: 'تاریخ انتقال');
    final fee = args['fee_amount'] == null
        ? Rial.zero
        : _parser.parseMoney(
            args['fee_amount'],
            args['amount_unit'],
            fallbackUnit: defaultCurrency,
            field: 'کارمزد',
            allowZero: true,
          );

    final payload = <String, Object?>{
      'sourceAccountId': source.id,
      'sourceAccountName': source.accountName,
      'destinationAccountId': destination.id,
      'destinationAccountName': destination.accountName,
      'amountRial': amount.value,
      'feeRial': fee.value,
      'date': date.date.toIso(),
      'description': _optionalString(args['description']),
    };
    return _propose(
      call,
      sessionId,
      DaramTool.addTransfer,
      payload,
      'انتقال ${amount.value} ریال از ${source.accountName} به ${destination.accountName}',
      'پیش‌نویس انتقال آماده تأیید است.',
    );
  }

  Future<ToolExecution> _addLoan(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final args = call.arguments;
    final title = _parser.requireString(args['title'], field: 'عنوان وام');
    final principal = _parser.parseMoney(
      args['principal_amount'],
      args['amount_unit'],
      fallbackUnit: defaultCurrency,
    );
    final count = _parser.parseInteger(
      args['installment_count'],
      field: 'تعداد اقساط',
      min: 1,
      max: 360,
    );
    final start = _parser.parseDate(
      args['start_date'],
      field: 'تاریخ دریافت وام',
    );

    final rawDates = args['installment_due_dates'];
    if (rawDates is! List || rawDates.isEmpty) {
      throw const ValidationException(
        'تاریخ سررسید اقساط مشخص نیست؛ تاریخ اولین قسط را بگویید.',
      );
    }
    final dueDates = <CalendarDate>[];
    for (var i = 0; i < rawDates.length; i++) {
      dueDates.add(
        _parser.parseDate(rawDates[i], field: 'تاریخ قسط ${i + 1}').date,
      );
    }
    if (dueDates.length != count) {
      throw ValidationException(
        'تعداد تاریخ‌های سررسید (${dueDates.length}) با تعداد اقساط ($count) برابر نیست.',
      );
    }
    for (var i = 1; i < dueDates.length; i++) {
      if (!dueDates[i].isAfter(dueDates[i - 1])) {
        throw const ValidationException('تاریخ سررسید اقساط باید صعودی باشد.');
      }
    }

    Account? account;
    final accountRef = _optionalString(args['account']);
    if (accountRef != null) {
      account = await _resolveAccount(accountRef);
    }

    var interest = Rial.zero;
    final interestInfo = args['interest_information'];
    if (interestInfo is Map) {
      final info = interestInfo.map((key, value) => MapEntry('$key', value));
      final total = info['total_interest_amount'];
      if (total != null) {
        interest = _parser.parseMoney(
          total,
          info['amount_unit'] ?? args['amount_unit'],
          fallbackUnit: defaultCurrency,
          field: 'مبلغ سود',
          allowZero: true,
        );
      }
    }

    Rial? expectedInstallment;
    if (args['installment_amount'] != null) {
      expectedInstallment = _parser.parseMoney(
        args['installment_amount'],
        args['amount_unit'],
        fallbackUnit: defaultCurrency,
        field: 'مبلغ قسط',
        allowZero: true,
      );
    }

    final payload = <String, Object?>{
      'title': title,
      'principalRial': principal.value,
      'interestRial': interest.value,
      'installmentCount': count,
      'installmentAmountRial': expectedInstallment?.value,
      'accountId': account?.id,
      'accountName': account?.accountName,
      'startDate': start.date.toIso(),
      'dueDates': dueDates.map((date) => date.toIso()).toList(),
      'description': _optionalString(args['description']),
    };
    return _propose(
      call,
      sessionId,
      DaramTool.addLoan,
      payload,
      'وام «$title» با $count قسط',
      'پیش‌نویس وام و جدول اقساط آماده تأیید است.',
    );
  }

  Future<ToolExecution> _markInstallmentPaid(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final args = call.arguments;
    final loanRef = _parser.requireString(args['loan_id'], field: 'وام');
    final installmentRef = _parser.requireString(
      args['installment_id'],
      field: 'قسط',
    );
    final paymentDate = _parser.parseDate(
      args['payment_date'],
      field: 'تاریخ پرداخت',
    );

    final loan = await _resolveLoan(loanRef);
    final installments = await _loans.installmentsOf(loan.id);
    if (installments.isEmpty) {
      throw const ValidationException('برای این وام قسطی ثبت نشده است.');
    }
    Installment? installment;
    final asNumber = int.tryParse(
      installmentRef.replaceAll(RegExp('[^0-9]'), ''),
    );
    for (final item in installments) {
      if (item.id == installmentRef) installment = item;
    }
    if (installment == null && asNumber != null) {
      for (final item in installments) {
        if (item.number == asNumber) {
          installment = item;
          break;
        }
      }
    }
    if (installment == null) {
      throw const ValidationException(
        'قسط مورد نظر پیدا نشد؛ شماره قسط را از جدول اقساط بگو.',
      );
    }
    if (installment.isPaid) {
      throw const ValidationException('این قسط قبلاً پرداخت شده است.');
    }

    final paid = args['paid_amount'] == null
        ? installment.amountRial
        : _parser.parseMoney(
            args['paid_amount'],
            args['amount_unit'],
            fallbackUnit: defaultCurrency,
            field: 'مبلغ پرداختی',
          );

    final payload = <String, Object?>{
      'loanId': loan.id,
      'loanTitle': loan.title,
      'installmentId': installment.id,
      'installmentNumber': installment.number,
      'paymentDate': paymentDate.date.toIso(),
      'paidAmountRial': paid.value,
      'scheduledAmountRial': installment.amountRial.value,
      'dueDate': CalendarDate.fromStored(installment.dueDate).toIso(),
    };
    return _propose(
      call,
      sessionId,
      DaramTool.markInstallmentPaid,
      payload,
      'پرداخت قسط ${installment.number} وام «${loan.title}»',
      'پیش‌نویس پرداخت قسط آماده تأیید است.',
    );
  }

  Future<ToolExecution> _queryTransactions(ToolCall call) async {
    final args = call.arguments;
    final range = _resolveRange(args['date_range']);
    final type = TransactionType.tryParse(args['transaction_type']);
    Account? account;
    final accountRef = _optionalString(args['account_filter']);
    if (accountRef != null) account = await _resolveAccount(accountRef);
    Category? category;
    final categoryRef = _optionalString(args['category_filter']);
    if (categoryRef != null) {
      category =
          await _categories.resolve(categoryRef, CategoryType.expense) ??
          await _categories.resolve(categoryRef, CategoryType.income);
    }

    final limit = args['limit'] is num
        ? _parser.parseInteger(
            args['limit'],
            field: 'تعداد نتایج',
            min: 1,
            max: 100,
          )
        : 50;

    final rows = await _transactions.list(
      TransactionFilter(
        start: range.start.stored,
        end: range.end.stored,
        type: type,
        accountId: account?.id,
        categoryId: category?.id,
        searchQuery: _optionalString(args['search_query']),
        limit: limit,
      ),
    );
    final income = Rial.sum(
      rows.where((row) => row.isIncome).map((row) => row.amountRial),
    );
    final expense = Rial.sum(
      rows.where((row) => row.isExpense).map((row) => row.amountRial),
    );

    final content = {
      'ok': true,
      'date_range': {'start': range.start.toIso(), 'end': range.end.toIso()},
      'totals': {
        'income_rial': income.value,
        'expense_rial': expense.value,
        'net_rial': (income - expense).value,
        'count': rows.length,
      },
      'items': [
        for (final row in rows.take(limit))
          {
            'date': CalendarDate.fromStored(row.transactionDate).toIso(),
            'type': row.type.name,
            'amount_rial': row.amountRial.value,
            'category': row.categoryName ?? 'بدون دسته‌بندی',
            'account': row.accountName,
            'description': row.description,
          },
      ],
      'note': 'این اعداد مستقیماً از پایگاه داده محلی محاسبه شده‌اند.',
    };
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode(content),
      userMessage: 'اطلاعات ذخیره‌شده بررسی شد.',
    );
  }

  Future<ToolExecution> _generateReport(ToolCall call) async {
    final args = call.arguments;
    final start = _parser
        .parseDate(args['start_date'], field: 'تاریخ شروع')
        .date;
    final end = _parser.parseDate(args['end_date'], field: 'تاریخ پایان').date;
    if (end.isBefore(start)) {
      throw const ValidationException(
        'تاریخ پایان نمی‌تواند قبل از تاریخ شروع باشد.',
      );
    }
    final range = DateRange(start, end);

    Account? account;
    final accountRef = _optionalString(args['account_filter']);
    if (accountRef != null) account = await _resolveAccount(accountRef);
    Category? category;
    final categoryRef = _optionalString(args['category_filter']);
    if (categoryRef != null) {
      category =
          await _categories.resolve(categoryRef, CategoryType.expense) ??
          await _categories.resolve(categoryRef, CategoryType.income);
    }
    final grouping = _optionalString(args['grouping']) ?? 'category';

    final report = await _analytics.buildReport(
      range: range,
      accountId: account?.id,
      categoryId: category?.id,
      grouping: grouping,
    );

    final metadata = _serializeReport(report);
    final content = {
      'ok': true,
      'report': {
        'date_range': {'start': start.toIso(), 'end': end.toIso()},
        'income_rial': report.summary.income.value,
        'expense_rial': report.summary.expense.value,
        'net_rial': report.summary.net.value,
        'transaction_count': report.summary.transactionCount,
        'categories': [
          for (final item in report.categories.take(10))
            {
              'name': item.name,
              'amount_rial': item.amount.value,
              'share_percent': (item.share * 100).toStringAsFixed(1),
            },
        ],
      },
      'note': 'جمع‌ها توسط برنامه محاسبه شده‌اند؛ آن‌ها را تغییر نده.',
    };

    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode(content),
      report: metadata,
      userMessage: 'گزارش مالی آماده شد.',
    );
  }

  Map<String, Object?> _serializeReport(ReportData report) => {
    'range': {
      'start': report.range.start.toIso(),
      'end': report.range.end.toIso(),
    },
    'summary': {
      'incomeRial': report.summary.income.value,
      'expenseRial': report.summary.expense.value,
      'netRial': report.summary.net.value,
      'count': report.summary.transactionCount,
    },
    'categories': [
      for (final item in report.categories)
        {
          'name': item.name,
          'amountRial': item.amount.value,
          'share': item.share,
          'colorHex': item.colorHex,
          'icon': item.icon,
        },
    ],
    'transactions': [
      for (final row in report.transactions.take(100))
        {
          'date': CalendarDate.fromStored(row.transactionDate).toIso(),
          'type': row.type.name,
          'amountRial': row.amountRial.value,
          'category': row.categoryName,
          'account': row.accountName,
          'description': row.description,
        },
    ],
    'grouping': report.grouping,
    'type': report.transactionType?.name ?? 'expense',
  };

  DateRange _resolveRange(Object? raw) {
    if (raw is Map) {
      final map = raw.map((key, value) => MapEntry('$key', value));
      final start = map['start'];
      final end = map['end'];
      if (start != null && end != null) {
        final from = _parser.parseDate(start, field: 'شروع بازه').date;
        final to = _parser.parseDate(end, field: 'پایان بازه').date;
        return from.isAfter(to) ? DateRange(to, from) : DateRange(from, to);
      }
    }
    if (raw is String && raw.trim().isNotEmpty) {
      final range = PersianDateParser().parseRange(raw);
      if (range != null && range.start.date != null && range.end.date != null) {
        return DateRange(range.start.date!, range.end.date!);
      }
      final single = _parser.parseDate(raw, field: 'بازه');
      return DateRange(single.date, single.date);
    }
    final today = CalendarDate.today();
    return DateRange(today.startOfJalaliMonth, today);
  }

  ToolExecution _propose(
    ToolCall call,
    String sessionId,
    DaramTool tool,
    Map<String, Object?> payload,
    String summary,
    String userMessage,
  ) {
    final actionId = _uuid.v4();
    final operationId = _uuid.v4();
    final action = PendingAction(
      id: actionId,
      sessionId: sessionId,
      actionType: tool.toolName,
      payload: payload,
      status: PendingActionStatus.pending,
      operationId: operationId,
      createdAt: DateTime.now().toUtc(),
    );
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'ok': true,
        'status': 'pending_user_confirmation',
        'action_id': actionId,
        'summary': summary,
        'message': 'پیش‌نویس ساخته شد و در انتظار تأیید صریح کاربر است. هنوز هیچ چیزی ذخیره نشده است.',
      }),
      pendingAction: action,
      userMessage: userMessage,
    );
  }

  ToolExecution _error(ToolCall call, String message) => ToolExecution(
    toolCallId: call.id,
    toolName: call.name,
    ok: false,
    content: jsonEncode({
      'ok': false,
      'error': message,
      'instruction': 'عملیات انجام نشد. اگر اطلاعات ضروری کم است، یک سؤال کوتاه از کاربر بپرس. مقادیر را حدس نزن.',
    }),
  );

  Future<Account> _resolveAccount(String reference) async {
    final direct = await _accounts.resolve(reference);
    if (direct != null) return direct;

    final normalized = _normalize(reference);
    final accounts = await _accounts.list();
    final generic = <String>{
      'حسابم',
      'کارتم',
      'حساب',
      'کارت',
      'حساباصلی',
    }.any((word) => normalized.contains(word));
    if (generic && accounts.length == 1) return accounts.first;

    final matches = accounts.where((account) {
      final name = _normalize(account.accountName);
      final bank = _normalize(account.bankName);
      return name.contains(normalized) ||
          normalized.contains(name) ||
          bank.contains(normalized) ||
          normalized.contains(bank);
    }).toList();
    if (matches.length == 1) return matches.first;
    if (matches.length > 1) {
      throw ValidationException(
        'چند حساب با «$reference» پیدا شد (${matches.map((account) => account.accountName).join('، ')}). کدام حساب؟',
      );
    }

    final available = accounts.isEmpty
        ? 'هنوز حسابی ثبت نشده است.'
        : 'حساب‌های موجود: ${accounts.map((account) => account.accountName).join('، ')}.';
    throw ValidationException('حسابی با «$reference» پیدا نشد. $available');
  }

  Future<Loan> _resolveLoan(String reference) async {
    final loans = await _loans.list();
    for (final loan in loans) {
      if (loan.id == reference) return loan;
    }
    final normalized = _normalize(reference);
    final matches = loans
        .where(
          (loan) =>
              _normalize(loan.title).contains(normalized) ||
              normalized.contains(_normalize(loan.title)),
        )
        .toList();
    if (matches.length == 1) return matches.first;
    if (matches.isEmpty) {
      throw ValidationException(
        loans.isEmpty
            ? 'هنوز وامی ثبت نشده است.'
            : 'وامی با «$reference» پیدا نشد. وام‌های موجود: ${loans.map((loan) => loan.title).join('، ')}.',
      );
    }
    throw ValidationException(
      'چند وام با این عنوان پیدا شد: ${matches.map((loan) => loan.title).join('، ')}. کدام یکی؟',
    );
  }

  AccountType _accountType(Object? value) {
    final raw = value is String ? value.trim() : '';
    return switch (raw) {
      'bank' || 'بانکی' || 'حساب بانکی' => AccountType.bank,
      'cash' || 'نقدی' => AccountType.cash,
      'digitalWallet' ||
      'کیف پول' ||
      'کیف پول دیجیتال' => AccountType.digitalWallet,
      'savings' || 'پس‌انداز' => AccountType.savings,
      _ => AccountType.other,
    };
  }

  String? _optionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
