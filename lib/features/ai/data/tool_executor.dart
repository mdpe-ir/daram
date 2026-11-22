import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/category_styles.dart';
import '../../../core/constants/iranian_banks.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/jalali_text.dart';
import '../../../core/time/persian_date_parser.dart';
import '../../../data/database/app_database.dart';
import '../../accounts/data/account_repository.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_models.dart';
import '../../chat/domain/drafts.dart';
import '../../accounts/domain/account.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart';
import '../../dashboard/data/analytics_repository.dart';
import '../../dashboard/domain/analytics.dart';
import '../../loans/data/loan_repository.dart';
import '../../loans/domain/loan.dart';
import '../../sms/data/sms_review_repository.dart';
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
    this.smsSuggestionIds = const <String>[],
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

  /// SMS suggestions shown by this execution, rendered as cards in chat.
  final List<String> smsSuggestionIds;

  /// Short Persian sentence the UI may show while the model composes its reply.
  final String? userMessage;
}

/// Validates tool arguments against the local domain and turns write tools into
/// pending drafts.
///
/// This class is the boundary between "the model proposed something" and
/// "the app is willing to save something". Financial tools only create drafts;
/// SMS decision tools act on a suggestion the user has already seen in the
/// conversation, and can never invent an amount or a target row.
class ToolExecutor {
  ToolExecutor({
    required ToolRegistry registry,
    required AccountRepository accounts,
    required CategoryRepository categories,
    required TransactionRepository transactions,
    required LoanRepository loans,
    required AnalyticsRepository analytics,
    required SmsReviewRepository sms,
    required ChatRepository chat,
    ArgumentParser? parser,
  }) : _registry = registry,
       _accounts = accounts,
       _categories = categories,
       _transactions = transactions,
       _loans = loans,
       _analytics = analytics,
       _sms = sms,
       _chat = chat,
       _parser = parser ?? const ArgumentParser();

  final ToolRegistry _registry;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final LoanRepository _loans;
  final AnalyticsRepository _analytics;
  final SmsReviewRepository _sms;
  final ChatRepository _chat;
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
        DaramTool.manageCategory => _manageCategory(call),
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
        DaramTool.queryTransactions => _queryTransactions(
          call,
          defaultCurrency,
        ),
        DaramTool.generateReport => _generateReport(call, defaultCurrency),
        DaramTool.reviewSmsSuggestions => _reviewSmsSuggestions(
          call,
          defaultCurrency,
        ),
        DaramTool.confirmSmsSuggestion => _confirmSmsSuggestion(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.editSmsSuggestion => _editSmsSuggestion(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.dismissSmsSuggestion => _dismissSmsSuggestion(
          call,
          sessionId,
        ),
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

  Future<ToolExecution> _manageCategory(ToolCall call) async {
    final args = call.arguments;
    final type = args['type'] == 'income'
        ? CategoryType.income
        : CategoryType.expense;
    final action = args['action'] as String;
    final icon = _categoryIconSlug(args['icon']);
    final colorHex = _categoryColor(args['color_hex']);
    Category? category;
    if (action == 'create') {
      final name = _parser.requireString(args['name'], field: 'نام دسته‌بندی');
      final existing = await _categories.list(type: type);
      final suggestion = suggestCategoryStyle(
        name,
        type,
        usedColors: existing.map((item) => item.colorHex),
      );
      // The model can omit the style or fall back to the old tag/purple
      // defaults. For a topic we understand, prefer the semantic suggestion so
      // every new category does not look identical.
      var resolvedIcon = suggestion.icon;
      if (icon != null && !(suggestion.semantic && icon == 'tag')) {
        resolvedIcon = icon;
      }
      var resolvedColor = suggestion.colorHex;
      if (colorHex != null &&
          !(suggestion.semantic && colorHex.toUpperCase() == '#8B5CF6')) {
        resolvedColor = colorHex;
      }
      category = await _categories.create(
        name: name,
        type: type,
        icon: resolvedIcon,
        colorHex: resolvedColor,
      );
    } else {
      final id = _parser.requireString(
        args['category_id'],
        field: 'شناسه دسته‌بندی',
      );
      category = await _categories.findById(id);
      if (category == null || category.type != type) {
        throw const ValidationException(
          'دسته‌بندی با این شناسه و نوع پیدا نشد.',
        );
      }
      if (action == 'rename') {
        final name = _parser.requireString(
          args['name'],
          field: 'نام دسته‌بندی',
        );
        final existing = await _categories.list(type: type);
        final suggestion = suggestCategoryStyle(
          name,
          type,
          usedColors: existing.map((item) => item.colorHex),
        );
        final current = category;
        final resolvedIcon = icon == null
            ? current.icon
            : suggestion.semantic && icon == 'tag'
            ? suggestion.icon
            : icon;
        final resolvedColor = colorHex == null
            ? current.colorHex
            : suggestion.semantic && colorHex.toUpperCase() == '#8B5CF6'
            ? suggestion.colorHex
            : colorHex;
        category = current.copyWith(
          name: name,
          icon: resolvedIcon,
          colorHex: resolvedColor,
        );
        await _categories.update(category);
      } else {
        await _categories.delete(category.id);
      }
    }
    final categories = await _categories.list();
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'status': 'completed',
        'action': action,
        'category_id': category.id,
        'name': category.name,
        'icon': category.icon,
        'color_hex': category.colorHex,
        'categories': [
          for (final item in categories)
            {
              'id': item.id,
              'name': item.name,
              'type': item.type.name,
              'icon': item.icon,
              'color_hex': item.colorHex,
            },
        ],
      }),
    );
  }

  /// Validates a model-supplied icon slug; `null` means "keep the default".
  String? _categoryIconSlug(Object? value) {
    final raw = _optionalString(value);
    if (raw == null) return null;
    if (!categoryIconCatalog.containsKey(raw)) {
      throw ValidationException(
        'آیکون «$raw» معتبر نیست. یکی از آیکون‌های فهرست دسته‌بندی را بفرست.',
      );
    }
    return raw;
  }

  /// Validates a model-supplied colour; `null` means "keep the default".
  String? _categoryColor(Object? value) {
    final raw = _optionalString(value);
    if (raw == null) return null;
    final normalized = raw.startsWith('#') ? raw : '#$raw';
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(normalized)) {
      throw const ValidationException(
        'رنگ دسته‌بندی باید به شکل #RRGGBB باشد.',
      );
    }
    return normalized.toUpperCase();
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

  Future<ToolExecution> _queryTransactions(
    ToolCall call,
    CurrencyUnit displayCurrency,
  ) async {
    final formatter = MoneyFormatter(unit: displayCurrency);
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

    final jalali = JalaliText();
    final content = {
      'ok': true,
      'date_range': {
        'start': range.start.toIso(),
        'end': range.end.toIso(),
        'start_jalali': const JalaliText(persianDigits: false)
            .numeric(range.start),
        'end_jalali': const JalaliText(persianDigits: false).numeric(range.end),
        'label_numeric_fa':
            '${jalali.numeric(range.start)} تا ${jalali.numeric(range.end)}',
        'label_fa': '${jalali.date(range.start)} تا ${jalali.date(range.end)}',
      },
      'display_currency': displayCurrency.name,
      'totals': {
        'income_display': formatter.format(income),
        'expense_display': formatter.format(expense),
        'net_display': formatter.format(income - expense),
        'income_rial': income.value,
        'expense_rial': expense.value,
        'net_rial': (income - expense).value,
        'count': rows.length,
      },
      'items': [
        for (final row in rows.take(limit))
          {
            'date': CalendarDate.fromStored(row.transactionDate).toIso(),
            'date_jalali': const JalaliText(persianDigits: false)
                .numeric(CalendarDate.fromStored(row.transactionDate)),
            'date_label_fa': jalali.date(
              CalendarDate.fromStored(row.transactionDate),
            ),
            'type': row.type.name,
            'amount_rial': row.amountRial.value,
            'amount_display': formatter.format(row.amountRial),
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

  Future<ToolExecution> _generateReport(
    ToolCall call,
    CurrencyUnit displayCurrency,
  ) async {
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
    final money = MoneyFormatter(unit: displayCurrency);
    final rangeText = JalaliText();
    final content = {
      'ok': true,
      'display_currency': displayCurrency.name,
      'report': {
        'date_range': {
          'start': start.toIso(),
          'end': end.toIso(),
          'start_jalali': const JalaliText(persianDigits: false).numeric(start),
          'end_jalali': const JalaliText(persianDigits: false).numeric(end),
          'label_numeric_fa':
              '${rangeText.numeric(start)} تا ${rangeText.numeric(end)}',
          'label_fa': '${rangeText.date(start)} تا ${rangeText.date(end)}',
        },
        'income_rial': report.summary.income.value,
        'expense_rial': report.summary.expense.value,
        'net_rial': report.summary.net.value,
        'income_display': money.format(report.summary.income),
        'expense_display': money.format(report.summary.expense),
        'net_display': money.format(report.summary.net),
        'transaction_count': report.summary.transactionCount,
        'transaction_count_display': PersianDigits.toPersian(
          '${report.summary.transactionCount}',
        ),
        'categories': [
          for (final item in report.categories.take(10))
            {
              'name': item.name,
              'amount_rial': item.amount.value,
              'amount_display': money.format(item.amount),
              'share_percent': (item.share * 100).toStringAsFixed(1),
              'share_display': PersianDigits.toPersian(
                '${(item.share * 100).round()}٪',
              ),
            },
        ],
      },
      'note': 'جمع‌ها توسط برنامه محاسبه شده‌اند؛ آن‌ها را تغییر نده. بازه و مبالغ نمایشی را از label_fa و *_display نقل کن.',
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

  Future<ToolExecution> _reviewSmsSuggestions(
    ToolCall call,
    CurrencyUnit displayCurrency,
  ) async {
    final limit = call.arguments['limit'] == null
        ? 10
        : _parser.parseInteger(
            call.arguments['limit'],
            field: 'تعداد پیشنهادها',
            min: 1,
            max: 20,
          );
    final rows = await _sms.open();
    final accounts = await _accounts.list();
    final categories = await _categories.list();
    final accountIds = {for (final account in accounts) account.id};
    final categoryIds = {for (final category in categories) category.id};
    final formatter = MoneyFormatter(unit: displayCurrency);
    final shown = rows.take(limit).toList();

    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'ok': true,
        'count': rows.length,
        'shown': shown.length,
        'display_currency': displayCurrency.name,
        'suggestions': [
          for (final row in shown)
            _smsSuggestionJson(
              row,
              formatter: formatter,
              accountIds: accountIds,
              categoryIds: categoryIds,
            ),
        ],
        'note': rows.isEmpty
            ? 'هیچ پیشنهاد پیامکی در انتظار بازبینی روی دستگاه نیست.'
            : 'این فهرست مستقیماً از پیشنهادهای پیامکی دستگاه خوانده شده است و در گفتگو به‌صورت کارت نمایش داده می‌شود. برای تأیید یا رد، فقط وقتی کاربر صریحاً خواست از ابزارهای confirm_sms_suggestion یا dismiss_sms_suggestion با همین suggestion_id استفاده کن. برای تغییر جزئیات از edit_sms_suggestion استفاده کن و هرگز شناسه نساز.',
      }),
      smsSuggestionIds: [for (final row in shown) row.id],
      userMessage: rows.isEmpty
          ? 'پیشنهاد پیامکی در انتظار بازبینی نیست.'
          : 'پیشنهادهای پیامکی بررسی شد.',
    );
  }

  Map<String, Object?> _smsSuggestionJson(
    SmsSuggestionRow row, {
    required MoneyFormatter formatter,
    required Set<String> accountIds,
    required Set<String> categoryIds,
  }) {
    final draft = SmsReviewRepository.draftOf(row);
    return {
      'suggestion_id': row.id,
      'sender': row.sender,
      'received_at': row.receivedAt.toUtc().toIso8601String(),
      'type': draft.type.name,
      'amount_rial': draft.amountRial.value,
      'amount_display': draft.amountRial.isZero
          ? null
          : formatter.format(draft.amountRial),
      'account': draft.accountName.isEmpty ? null : draft.accountName,
      'account_id': draft.accountId.isEmpty ? null : draft.accountId,
      'category': draft.categoryName,
      'description': draft.description,
      'date': draft.date.toIso(),
      'date_jalali': JalaliText(persianDigits: false).date(draft.date),
      'status': row.status,
      'edited': row.editedAt != null,
      'ready_to_confirm': SmsReviewRepository.isReady(
        row,
        accountIds: accountIds,
        categoryIds: categoryIds,
      ),
    };
  }

  /// Resolves an open SMS suggestion by its exact id.
  ///
  /// Editing a draft is allowed before the cards are persisted (for example in
  /// the same turn as a review); only confirm/dismiss require prior display.
  Future<SmsSuggestionRow> _smsTarget(ToolCall call) async {
    final id = _parser.requireString(
      call.arguments['suggestion_id'],
      field: 'شناسه پیشنهاد پیامکی',
    );
    final row = await _sms.find(id);
    if (row == null) {
      throw const NotFoundException('پیشنهاد پیامکی با این شناسه پیدا نشد.');
    }
    if (!SmsReviewRepository.openStatuses.contains(row.status)) {
      throw const ValidationException(
        'این پیشنهاد دیگر در انتظار بازبینی نیست.',
      );
    }
    return row;
  }

  /// Resolves an SMS suggestion that the user has already seen in chat.
  Future<SmsSuggestionRow> _presentedSmsTarget(
    ToolCall call,
    String sessionId,
  ) async {
    final row = await _smsTarget(call);
    if (!await _chat.hasPresentedSmsSuggestion(
      sessionId: sessionId,
      suggestionId: row.id,
    )) {
      throw const ValidationException(
        'این پیشنهاد هنوز در گفتگو نمایش داده نشده است. اول با review_sms_suggestions فهرست را نشان بده و بعد از دیدن و تأیید صریح کاربر اقدام کن.',
      );
    }
    return row;
  }

  Future<ToolExecution> _confirmSmsSuggestion(
    ToolCall call,
    String sessionId,
    CurrencyUnit displayCurrency,
  ) async {
    final row = await _presentedSmsTarget(call, sessionId);
    final draft = SmsReviewRepository.draftOf(row);
    if (row.status != 'pending' ||
        draft.accountId.isEmpty ||
        draft.amountRial.isZero) {
      throw const ValidationException(
        'این پیشنهاد هنوز مبلغ یا حساب معتبر ندارد؛ اول با edit_sms_suggestion اصلاحش کن.',
      );
    }
    await _sms.confirm(row.id);
    final formatter = MoneyFormatter(unit: displayCurrency);
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'ok': true,
        'status': 'confirmed',
        'suggestion_id': row.id,
        'summary': _smsSummary(draft, formatter),
        'message': 'این پیشنهاد به‌عنوان تراکنش ثبت شد و پول واقعی جابه‌جا نشده است؛ فقط رکورد مالی ساخته شد. حالا کوتاه به کاربر خبر بده.',
      }),
      userMessage: 'پیشنهاد پیامکی ثبت شد.',
    );
  }

  Future<ToolExecution> _editSmsSuggestion(
    ToolCall call,
    String sessionId,
    CurrencyUnit displayCurrency,
  ) async {
    final row = await _smsTarget(call);
    final current = SmsReviewRepository.draftOf(row);
    final args = call.arguments;

    var type = current.type;
    if (args['type'] != null) {
      type =
          TransactionType.tryParse(args['type']) ??
          (throw const ValidationException(
            'نوع تراکنش باید درآمد یا هزینه باشد.',
          ));
    }
    var amount = current.amountRial;
    if (args['amount'] != null) {
      amount = _parser.parseMoney(
        args['amount'],
        args['amount_unit'],
        fallbackUnit: displayCurrency,
      );
    }
    var date = current.date;
    if (args['date'] != null) {
      date = _parser.parseDate(args['date'], field: 'تاریخ تراکنش').date;
    }
    var accountId = current.accountId;
    var accountName = current.accountName;
    if (args['account'] != null) {
      final account = await _resolveAccount(
        _parser.requireString(args['account'], field: 'حساب'),
      );
      accountId = account.id;
      accountName = account.accountName;
    }

    final categoryType = type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    Category? category;
    if (args['category'] != null) {
      final name = _parser.requireString(args['category'], field: 'دسته‌بندی');
      category = await _categories.resolve(name, categoryType);
      if (category == null) {
        throw ValidationException(
          'دسته‌بندی «$name» برای این نوع تراکنش پیدا نشد.',
        );
      }
    } else if (current.categoryId != null) {
      final existing = await _categories.findById(current.categoryId!);
      if (existing != null && existing.type == categoryType) {
        category = existing;
      }
    }

    var description = current.description;
    if (args.containsKey('description')) {
      description = _optionalString(args['description']);
    }

    final draft = TransactionDraft(
      type: type,
      amountRial: amount,
      accountId: accountId,
      accountName: accountName,
      categoryId: category?.id,
      categoryName: category?.name,
      date: date,
      description: description,
    );
    await _sms.updateDraft(row.id, draft);
    final formatter = MoneyFormatter(unit: displayCurrency);
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'ok': true,
        'status': 'updated',
        'suggestion_id': row.id,
        'summary': _smsSummary(draft, formatter),
        'amount_display': amount.isZero ? null : formatter.format(amount),
        'ready_to_confirm': accountId.isNotEmpty && !amount.isZero,
        'message': 'پیش‌نویس پیامکی به‌روزرسانی شد و هنوز چیزی ثبت نشده است. تغییرات را کوتاه به کاربر بگو و برای ثبت نهایی منتظر تأیید صریح بمان.',
      }),
      userMessage: 'پیش‌نویس پیامکی ویرایش شد.',
    );
  }

  Future<ToolExecution> _dismissSmsSuggestion(
    ToolCall call,
    String sessionId,
  ) async {
    final row = await _presentedSmsTarget(call, sessionId);
    final ignorePattern = call.arguments['ignore_pattern'] == true;
    await _sms.dismiss(row.id, ignorePattern: ignorePattern);
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'ok': true,
        'status': 'dismissed',
        'suggestion_id': row.id,
        'message': ignorePattern
            ? 'این پیشنهاد و قالب‌های مشابه همان سرشماره رد شدند.'
            : 'این پیشنهاد رد شد.',
      }),
      userMessage: 'پیشنهاد پیامکی رد شد.',
    );
  }

  String _smsSummary(TransactionDraft draft, MoneyFormatter formatter) =>
      '${draft.type.labelFa} ${formatter.format(draft.amountRial)} در '
      '${draft.accountName.isEmpty ? 'حساب نامشخص' : draft.accountName}';

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
