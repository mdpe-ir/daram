import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart' show ThemeMode;
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
import '../../accounts/domain/account.dart';
import '../../assets/data/asset_repository.dart';
import '../../assets/domain/asset_holding.dart';
import '../../assets/domain/asset_quantity.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart';
import '../../chat/data/chat_repository.dart';
import '../../chat/domain/chat_models.dart';
import '../../chat/domain/drafts.dart';
import '../../dashboard/data/analytics_repository.dart';
import '../../dashboard/domain/analytics.dart';
import '../../loans/data/loan_repository.dart';
import '../../loans/domain/loan.dart';
import '../../obligations/data/obligation_repository.dart';
import '../../obligations/domain/obligation.dart';
import '../../sms/data/sms_review_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/data/transfer_repository.dart';
import '../../transactions/domain/transaction_record.dart';
import '../domain/ai_models.dart';
import '../domain/settings_change.dart';
import '../domain/tool.dart';
import 'argument_parser.dart';
import 'tool_registry.dart';

/// Resolves a live market rate for an asset kind/code.
///
/// Injected by the app so the AI layer does not depend on the market feature
/// and tests can run without network access.
typedef AssetRateLookup =
    Future<({Rial rate, DateTime updatedAt, String source})> Function(
      AssetKind kind,
      String? code,
    );

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
    this.settingsChange,
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

  /// A non-financial preference change to apply immediately (theme, unit…).
  final SettingsChange? settingsChange;
}

/// A validated write payload before it becomes a pending action.
class _DraftSpec {
  const _DraftSpec({
    required this.payload,
    required this.summary,
    required this.userMessage,
    this.notes = const <String>[],
  });

  final Map<String, Object?> payload;
  final String summary;
  final String userMessage;
  final List<String> notes;
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
    required AssetRepository assets,
    required ObligationRepository obligations,
    required TransferRepository transfers,
    AssetRateLookup? marketRates,
    ArgumentParser? parser,
  }) : _registry = registry,
       _accounts = accounts,
       _categories = categories,
       _transactions = transactions,
       _loans = loans,
       _analytics = analytics,
       _sms = sms,
       _chat = chat,
       _assets = assets,
       _obligations = obligations,
       _transfers = transfers,
       _marketRates = marketRates,
       _parser = parser ?? const ArgumentParser();

  final ToolRegistry _registry;
  final AccountRepository _accounts;
  final CategoryRepository _categories;
  final TransactionRepository _transactions;
  final LoanRepository _loans;
  final AnalyticsRepository _analytics;
  final SmsReviewRepository _sms;
  final ChatRepository _chat;
  final AssetRepository _assets;
  final ObligationRepository _obligations;
  final TransferRepository _transfers;
  final AssetRateLookup? _marketRates;
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
        DaramTool.queryRecords => _queryRecords(call, defaultCurrency),
        DaramTool.financialOverview => _financialOverview(
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
        DaramTool.updatePendingDraft => _updatePendingDraft(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.cancelPendingDraft => _cancelPendingDraft(call, sessionId),
        DaramTool.manageAccount => _manageAccount(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.manageTransaction => _manageTransaction(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.manageTransfer => _manageTransfer(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.manageLoan => _manageLoan(call, sessionId),
        DaramTool.manageAsset => _manageAsset(call, sessionId, defaultCurrency),
        DaramTool.manageObligation => _manageObligation(
          call,
          sessionId,
          defaultCurrency,
        ),
        DaramTool.updateSettings => _updateSettings(call),
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

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Add tools (draft builders)
  // ---------------------------------------------------------------------------

  Future<_DraftSpec> _buildAccountDraft(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
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
    return _DraftSpec(
      payload: <String, Object?>{
        'bankId': bankId,
        'bankName': resolvedBankName,
        'accountName': accountName,
        'accountType': type.name,
        'initialBalanceRial': balance.value,
        'cardLastFour': card,
        'description': _optionalString(args['description']),
      },
      summary: 'حساب «$accountName» در $resolvedBankName',
      userMessage: 'حساب جدید آماده تأیید است.',
    );
  }

  Future<_DraftSpec> _buildTransactionDraft(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
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

    return _DraftSpec(
      payload: <String, Object?>{
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
      },
      summary: '${type.labelFa} ${amount.value} ریال در ${account.accountName}',
      userMessage: 'پیش‌نویس ${type.labelFa} آماده تأیید است.',
      notes: [
        if (assumedCategory && categoryName != null)
          'دسته‌بندی «$categoryName» پیدا نشد و دسته پیش‌فرض انتخاب شد.',
        if (date.ambiguous)
          'سال تاریخ ذکر نشده بود؛ نزدیک‌ترین تاریخ گذشته انتخاب شد.',
      ],
    );
  }

  Future<_DraftSpec> _buildTransferDraft(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
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
    return _DraftSpec(
      payload: <String, Object?>{
        'sourceAccountId': source.id,
        'sourceAccountName': source.accountName,
        'destinationAccountId': destination.id,
        'destinationAccountName': destination.accountName,
        'amountRial': amount.value,
        'feeRial': fee.value,
        'date': date.date.toIso(),
        'description': _optionalString(args['description']),
      },
      summary:
          'انتقال ${amount.value} ریال از ${source.accountName} به ${destination.accountName}',
      userMessage: 'پیش‌نویس انتقال آماده تأیید است.',
    );
  }

  Future<_DraftSpec> _buildLoanDraft(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
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

    return _DraftSpec(
      payload: <String, Object?>{
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
      },
      summary: 'وام «$title» با $count قسط',
      userMessage: 'پیش‌نویس وام و جدول اقساط آماده تأیید است.',
    );
  }

  Future<_DraftSpec> _buildInstallmentPaymentDraft(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
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

    return _DraftSpec(
      payload: <String, Object?>{
        'loanId': loan.id,
        'loanTitle': loan.title,
        'installmentId': installment.id,
        'installmentNumber': installment.number,
        'paymentDate': paymentDate.date.toIso(),
        'paidAmountRial': paid.value,
        'scheduledAmountRial': installment.amountRial.value,
        'dueDate': CalendarDate.fromStored(installment.dueDate).toIso(),
      },
      summary: 'پرداخت قسط ${installment.number} وام «${loan.title}»',
      userMessage: 'پیش‌نویس پرداخت قسط آماده تأیید است.',
    );
  }

  Future<ToolExecution> _addAccount(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildAccountDraft(call.arguments, defaultCurrency);
    return _propose(call, sessionId, DaramTool.addAccount, spec);
  }

  Future<ToolExecution> _addTransaction(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildTransactionDraft(call.arguments, defaultCurrency);
    return _propose(call, sessionId, DaramTool.addTransaction, spec);
  }

  Future<ToolExecution> _addTransfer(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildTransferDraft(call.arguments, defaultCurrency);
    return _propose(call, sessionId, DaramTool.addTransfer, spec);
  }

  Future<ToolExecution> _addLoan(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildLoanDraft(call.arguments, defaultCurrency);
    return _propose(call, sessionId, DaramTool.addLoan, spec);
  }

  Future<ToolExecution> _markInstallmentPaid(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildInstallmentPaymentDraft(
      call.arguments,
      defaultCurrency,
    );
    return _propose(call, sessionId, DaramTool.markInstallmentPaid, spec);
  }

  // ---------------------------------------------------------------------------
  // Manage tools (edit / delete existing records)
  // ---------------------------------------------------------------------------

  Future<ToolExecution> _manageAccount(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildManagedAccount(call.arguments, defaultCurrency);
    return _propose(call, sessionId, DaramTool.manageAccount, spec);
  }

  Future<ToolExecution> _manageTransaction(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildManagedTransaction(
      call.arguments,
      defaultCurrency,
    );
    return _propose(call, sessionId, DaramTool.manageTransaction, spec);
  }

  Future<ToolExecution> _manageTransfer(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildManagedTransfer(call.arguments, defaultCurrency);
    return _propose(call, sessionId, DaramTool.manageTransfer, spec);
  }

  Future<ToolExecution> _manageLoan(ToolCall call, String sessionId) async {
    final spec = await _buildManagedLoan(call.arguments);
    return _propose(call, sessionId, DaramTool.manageLoan, spec);
  }

  Future<ToolExecution> _manageAsset(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildManagedAsset(call.arguments, defaultCurrency);
    return _propose(call, sessionId, DaramTool.manageAsset, spec);
  }

  Future<ToolExecution> _manageObligation(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final spec = await _buildManagedObligation(call.arguments, defaultCurrency);
    return _propose(call, sessionId, DaramTool.manageObligation, spec);
  }

  Future<_DraftSpec> _buildManagedAccount(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
    final action = _parser.requireString(args['action'], field: 'عملیات');
    final accountId = _parser.requireString(
      args['account_id'],
      field: 'شناسه حساب',
    );
    final account = await _accounts.findById(accountId);
    if (account == null) {
      throw const NotFoundException('حسابی با این شناسه پیدا نشد.');
    }
    if (action == 'archive' || action == 'unarchive') {
      return _DraftSpec(
        payload: {
          'recordType': 'account',
          'action': action,
          'recordId': account.id,
          'summary': action == 'archive'
              ? 'بایگانی حساب «${account.accountName}»'
              : 'بازگردانی حساب «${account.accountName}»',
          'fields': const <String, Object?>{},
        },
        summary: action == 'archive'
            ? 'بایگانی حساب «${account.accountName}»'
            : 'بازگردانی حساب «${account.accountName}»',
        userMessage: 'پیش‌نویس تغییر حساب آماده تأیید است.',
      );
    }

    final name = args.containsKey('account_name')
        ? _parser.requireString(args['account_name'], field: 'نام حساب')
        : account.accountName;
    var bankId = account.bankId;
    var bankName = account.bankName;
    if (args.containsKey('bank_name')) {
      final raw = _parser.requireString(args['bank_name'], field: 'نام بانک');
      final known = bankByName(raw);
      bankId = known?.id ?? 'other';
      bankName = known?.nameFa ?? raw;
    }
    final type = args.containsKey('account_type')
        ? _accountType(args['account_type'])
        : account.accountType;
    final card = args.containsKey('card_last_four_digits')
        ? _optionalString(args['card_last_four_digits'])
        : account.cardLastFour;
    if (card != null && !RegExp(r'^\d{4}$').hasMatch(card)) {
      throw const ValidationException(
        'چهار رقم آخر کارت باید دقیقاً چهار رقم باشد.',
      );
    }
    final description = args.containsKey('description')
        ? _optionalString(args['description'])
        : account.description;
    return _DraftSpec(
      payload: {
        'recordType': 'account',
        'action': 'update',
        'recordId': account.id,
        'summary': 'ویرایش حساب «$name»',
        'fields': <String, Object?>{
          'accountName': name,
          'bankId': bankId,
          'bankName': bankName,
          'accountType': type.name,
          'cardLastFour': card,
          'description': description,
        },
      },
      summary: 'ویرایش حساب «$name»',
      userMessage: 'پیش‌نویس ویرایش حساب آماده تأیید است.',
    );
  }

  Future<_DraftSpec> _buildManagedTransaction(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
    final action = _parser.requireString(args['action'], field: 'عملیات');
    final current = await _resolveTransaction(args);
    final formatter = MoneyFormatter(unit: defaultCurrency);
    if (action == 'delete') {
      final summary =
          'حذف ${current.type.labelFa} ${formatter.format(current.amountRial)}'
          '${current.description == null ? '' : ' — ${current.description}'}';
      return _DraftSpec(
        payload: {
          'recordType': 'transaction',
          'action': 'delete',
          'recordId': current.id,
          'summary': summary,
          'fields': <String, Object?>{
            'type': current.type.name,
            'amountRial': current.amountRial.value,
            'accountName': current.accountName,
            'categoryName': current.categoryName,
            'date': CalendarDate.fromStored(current.transactionDate).toIso(),
            'description': current.description,
          },
        },
        summary: summary,
        userMessage: 'پیش‌نویس حذف تراکنش آماده تأیید است.',
      );
    }

    final type = args.containsKey('type')
        ? (TransactionType.tryParse(args['type']) ??
              (throw const ValidationException(
                'نوع تراکنش باید درآمد یا هزینه باشد.',
              )))
        : current.type;
    final amount = args['amount'] == null
        ? current.amountRial
        : _parser.parseMoney(
            args['amount'],
            args['amount_unit'],
            fallbackUnit: defaultCurrency,
          );
    final date = args['date'] == null
        ? CalendarDate.fromStored(current.transactionDate)
        : _parser.parseDate(args['date'], field: 'تاریخ تراکنش').date;
    Account? account;
    if (args['account'] != null) {
      account = await _resolveAccount(
        _parser.requireString(args['account'], field: 'حساب'),
      );
    } else {
      account = await _accounts.findById(current.accountId);
      if (account == null) {
        throw const NotFoundException('حساب این تراکنش پیدا نشد.');
      }
    }

    final categoryType = type == TransactionType.income
        ? CategoryType.income
        : CategoryType.expense;
    Category? category;
    if (args['clear_category'] == true) {
      category = null;
    } else if (args['category'] != null) {
      final name = _parser.requireString(args['category'], field: 'دسته‌بندی');
      if (name.replaceAll(' ', '') == 'بدوندسته' ||
          name.replaceAll(' ', '') == 'بدوندسته‌بندی') {
        category = null;
      } else {
        category = await _categories.resolve(name, categoryType);
        if (category == null) {
          throw ValidationException(
            'دسته‌بندی «$name» برای این نوع تراکنش پیدا نشد.',
          );
        }
      }
    } else if (current.categoryId != null) {
      final existing = await _categories.findById(current.categoryId!);
      if (existing != null && existing.type == categoryType) {
        category = existing;
      }
    }
    final description = args.containsKey('description')
        ? _optionalString(args['description'])
        : current.description;
    final summary =
        'ویرایش ${type.labelFa} ${formatter.format(amount)}'
        '${description == null ? '' : ' — $description'}';
    return _DraftSpec(
      payload: {
        'recordType': 'transaction',
        'action': 'update',
        'recordId': current.id,
        'summary': summary,
        'fields': <String, Object?>{
          'type': type.name,
          'amountRial': amount.value,
          'accountId': account.id,
          'accountName': account.accountName,
          'categoryId': category?.id,
          'categoryName': category?.name,
          'date': date.toIso(),
          'description': description,
        },
      },
      summary: summary,
      userMessage: 'پیش‌نویس ویرایش تراکنش آماده تأیید است.',
      notes: [
        if (current.type != type)
          'نوع تراکنش از ${current.type.labelFa} به ${type.labelFa} تغییر می‌کند.',
      ],
    );
  }

  Future<_DraftSpec> _buildManagedTransfer(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
    final action = _parser.requireString(args['action'], field: 'عملیات');
    final current = await _resolveTransfer(args, defaultCurrency);
    final formatter = MoneyFormatter(unit: defaultCurrency);
    if (action == 'delete') {
      final summary =
          'حذف انتقال ${formatter.format(current.amountRial)} از '
          '${current.sourceAccountName ?? '—'} به '
          '${current.destinationAccountName ?? '—'}';
      return _DraftSpec(
        payload: {
          'recordType': 'transfer',
          'action': 'delete',
          'recordId': current.id,
          'summary': summary,
          'fields': <String, Object?>{
            'sourceAccountName': current.sourceAccountName,
            'destinationAccountName': current.destinationAccountName,
            'amountRial': current.amountRial.value,
            'feeRial': current.feeRial.value,
            'date': CalendarDate.fromStored(current.transferDate).toIso(),
            'description': current.description,
          },
        },
        summary: summary,
        userMessage: 'پیش‌نویس حذف انتقال آماده تأیید است.',
      );
    }

    var source = await _accounts.findById(current.sourceAccountId);
    var destination = await _accounts.findById(current.destinationAccountId);
    if (args['source_account'] != null) {
      source = await _resolveAccount(
        _parser.requireString(args['source_account'], field: 'حساب مبدأ'),
      );
    }
    if (args['destination_account'] != null) {
      destination = await _resolveAccount(
        _parser.requireString(args['destination_account'], field: 'حساب مقصد'),
      );
    }
    if (source == null || destination == null) {
      throw const NotFoundException('حساب مبدأ یا مقصد پیدا نشد.');
    }
    if (source.id == destination.id) {
      throw const ValidationException('حساب مبدأ و مقصد باید متفاوت باشند.');
    }
    final amount = args['amount'] == null
        ? current.amountRial
        : _parser.parseMoney(
            args['amount'],
            args['amount_unit'],
            fallbackUnit: defaultCurrency,
          );
    final fee = args['fee_amount'] == null
        ? current.feeRial
        : _parser.parseMoney(
            args['fee_amount'],
            args['amount_unit'],
            fallbackUnit: defaultCurrency,
            field: 'کارمزد',
            allowZero: true,
          );
    final date = args['date'] == null
        ? CalendarDate.fromStored(current.transferDate)
        : _parser.parseDate(args['date'], field: 'تاریخ انتقال').date;
    final description = args.containsKey('description')
        ? _optionalString(args['description'])
        : current.description;
    final summary =
        'ویرایش انتقال ${formatter.format(amount)} از ${source.accountName} '
        'به ${destination.accountName}';
    return _DraftSpec(
      payload: {
        'recordType': 'transfer',
        'action': 'update',
        'recordId': current.id,
        'summary': summary,
        'fields': <String, Object?>{
          'sourceAccountId': source.id,
          'sourceAccountName': source.accountName,
          'destinationAccountId': destination.id,
          'destinationAccountName': destination.accountName,
          'amountRial': amount.value,
          'feeRial': fee.value,
          'date': date.toIso(),
          'description': description,
        },
      },
      summary: summary,
      userMessage: 'پیش‌نویس ویرایش انتقال آماده تأیید است.',
    );
  }

  Future<_DraftSpec> _buildManagedLoan(Map<String, Object?> args) async {
    final action = _parser.requireString(args['action'], field: 'عملیات');
    final loanId = _parser.requireString(args['loan_id'], field: 'شناسه وام');
    final loan = await _loans.findById(loanId);
    if (loan == null) {
      throw const NotFoundException('وامی با این شناسه پیدا نشد.');
    }
    if (action == 'delete') {
      return _DraftSpec(
        payload: {
          'recordType': 'loan',
          'action': 'delete',
          'recordId': loan.id,
          'summary': 'حذف وام «${loan.title}» و جدول اقساط',
          'fields': <String, Object?>{'title': loan.title},
        },
        summary: 'حذف وام «${loan.title}» و جدول اقساط',
        userMessage: 'پیش‌نویس حذف وام آماده تأیید است.',
        notes: const [
          'با حذف وام، جدول اقساط و اثر مالی وام از حساب‌ها برداشته می‌شود.',
        ],
      );
    }
    if (action == 'archive') {
      return _DraftSpec(
        payload: {
          'recordType': 'loan',
          'action': 'archive',
          'recordId': loan.id,
          'summary': 'بایگانی وام «${loan.title}»',
          'fields': <String, Object?>{'title': loan.title},
        },
        summary: 'بایگانی وام «${loan.title}»',
        userMessage: 'پیش‌نویس بایگانی وام آماده تأیید است.',
      );
    }
    final title = args.containsKey('title')
        ? _parser.requireString(args['title'], field: 'عنوان وام')
        : loan.title;
    final description = args.containsKey('description')
        ? _optionalString(args['description'])
        : loan.description;
    final status = args.containsKey('status')
        ? LoanStatus.values.firstWhereOrNull(
            (item) => item.name == args['status'],
          )
        : null;
    if (args.containsKey('status') && status == null) {
      throw const ValidationException(
        'وضعیت وام باید active، closed یا archived باشد.',
      );
    }
    return _DraftSpec(
      payload: {
        'recordType': 'loan',
        'action': 'update',
        'recordId': loan.id,
        'summary': 'ویرایش وام «$title»',
        'fields': <String, Object?>{
          'title': title,
          'description': description,
          'status': status?.name,
        },
      },
      summary: 'ویرایش وام «$title»',
      userMessage: 'پیش‌نویس ویرایش وام آماده تأیید است.',
      notes: const ['اصل وام و جدول اقساط با این ابزار تغییر نمی‌کند.'],
    );
  }

  Future<_DraftSpec> _buildManagedAsset(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
    final action = _parser.requireString(args['action'], field: 'عملیات');
    AssetHolding? current;
    if (action != 'create') {
      final assetId = _parser.requireString(
        args['asset_id'],
        field: 'شناسه دارایی',
      );
      current = await _assets.findById(assetId);
      if (current == null) {
        throw const NotFoundException('دارایی‌ای با این شناسه پیدا نشد.');
      }
    }
    if (action == 'delete') {
      final asset = current!;
      return _DraftSpec(
        payload: {
          'recordType': 'asset',
          'action': 'delete',
          'recordId': asset.id,
          'summary': 'حذف دارایی «${asset.name}»',
          'fields': <String, Object?>{
            'name': asset.name,
            'kind': asset.kind.name,
            'quantityMicros': asset.quantity.micros,
          },
        },
        summary: 'حذف دارایی «${asset.name}»',
        userMessage: 'پیش‌نویس حذف دارایی آماده تأیید است.',
      );
    }

    final kind = args.containsKey('kind')
        ? AssetKind.values.firstWhereOrNull((item) => item.name == args['kind'])
        : current?.kind;
    if (kind == null) {
      throw const ValidationException(
        'نوع دارایی باید gold، silver، currency یا crypto باشد.',
      );
    }
    final code = args.containsKey('currency_code')
        ? _optionalString(args['currency_code'])?.toUpperCase()
        : current?.currencyCode;
    if (kind == AssetKind.currency &&
        (code == null || !RegExp(r'^[A-Z]{3}$').hasMatch(code))) {
      throw const ValidationException('کد سه‌حرفی ارز را وارد کنید.');
    }
    if (kind == AssetKind.crypto &&
        (code == null || !RegExp(r'^[A-Z]{3,10}$').hasMatch(code))) {
      throw const ValidationException('نماد رمزارز را وارد کنید.');
    }
    if ((kind == AssetKind.gold || kind == AssetKind.silver) && code != null) {
      throw const ValidationException('برای طلا و نقره کد ارز نگذار.');
    }
    final name = args.containsKey('name')
        ? _parser.requireString(args['name'], field: 'نام دارایی')
        : current?.name;
    if (name == null) {
      throw const ValidationException('نام دارایی مشخص نیست.');
    }
    AssetQuantity? quantity = current?.quantity;
    if (args.containsKey('quantity')) {
      final raw = args['quantity'];
      quantity = AssetQuantity.tryParse('$raw');
      if (quantity == null) {
        throw const ValidationException(
          'مقدار دارایی باید عدد مثبت با حداکثر شش رقم اعشار باشد.',
        );
      }
    }
    if (quantity == null) {
      throw const ValidationException('مقدار دارایی مشخص نیست.');
    }

    var rate = current?.rateRial;
    var rateDate = current?.rateDate;
    var isMarketRate = current?.isMarketRate ?? false;
    if (args['use_market_rate'] == true) {
      final lookup = _marketRates;
      if (lookup == null) {
        throw const ValidationException(
          'دریافت نرخ زنده در این نسخه در دسترس نیست؛ نرخ را دستی بده.',
        );
      }
      final quote = await lookup(kind, code);
      rate = quote.rate;
      rateDate = quote.updatedAt;
      isMarketRate = true;
    } else if (args.containsKey('rate')) {
      rate = _parser.parseMoney(
        args['rate'],
        args['amount_unit'],
        fallbackUnit: defaultCurrency,
        field: 'نرخ دارایی',
      );
      rateDate = args['rate_date'] == null
          ? CalendarDate.today().stored
          : _parser
                .parseDate(args['rate_date'], field: 'تاریخ نرخ')
                .date
                .stored;
      isMarketRate = false;
    } else if (args.containsKey('rate_date')) {
      rateDate = _parser
          .parseDate(args['rate_date'], field: 'تاریخ نرخ')
          .date
          .stored;
    }
    final summary = action == 'create'
        ? 'ثبت دارایی «$name»'
        : 'ویرایش دارایی «$name»';
    return _DraftSpec(
      payload: {
        'recordType': 'asset',
        'action': action,
        'recordId': current?.id,
        'summary': summary,
        'fields': <String, Object?>{
          'name': name,
          'kind': kind.name,
          'currencyCode': code,
          'quantityMicros': quantity.micros,
          'rateRial': rate?.value,
          'rateDate': rateDate?.toUtc().toIso8601String(),
          'isMarketRate': isMarketRate,
        },
      },
      summary: summary,
      userMessage: action == 'create'
          ? 'پیش‌نویس دارایی جدید آماده تأیید است.'
          : 'پیش‌نویس ویرایش دارایی آماده تأیید است.',
    );
  }

  Future<_DraftSpec> _buildManagedObligation(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
    final action = _parser.requireString(args['action'], field: 'عملیات');
    Obligation? current;
    if (action != 'create') {
      final id = _parser.requireString(
        args['obligation_id'],
        field: 'شناسه طلب/بدهی',
      );
      current = await _obligations.findById(id);
      if (current == null) {
        throw const NotFoundException('موردی با این شناسه پیدا نشد.');
      }
    }
    final formatter = MoneyFormatter(unit: defaultCurrency);

    if (action == 'delete') {
      final item = current!;
      final summary =
          'حذف ${item.isReceivable ? 'طلب' : 'بدهی'} از ${item.counterparty}';
      return _DraftSpec(
        payload: {
          'recordType': 'obligation',
          'action': 'delete',
          'recordId': item.id,
          'summary': summary,
          'fields': <String, Object?>{
            'counterparty': item.counterparty,
            'isReceivable': item.isReceivable,
            'amountRial': item.amount.value,
          },
        },
        summary: summary,
        userMessage: 'پیش‌نویس حذف طلب/بدهی آماده تأیید است.',
      );
    }

    if (action == 'add_payment') {
      final item = current!;
      final amount = _parser.parseMoney(
        args['payment_amount'],
        args['amount_unit'],
        fallbackUnit: defaultCurrency,
        field: 'مبلغ پرداخت',
      );
      if (amount > item.remaining) {
        throw ValidationException(
          'مبلغ پرداخت از مانده (${formatter.format(item.remaining)}) بیشتر است.',
        );
      }
      final date = args['payment_date'] == null
          ? CalendarDate.today()
          : _parser.parseDate(args['payment_date'], field: 'تاریخ پرداخت').date;
      final summary =
          'ثبت پرداخت ${formatter.format(amount)} برای '
          '${item.isReceivable ? 'طلب' : 'بدهی'} ${item.counterparty}';
      return _DraftSpec(
        payload: {
          'recordType': 'obligation',
          'action': 'add_payment',
          'recordId': item.id,
          'summary': summary,
          'fields': <String, Object?>{
            'obligationId': item.id,
            'amountRial': amount.value,
            'date': date.toIso(),
          },
        },
        summary: summary,
        userMessage: 'پیش‌نویس ثبت پرداخت آماده تأیید است.',
      );
    }

    final counterparty = args.containsKey('counterparty')
        ? _parser.requireString(args['counterparty'], field: 'طرف حساب')
        : current?.counterparty;
    if (counterparty == null) {
      throw const ValidationException('نام طرف حساب مشخص نیست.');
    }
    final isReceivable = args.containsKey('is_receivable')
        ? args['is_receivable'] == true
        : current?.isReceivable;
    if (isReceivable == null) {
      throw const ValidationException(
        'مشخص کن این مورد طلب است (پول به کاربر بدهکارند) یا بدهی.',
      );
    }
    final amount = args['amount'] == null
        ? current?.amount
        : _parser.parseMoney(
            args['amount'],
            args['amount_unit'],
            fallbackUnit: defaultCurrency,
          );
    if (amount == null) {
      throw const ValidationException('مبلغ طلب/بدهی مشخص نیست.');
    }
    if (current != null && amount < current.paid) {
      throw const ValidationException('مبلغ از مجموع پرداخت‌ها کمتر است.');
    }
    final dueDate = args.containsKey('due_date')
        ? (args['due_date'] == null
              ? null
              : _parser.parseDate(args['due_date'], field: 'تاریخ سررسید').date)
        : current?.dueDate;
    final note = args.containsKey('note')
        ? _optionalString(args['note'])
        : current?.note;
    final summary = action == 'create'
        ? 'ثبت ${isReceivable ? 'طلب' : 'بدهی'} ${formatter.format(amount)} از $counterparty'
        : 'ویرایش ${isReceivable ? 'طلب' : 'بدهی'} $counterparty';
    return _DraftSpec(
      payload: {
        'recordType': 'obligation',
        'action': action,
        'recordId': current?.id,
        'summary': summary,
        'fields': <String, Object?>{
          'counterparty': counterparty,
          'isReceivable': isReceivable,
          'amountRial': amount.value,
          'dueDate': dueDate?.toIso(),
          'note': note,
        },
      },
      summary: summary,
      userMessage: action == 'create'
          ? 'پیش‌نویس طلب/بدهی آماده تأیید است.'
          : 'پیش‌نویس ویرایش طلب/بدهی آماده تأیید است.',
    );
  }

  // ---------------------------------------------------------------------------
  // Pending-draft management
  // ---------------------------------------------------------------------------

  /// Re-validates and edits an open draft instead of creating a new one.
  Future<ToolExecution> _updatePendingDraft(
    ToolCall call,
    String sessionId,
    CurrencyUnit defaultCurrency,
  ) async {
    final actionId = _parser.requireString(
      call.arguments['action_id'],
      field: 'شناسه پیش‌نویس',
    );
    final action = await _chat.findPendingAction(actionId);
    if (action == null || action.sessionId != sessionId) {
      throw const NotFoundException('پیش‌نویس باز با این شناسه پیدا نشد.');
    }
    if (!action.isPending) {
      throw ValidationException(
        'این پیش‌نویس قبلاً ${action.status.labelFa} شده است.',
      );
    }
    final rawChanges = call.arguments['changes'];
    if (rawChanges is! Map || rawChanges.isEmpty) {
      throw const ValidationException('هیچ تغییری برای اعمال فرستاده نشد.');
    }
    final changes = rawChanges.map((key, value) => MapEntry('$key', value));
    final tool = DaramTool.fromName(action.actionType);
    final spec = await _rebuildDraft(
      tool,
      action.payload,
      changes,
      defaultCurrency,
    );
    await _chat.updatePendingAction(
      action.copyWith(payload: spec.payload, clearError: true),
    );
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'ok': true,
        'status': 'updated',
        'action_id': action.id,
        'summary': spec.summary,
        'message': 'پیش‌نویس به‌روزرسانی شد و هنوز چیزی ذخیره نشده است. تغییر را کوتاه به کاربر بگو و برای تأیید نهایی منتظر بمان.',
      }),
      userMessage: 'پیش‌نویس به‌روزرسانی شد.',
    );
  }

  Future<ToolExecution> _cancelPendingDraft(
    ToolCall call,
    String sessionId,
  ) async {
    final actionId = _parser.requireString(
      call.arguments['action_id'],
      field: 'شناسه پیش‌نویس',
    );
    final action = await _chat.findPendingAction(actionId);
    if (action == null || action.sessionId != sessionId) {
      throw const NotFoundException('پیش‌نویس باز با این شناسه پیدا نشد.');
    }
    if (!action.isPending) {
      throw ValidationException(
        'این پیش‌نویس قبلاً ${action.status.labelFa} شده است.',
      );
    }
    await _chat.updatePendingAction(
      action.copyWith(
        status: PendingActionStatus.rejected,
        resolvedAt: DateTime.now().toUtc(),
      ),
    );
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'ok': true,
        'status': 'cancelled',
        'action_id': action.id,
        'message': 'پیش‌نویس لغو شد؛ هیچ رکوردی ذخیره یا حذف نشد.',
      }),
      userMessage: 'پیش‌نویس لغو شد.',
    );
  }

  /// Rebuilds [payload] after applying [changes] using the original tool
  /// validators, so an edited draft can never bypass validation.
  Future<_DraftSpec> _rebuildDraft(
    DaramTool? tool,
    Map<String, Object?> payload,
    Map<String, Object?> changes,
    CurrencyUnit defaultCurrency,
  ) async {
    if (tool == null) {
      throw const ValidationException('این پیش‌نویس قابل ویرایش نیست.');
    }
    switch (tool) {
      case DaramTool.addAccount:
        return _buildAccountDraft(
          _mergeDraftChanges(
            _argsFromAccountPayload(payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.addTransaction:
        return _buildTransactionDraft(
          _mergeDraftChanges(
            _argsFromTransactionPayload(payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.addTransfer:
        return _buildTransferDraft(
          _mergeDraftChanges(
            _argsFromTransferPayload(payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.addLoan:
        return _buildLoanDraft(
          _mergeDraftChanges(
            _argsFromLoanPayload(payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.markInstallmentPaid:
        return _buildInstallmentPaymentDraft(
          _mergeDraftChanges(
            _argsFromInstallmentPayload(payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.manageAccount:
        return _buildManagedAccount(
          _mergeDraftChanges(
            _argsFromManagedPayload(tool, payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.manageTransaction:
        return _buildManagedTransaction(
          _mergeDraftChanges(
            _argsFromManagedPayload(tool, payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.manageTransfer:
        return _buildManagedTransfer(
          _mergeDraftChanges(
            _argsFromManagedPayload(tool, payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.manageLoan:
        return _buildManagedLoan(
          _mergeDraftChanges(
            _argsFromManagedPayload(tool, payload),
            changes,
            defaultCurrency,
          ),
        );
      case DaramTool.manageAsset:
        return _buildManagedAsset(
          _mergeDraftChanges(
            _argsFromManagedPayload(tool, payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
      case DaramTool.manageObligation:
        return _buildManagedObligation(
          _mergeDraftChanges(
            _argsFromManagedPayload(tool, payload),
            changes,
            defaultCurrency,
          ),
          defaultCurrency,
        );
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
          DaramTool.updateSettings:
        throw const ValidationException('این پیش‌نویس قابل ویرایش نیست.');
    }
  }

  /// Keys whose meaning depends on `amount_unit`.
  static const _unitSensitiveKeys = <String>{
    'amount',
    'fee_amount',
    'payment_amount',
    'initial_balance',
    'principal_amount',
    'installment_amount',
    'paid_amount',
    'rate',
  };

  /// Applies model-supplied [changes] over canonical [base] arguments.
  ///
  /// Canonical payloads carry Rial amounts, so the reconstructed arguments say
  /// `amount_unit: rial`. When the user changes only an amount (for example
  /// «مبلغ رو ۳۰۰ هزار کن») the model usually omits the unit; the stale `rial`
  /// marker must be dropped so the amount is interpreted in the user's display
  /// unit instead of being silently divided by ten.
  Map<String, Object?> _mergeDraftChanges(
    Map<String, Object?> base,
    Map<String, Object?> changes,
    CurrencyUnit defaultCurrency,
  ) {
    final merged = Map<String, Object?>.of(base);
    final changesAnAmount = changes.keys.any(_unitSensitiveKeys.contains);
    final explicitUnit = CurrencyUnit.tryParse(changes['amount_unit']);
    CurrencyUnit? targetUnit;
    if (explicitUnit != null) {
      targetUnit = explicitUnit;
    } else if (changesAnAmount) {
      // The model usually omits the unit when only the amount changes; the
      // stale `rial` marker must go so the display unit applies instead.
      merged.remove('amount_unit');
      targetUnit = defaultCurrency;
    }
    if (targetUnit == CurrencyUnit.toman) {
      // Untouched canonical amounts are Rial. Re-read in Toman they would be
      // divided by ten, so convert them first to keep their value unchanged.
      for (final key in _unitSensitiveKeys) {
        if (changes.containsKey(key)) continue;
        final value = merged[key];
        if (value is int) merged[key] = value / 10;
      }
      final interest = merged['interest_information'];
      if (interest is Map) {
        final nested = interest.map((key, value) => MapEntry('$key', value));
        final total = nested['total_interest_amount'];
        if (total is int) {
          nested['total_interest_amount'] = total / 10;
          nested['amount_unit'] = 'toman';
        }
        merged['interest_information'] = nested;
      }
    }
    if (changes.containsKey('type') && !changes.containsKey('category')) {
      merged.remove('category');
    }
    merged.addAll(changes);
    return merged;
  }

  Map<String, Object?> _argsFromAccountPayload(
    Map<String, Object?> payload,
  ) => {
    'bank_name': payload['bankName'],
    'account_name': payload['accountName'],
    'account_type': payload['accountType'],
    'initial_balance': payload['initialBalanceRial'],
    'amount_unit': 'rial',
    if (payload['cardLastFour'] != null)
      'card_last_four_digits': payload['cardLastFour'],
    if (payload['description'] != null) 'description': payload['description'],
  };

  Map<String, Object?> _argsFromTransactionPayload(
    Map<String, Object?> payload,
  ) => {
    'type': payload['type'],
    'amount': payload['amountRial'],
    'amount_unit': 'rial',
    'date': payload['date'],
    'account': payload['accountId'] ?? payload['accountName'],
    if (payload['categoryName'] != null) 'category': payload['categoryName'],
    if (payload['description'] != null) 'description': payload['description'],
  };

  Map<String, Object?> _argsFromTransferPayload(
    Map<String, Object?> payload,
  ) => {
    'source_account': payload['sourceAccountId'],
    'destination_account': payload['destinationAccountId'],
    'amount': payload['amountRial'],
    'amount_unit': 'rial',
    'date': payload['date'],
    if (payload['feeRial'] != null) 'fee_amount': payload['feeRial'],
    if (payload['description'] != null) 'description': payload['description'],
  };

  Map<String, Object?> _argsFromLoanPayload(Map<String, Object?> payload) => {
    'title': payload['title'],
    'principal_amount': payload['principalRial'],
    'amount_unit': 'rial',
    'installment_count': payload['installmentCount'],
    'start_date': payload['startDate'],
    'installment_due_dates': payload['dueDates'],
    if (payload['installmentAmountRial'] != null)
      'installment_amount': payload['installmentAmountRial'],
    if (payload['accountId'] != null) 'account': payload['accountId'],
    if (payload['interestRial'] != null)
      'interest_information': {
        'total_interest_amount': payload['interestRial'],
        'amount_unit': 'rial',
      },
    if (payload['description'] != null) 'description': payload['description'],
  };

  Map<String, Object?> _argsFromInstallmentPayload(
    Map<String, Object?> payload,
  ) => {
    'loan_id': payload['loanId'],
    'installment_id': payload['installmentId'],
    'payment_date': payload['paymentDate'],
    'paid_amount': payload['paidAmountRial'],
    'amount_unit': 'rial',
  };

  /// Reconstructs tool arguments from a `manage_*` draft payload.
  Map<String, Object?> _argsFromManagedPayload(
    DaramTool tool,
    Map<String, Object?> payload,
  ) {
    final fields = payload['fields'] is Map
        ? (payload['fields'] as Map).map(
            (key, value) => MapEntry('$key', value),
          )
        : <String, Object?>{};
    final base = <String, Object?>{
      'action': payload['action'],
      if (payload['recordId'] != null)
        ...switch (tool) {
          DaramTool.manageAccount => {'account_id': payload['recordId']},
          DaramTool.manageTransaction => {
            'transaction_id': payload['recordId'],
          },
          DaramTool.manageTransfer => {'transfer_id': payload['recordId']},
          DaramTool.manageLoan => {'loan_id': payload['recordId']},
          DaramTool.manageAsset => {'asset_id': payload['recordId']},
          DaramTool.manageObligation => {'obligation_id': payload['recordId']},
          _ => const <String, Object?>{},
        },
    };
    switch (tool) {
      case DaramTool.manageAccount:
        return {
          ...base,
          if (fields['accountName'] != null)
            'account_name': fields['accountName'],
          if (fields['bankName'] != null) 'bank_name': fields['bankName'],
          if (fields['accountType'] != null)
            'account_type': fields['accountType'],
          if (fields['cardLastFour'] != null)
            'card_last_four_digits': fields['cardLastFour'],
          if (fields['description'] != null)
            'description': fields['description'],
        };
      case DaramTool.manageTransaction:
        return {
          ...base,
          if (fields['type'] != null) 'type': fields['type'],
          if (fields['amountRial'] != null) ...{
            'amount': fields['amountRial'],
            'amount_unit': 'rial',
          },
          if (fields['date'] != null) 'date': fields['date'],
          if (fields['accountId'] != null) 'account': fields['accountId'],
          if (fields['categoryName'] != null)
            'category': fields['categoryName'],
          if (fields['description'] != null)
            'description': fields['description'],
        };
      case DaramTool.manageTransfer:
        return {
          ...base,
          if (fields['sourceAccountId'] != null)
            'source_account': fields['sourceAccountId'],
          if (fields['destinationAccountId'] != null)
            'destination_account': fields['destinationAccountId'],
          if (fields['amountRial'] != null) ...{
            'amount': fields['amountRial'],
            'amount_unit': 'rial',
          },
          if (fields['feeRial'] != null) ...{
            'fee_amount': fields['feeRial'],
            'amount_unit': 'rial',
          },
          if (fields['date'] != null) 'date': fields['date'],
          if (fields['description'] != null)
            'description': fields['description'],
        };
      case DaramTool.manageLoan:
        return {
          ...base,
          if (fields['title'] != null) 'title': fields['title'],
          if (fields['description'] != null)
            'description': fields['description'],
          if (fields['status'] != null) 'status': fields['status'],
        };
      case DaramTool.manageAsset:
        return {
          ...base,
          if (fields['name'] != null) 'name': fields['name'],
          if (fields['kind'] != null) 'kind': fields['kind'],
          if (fields['currencyCode'] != null)
            'currency_code': fields['currencyCode'],
          if (fields['quantityMicros'] != null)
            'quantity': AssetQuantity.fromMicros(
              fields['quantityMicros'] as int,
            ).decimal,
          if (fields['rateRial'] != null) ...{
            'rate': fields['rateRial'],
            'amount_unit': 'rial',
          },
          if (fields['rateDate'] != null)
            'rate_date': '${fields['rateDate']}'.split('T').first,
        };
      case DaramTool.manageObligation:
        return {
          ...base,
          if (fields['counterparty'] != null)
            'counterparty': fields['counterparty'],
          if (fields['isReceivable'] != null)
            'is_receivable': fields['isReceivable'],
          if (fields['amountRial'] != null) ...{
            'amount': fields['amountRial'],
            'amount_unit': 'rial',
          },
          if (fields['dueDate'] != null) 'due_date': fields['dueDate'],
          if (fields['note'] != null) 'note': fields['note'],
          if (fields['amountRial'] != null &&
              payload['action'] == 'add_payment')
            'payment_amount': fields['amountRial'],
          if (fields['date'] != null && payload['action'] == 'add_payment')
            'payment_date': fields['date'],
        };
      default:
        return base;
    }
  }

  // ---------------------------------------------------------------------------
  // Query tools
  // ---------------------------------------------------------------------------

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
            'id': row.id,
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

  Future<ToolExecution> _queryRecords(
    ToolCall call,
    CurrencyUnit displayCurrency,
  ) async {
    final args = call.arguments;
    final recordType = _parser.requireString(
      args['record_type'],
      field: 'نوع رکورد',
    );
    final limit = args['limit'] is num
        ? _parser.parseInteger(
            args['limit'],
            field: 'تعداد نتایج',
            min: 1,
            max: 100,
          )
        : 50;
    final formatter = MoneyFormatter(unit: displayCurrency);
    final jalali = JalaliText();
    final range = _resolveRange(args['date_range']);

    final content = <String, Object?>{
      'ok': true,
      'record_type': recordType,
      'display_currency': displayCurrency.name,
    };

    switch (recordType) {
      case 'accounts':
        final rows = await _accounts.listWithBalances(includeArchived: true);
        content['items'] = [
          for (final item in rows)
            {
              'id': item.account.id,
              'name': item.account.accountName,
              'bank': item.account.bankName,
              'type': item.account.accountType.name,
              'balance_rial': item.balance.value,
              'balance_display': formatter.format(item.balance),
              'card_last_four': item.account.cardLastFour,
              'archived': item.account.archivedAt != null,
            },
        ];
        content['total_balance_rial'] = Rial.sum(
          rows
              .where((item) => item.account.archivedAt == null)
              .map((item) => item.balance),
        ).value;
      case 'transactions':
        Account? account;
        final accountRef = _optionalString(args['account']);
        if (accountRef != null) account = await _resolveAccount(accountRef);
        Category? category;
        final categoryRef = _optionalString(args['category']);
        if (categoryRef != null) {
          category =
              await _categories.resolve(categoryRef, CategoryType.expense) ??
              await _categories.resolve(categoryRef, CategoryType.income);
        }
        final rows = await _transactions.list(
          TransactionFilter(
            start: range.start.stored,
            end: range.end.stored,
            type: TransactionType.tryParse(args['transaction_type']),
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
        content['range'] = {
          'start': range.start.toIso(),
          'end': range.end.toIso(),
          'label_fa':
              '${jalali.date(range.start)} تا ${jalali.date(range.end)}',
        };
        content['totals'] = {
          'income_rial': income.value,
          'expense_rial': expense.value,
          'net_rial': (income - expense).value,
          'income_display': formatter.format(income),
          'expense_display': formatter.format(expense),
          'net_display': formatter.format(income - expense),
          'count': rows.length,
        };
        content['items'] = [
          for (final row in rows) _transactionJson(row, formatter, jalali),
        ];
      case 'transfers':
        final rows = (await _transfers.list(limit: 200))
            .where(
              (row) =>
                  !row.transferDate.isBefore(range.start.stored) &&
                  !row.transferDate.isAfter(range.end.stored),
            )
            .take(limit)
            .toList();
        content['items'] = [
          for (final row in rows)
            {
              'id': row.id,
              'date': CalendarDate.fromStored(row.transferDate).toIso(),
              'date_label_fa': jalali.date(
                CalendarDate.fromStored(row.transferDate),
              ),
              'from': row.sourceAccountName,
              'to': row.destinationAccountName,
              'amount_rial': row.amountRial.value,
              'amount_display': formatter.format(row.amountRial),
              'fee_rial': row.feeRial.value,
              'fee_display': formatter.format(row.feeRial),
              'description': row.description,
            },
        ];
      case 'loans':
        final status = args['loan_status'] == null
            ? null
            : LoanStatus.values.firstWhereOrNull(
                (item) => item.name == args['loan_status'],
              );
        final rows = (await _loans.list())
            .where((loan) => status == null || loan.status == status)
            .take(limit)
            .toList();
        content['items'] = [
          for (final loan in rows)
            {
              'id': loan.id,
              'title': loan.title,
              'status': loan.status.name,
              'status_label': loan.status.labelFa,
              'principal_rial': loan.principalAmountRial.value,
              'principal_display': formatter.format(loan.principalAmountRial),
              'installment_count': loan.installmentCount,
              'installment_amount_display': formatter.format(
                loan.installmentAmountRial,
              ),
              'paid_installments': loan.paidInstallments,
              'outstanding_rial': loan.outstandingRial.value,
              'outstanding_display': formatter.format(loan.outstandingRial),
              'account': loan.accountName,
              'next_due': loan.nextDueDate == null
                  ? null
                  : CalendarDate.fromStored(loan.nextDueDate!).toIso(),
            },
        ];
        content['total_outstanding_display'] = formatter.format(
          Rial.sum(
            rows
                .where((loan) => loan.status == LoanStatus.active)
                .map((loan) => loan.outstandingRial),
          ),
        );
      case 'installments':
        final loans = await _loans.list();
        final titles = {for (final loan in loans) loan.id: loan.title};
        final items = <Map<String, Object?>>[];
        for (final loan in loans) {
          for (final installment in await _loans.installmentsOf(loan.id)) {
            if (installment.isPaid) continue;
            items.add({
              'id': installment.id,
              'loan_id': loan.id,
              'loan_title': titles[loan.id],
              'number': installment.number,
              'due_date': CalendarDate.fromStored(installment.dueDate).toIso(),
              'due_date_label_fa': jalali.date(
                CalendarDate.fromStored(installment.dueDate),
              ),
              'amount_rial': installment.amountRial.value,
              'amount_display': formatter.format(installment.amountRial),
              'overdue': installment.isOverdue,
            });
          }
        }
        items.sort((a, b) => '${a['due_date']}'.compareTo('${b['due_date']}'));
        content['items'] = items.take(limit).toList();
      case 'assets':
        final rows = await _assets.list();
        content['items'] = [
          for (final asset in rows) _assetJson(asset, formatter),
        ];
        content['total_value_display'] = formatter.format(
          Rial.sum(rows.map((asset) => asset.estimatedValue).whereType<Rial>()),
        );
        content['valued_count'] = rows.where((asset) => asset.hasRate).length;
        content['count'] = rows.length;
      case 'obligations':
        final direction = args['obligation_direction'];
        final rows = (await _obligations.list())
            .where(
              (item) =>
                  direction == null ||
                  (direction == 'receivable' && item.isReceivable) ||
                  (direction == 'payable' && !item.isReceivable),
            )
            .take(limit)
            .toList();
        content['items'] = [
          for (final item in rows) _obligationJson(item, formatter),
        ];
        content['receivable_display'] = formatter.format(
          Rial.sum(
            rows
                .where((item) => item.isReceivable)
                .map((item) => item.remaining),
          ),
        );
        content['payable_display'] = formatter.format(
          Rial.sum(
            rows
                .where((item) => !item.isReceivable)
                .map((item) => item.remaining),
          ),
        );
      case 'categories':
        final rows = await _categories.list();
        content['items'] = [
          for (final item in rows)
            {
              'id': item.id,
              'name': item.name,
              'type': item.type.name,
              'icon': item.icon,
              'color_hex': item.colorHex,
              'is_default': item.isDefault,
            },
        ];
      default:
        throw const ValidationException('نوع رکورد شناخته نشد.');
    }

    content['note'] = 'این داده‌ها مستقیماً از پایگاه داده محلی خوانده شده‌اند. برای ویرایش یا حذف از ابزارهای manage_* و شناسه همین رکوردها استفاده کن.';
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode(content),
      userMessage: 'اطلاعات بررسی شد.',
    );
  }

  // ---------------------------------------------------------------------------
  // Financial overview & roadmap
  // ---------------------------------------------------------------------------

  Future<ToolExecution> _financialOverview(
    ToolCall call,
    CurrencyUnit displayCurrency,
  ) async {
    final args = call.arguments;
    final months = args['months'] is num
        ? _parser.parseInteger(
            args['months'],
            field: 'تعداد ماه',
            min: 1,
            max: 12,
          )
        : 6;
    final includeAssets = args['include_assets'] != false;
    final formatter = MoneyFormatter(unit: displayCurrency);
    final jalali = JalaliText();
    final today = CalendarDate.today();

    final accounts = await _accounts.listWithBalances();
    final balance = Rial.sum(accounts.map((item) => item.balance));
    final assets = await _assets.list();
    final obligations = await _obligations.list();
    final loans = await _loans.list();
    final activeLoans = loans.where((loan) => loan.status == LoanStatus.active);
    final loanOutstanding = Rial.sum(
      activeLoans.map((loan) => loan.outstandingRial),
    );
    final payables = Rial.sum(
      obligations
          .where((item) => !item.isReceivable)
          .map((item) => item.remaining),
    );
    final receivables = Rial.sum(
      obligations
          .where((item) => item.isReceivable)
          .map((item) => item.remaining),
    );

    // Value holdings. A missing rate is filled from the live market when the
    // app provides a lookup; failures fall back to "unvalued".
    final assetJson = <Map<String, Object?>>[];
    var assetsTotal = Rial.zero;
    var unvalued = 0;
    for (final asset in includeAssets ? assets : const <AssetHolding>[]) {
      var rate = asset.rateRial;
      var rateAt = asset.rateDate;
      var source = asset.isMarketRate ? 'نرخ بازار (ذخیره‌شده)' : 'نرخ دستی';
      var live = false;
      if (includeAssets && rate == null) {
        final lookup = _marketRates;
        if (lookup != null) {
          try {
            final quote = await lookup(asset.kind, asset.currencyCode);
            rate = quote.rate;
            rateAt = quote.updatedAt;
            source = quote.source;
            live = true;
          } on Object {
            // A failed lookup must not break the whole overview.
          }
        }
      }
      final value = rate == null ? null : asset.quantity.valueAt(rate);
      if (value != null) assetsTotal = assetsTotal + value;
      if (value == null) unvalued++;
      assetJson.add({
        ..._assetJson(asset, formatter),
        'rate_source': source,
        'rate_at': rateAt?.toUtc().toIso8601String(),
        'live_rate': live,
        if (value != null) ...{
          'value_rial': value.value,
          'value_display': formatter.format(value),
        },
      });
    }

    final netWorth =
        balance + assetsTotal + receivables - loanOutstanding - payables;
    final totalAssets = balance + assetsTotal + receivables;

    final monthly = await _analytics.monthly(months: months, today: today);
    final totalIncome = Rial.sum(monthly.map((point) => point.income));
    final totalExpense = Rial.sum(monthly.map((point) => point.expense));
    final monthsWithData = monthly
        .where((point) => point.income.value > 0 || point.expense.value > 0)
        .length;
    final divisor = monthsWithData == 0 ? months : monthsWithData;
    final avgIncome = Rial(totalIncome.value ~/ divisor);
    final avgExpense = Rial(totalExpense.value ~/ divisor);
    final savingsRate = totalIncome.value == 0
        ? 0.0
        : (totalIncome.value - totalExpense.value) / totalIncome.value;
    final emergencyMonths = avgExpense.value == 0
        ? null
        : balance.value / avgExpense.value;
    final debtRatio = totalAssets.value == 0
        ? (loanOutstanding.value + payables.value == 0 ? 0.0 : 1.0)
        : (loanOutstanding.value + payables.value) / totalAssets.value;

    final currentMonthRange = DateRange(today.startOfJalaliMonth, today);
    final monthSummary = await _analytics.summary(currentMonthRange);
    final breakdown = await _analytics.categoryBreakdown(
      currentMonthRange,
      type: TransactionType.expense,
    );
    final topCategories = breakdown.take(5).toList();
    final upcoming = await _loans.upcoming(limit: 5);

    final roadmap = <Map<String, Object?>>[];
    void addPriority(
      String severity,
      String title,
      String detail,
      String actionHint,
    ) {
      roadmap.add({
        'priority': severity,
        'title': title,
        'detail': detail,
        'action_hint': actionHint,
      });
    }

    if (accounts.isEmpty) {
      addPriority(
        'high',
        'اول حساب اصلی‌ات را ثبت کن',
        'بدون حساب، موجودی و جریان نقدی قابل محاسبه نیست.',
        'add_account',
      );
    }
    if (emergencyMonths != null && emergencyMonths < 1) {
      addPriority(
        'high',
        'صندوق اضطراری بساز',
        'ذخیره نقدی فعلی حدود ${_oneDecimal(emergencyMonths)} ماه هزینه را پوشش می‌دهد؛ هدف حداقل ۳ ماه است.',
        'پس‌انداز ماهانه',
      );
    } else if (emergencyMonths != null && emergencyMonths < 3) {
      addPriority(
        'medium',
        'صندوق اضطراری را کامل کن',
        'پوشش فعلی ${_oneDecimal(emergencyMonths)} ماه است؛ تا ۳ تا ۶ ماه هزینه ادامه بده.',
        'پس‌انداز ماهانه',
      );
    }
    if (savingsRate < 0) {
      addPriority(
        'high',
        'هزینه‌ها از درآمد جلو زده',
        'در ${_fa(divisor)} ماه اخیر به‌طور میانگین ${formatter.format(avgExpense - avgIncome)} بیشتر از درآمد خرج شده است.',
        'generate_report',
      );
    } else if (savingsRate < 0.1) {
      addPriority(
        'medium',
        'نرخ پس‌انداز را بالا ببر',
        'نرخ پس‌انداز حدود ${_fa((savingsRate * 100).round())}٪ است؛ هدف رایج ۱۰٪ تا ۲۰٪ درآمد است.',
        'generate_report',
      );
    }
    if (loanOutstanding.value > 0 || payables.value > 0) {
      addPriority(
        'medium',
        'بدهی‌ها را اولویت‌بندی کن',
        'مجموع بدهی ${formatter.format(loanOutstanding + payables)} است؛ اقساط نزدیک و بدهی گران‌تر را اول تسویه کن.',
        'query_records',
      );
    }
    if (unvalued > 0) {
      addPriority(
        'low',
        'نرخ دارایی‌ها را کامل کن',
        '${_fa(unvalued)} دارایی بدون نرخ است و در ارزش خالص لحاظ نشده.',
        'manage_asset',
      );
    }
    if (topCategories.isNotEmpty && topCategories.first.share > 0.35) {
      addPriority(
        'low',
        'بازبینی بزرگ‌ترین دسته هزینه',
        '«${topCategories.first.name}» حدود ${_fa((topCategories.first.share * 100).round())}٪ هزینه این ماه را ساخته است.',
        'generate_report',
      );
    }
    if (roadmap.isEmpty) {
      addPriority(
        'low',
        'مسیر پایدار است؛ یک هدف پس‌انداز تعریف کن',
        'برای رشد، مبلغ مشخصی از مازاد ماهانه را هدف‌گذاری کن و پیشرفت را ماهانه بسنج.',
        'generate_report',
      );
    }

    // Health score: savings, buffer, debt and data completeness.
    final savingsScore = (savingsRate.clamp(0.0, 0.3) / 0.3) * 35;
    final bufferScore = emergencyMonths == null
        ? 15.0
        : (emergencyMonths.clamp(0.0, 6.0) / 6.0) * 25;
    final debtScore = (1 - debtRatio.clamp(0.0, 1.0)) * 25;
    final dataScore = assets.isEmpty
        ? (accounts.isEmpty ? 0.0 : 10.0)
        : 10.0 * (assets.length - unvalued) / assets.length;
    final healthScore = (savingsScore + bufferScore + debtScore + dataScore)
        .round()
        .clamp(0, 100);
    final healthLabel = healthScore >= 80
        ? 'عالی'
        : healthScore >= 60
        ? 'خوب'
        : healthScore >= 40
        ? 'متوسط'
        : 'نیازمند توجه';

    final overview = <String, Object?>{
      'as_of': today.toIso(),
      'as_of_label_fa': jalali.date(today),
      'net_worth_rial': netWorth.value,
      'net_worth_display': formatter.format(netWorth),
      'cash_rial': balance.value,
      'cash_display': formatter.format(balance),
      'assets_rial': assetsTotal.value,
      'assets_display': formatter.format(assetsTotal),
      'receivables_rial': receivables.value,
      'receivables_display': formatter.format(receivables),
      'loans_outstanding_rial': loanOutstanding.value,
      'loans_outstanding_display': formatter.format(loanOutstanding),
      'payables_rial': payables.value,
      'payables_display': formatter.format(payables),
      'cashflow': {
        'months': months,
        'total_income_rial': totalIncome.value,
        'total_expense_rial': totalExpense.value,
        'total_income_display': formatter.format(totalIncome),
        'total_expense_display': formatter.format(totalExpense),
        'avg_income_display': formatter.format(avgIncome),
        'avg_expense_display': formatter.format(avgExpense),
        'savings_rate_percent': (savingsRate * 100).round(),
        'monthly': [
          for (final point in monthly)
            {
              'label': point.label,
              'income_display': formatter.format(point.income),
              'expense_display': formatter.format(point.expense),
              'income_rial': point.income.value,
              'expense_rial': point.expense.value,
            },
        ],
      },
      'current_month': {
        'income_display': formatter.format(monthSummary.income),
        'expense_display': formatter.format(monthSummary.expense),
        'net_display': formatter.format(monthSummary.net),
        'count': monthSummary.transactionCount,
      },
      'emergency_fund_months': emergencyMonths == null
          ? null
          : _oneDecimal(emergencyMonths),
      'debt_ratio_percent': (debtRatio * 100).round(),
      'health': {
        'score': healthScore,
        'label': healthLabel,
        'savings_rate_percent': (savingsRate * 100).round(),
        'emergency_months': emergencyMonths == null
            ? null
            : _oneDecimal(emergencyMonths),
        'debt_ratio_percent': (debtRatio * 100).round(),
      },
      'accounts': [
        for (final item in accounts)
          {
            'id': item.account.id,
            'name': item.account.accountName,
            'bank': item.account.bankName,
            'balance_display': formatter.format(item.balance),
          },
      ],
      'assets': assetJson,
      'obligations': [
        for (final item in obligations) _obligationJson(item, formatter),
      ],
      'loans': [
        for (final loan in activeLoans)
          {
            'id': loan.id,
            'title': loan.title,
            'outstanding_display': formatter.format(loan.outstandingRial),
            'installment_amount_display': formatter.format(
              loan.installmentAmountRial,
            ),
            'paid_installments': loan.paidInstallments,
            'installment_count': loan.installmentCount,
            'next_due': loan.nextDueDate == null
                ? null
                : CalendarDate.fromStored(loan.nextDueDate!).toIso(),
          },
      ],
      'upcoming_installments': [
        for (final item in upcoming)
          {
            'id': item.id,
            'loan_id': item.loanId,
            'loan_title': item.loanTitle,
            'number': item.number,
            'due_date_label_fa': jalali.date(
              CalendarDate.fromStored(item.dueDate),
            ),
            'amount_display': formatter.format(item.amountRial),
          },
      ],
      'top_expense_categories': [
        for (final item in topCategories)
          {
            'name': item.name,
            'amount_display': formatter.format(item.amount),
            'share_percent': (item.share * 100).round(),
            'color_hex': item.colorHex,
          },
      ],
      'roadmap': roadmap,
    };

    final content = {
      'ok': true,
      'display_currency': displayCurrency.name,
      'overview': overview,
      'note': 'همه اعداد و اولویت‌ها توسط برنامه محاسبه شده‌اند؛ آن‌ها را تغییر نده و دوباره جمع نزن. برای متن پاسخ، مبالغ را از فیلدهای _display نقل کن و برای تاریخ‌ها از label_fa استفاده کن.',
    };

    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode(content),
      report: {'kind': 'financial_overview', ...overview},
      userMessage: 'وضعیت مالی محاسبه شد.',
    );
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  Future<ToolExecution> _updateSettings(ToolCall call) async {
    final args = call.arguments;
    final themeRaw = _optionalString(args['theme_mode']);
    final theme = switch (themeRaw) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      null => null,
      _ => throw const ValidationException(
        'حالت ظاهری باید system، light یا dark باشد.',
      ),
    };
    final unitRaw = _optionalString(args['currency_unit']);
    final unit = unitRaw == null
        ? null
        : (CurrencyUnit.tryParse(unitRaw) ??
              (throw const ValidationException(
                'واحد نمایش باید toman یا rial باشد.',
              )));
    final digits = args['persian_digits'] is bool
        ? args['persian_digits'] as bool
        : null;
    final change = SettingsChange(
      themeMode: theme,
      currencyUnit: unit,
      persianDigits: digits,
    );
    if (change.isEmpty) {
      throw const ValidationException('هیچ تنظیمی برای تغییر فرستاده نشد.');
    }
    return ToolExecution(
      toolCallId: call.id,
      toolName: call.name,
      ok: true,
      content: jsonEncode({
        'ok': true,
        'status': 'completed',
        'changed': change.summaryFa,
        'message': 'تنظیمات اعمال شد. تغییر را کوتاه به کاربر بگو.',
      }),
      userMessage: 'تنظیمات اعمال شد.',
      settingsChange: change,
    );
  }

  // ---------------------------------------------------------------------------
  // Reports
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // SMS suggestions
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Map<String, Object?> _transactionJson(
    TransactionRecord row,
    MoneyFormatter formatter,
    JalaliText jalali,
  ) => {
    'id': row.id,
    'date': CalendarDate.fromStored(row.transactionDate).toIso(),
    'date_label_fa': jalali.date(CalendarDate.fromStored(row.transactionDate)),
    'type': row.type.name,
    'amount_rial': row.amountRial.value,
    'amount_display': formatter.format(row.amountRial),
    'category': row.categoryName ?? 'بدون دسته‌بندی',
    'account': row.accountName,
    'description': row.description,
  };

  Map<String, Object?> _assetJson(
    AssetHolding asset,
    MoneyFormatter formatter,
  ) {
    final value = asset.estimatedValue;
    return {
      'id': asset.id,
      'name': asset.name,
      'kind': asset.kind.name,
      'currency_code': asset.currencyCode,
      'quantity': asset.quantity.decimal,
      'quantity_micros': asset.quantity.micros,
      'rate_rial': asset.rateRial?.value,
      'rate_display': asset.rateRial == null
          ? null
          : formatter.format(asset.rateRial!),
      'rate_date': asset.rateDate?.toUtc().toIso8601String(),
      'is_market_rate': asset.isMarketRate,
      'value_rial': value?.value,
      'value_display': value == null ? null : formatter.format(value),
    };
  }

  Map<String, Object?> _obligationJson(
    Obligation item,
    MoneyFormatter formatter,
  ) => {
    'id': item.id,
    'counterparty': item.counterparty,
    'is_receivable': item.isReceivable,
    'direction': item.isReceivable ? 'receivable' : 'payable',
    'amount_rial': item.amount.value,
    'amount_display': formatter.format(item.amount),
    'paid_rial': item.paid.value,
    'paid_display': formatter.format(item.paid),
    'remaining_rial': item.remaining.value,
    'remaining_display': formatter.format(item.remaining),
    'due_date': item.dueDate?.toIso(),
    'due_date_label_fa': item.dueDate == null
        ? null
        : JalaliText(persianDigits: false).date(item.dueDate!),
    'note': item.note,
  };

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
    _DraftSpec spec,
  ) {
    final actionId = _uuid.v4();
    final operationId = _uuid.v4();
    final payload = spec.notes.isEmpty
        ? spec.payload
        : {...spec.payload, 'notes': spec.notes};
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
        'summary': spec.summary,
        'message': 'پیش‌نویس ساخته شد و در انتظار تأیید صریح کاربر است. هنوز هیچ چیزی ذخیره نشده است.',
      }),
      pendingAction: action,
      userMessage: spec.userMessage,
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

  /// Resolves the transaction targeted by a `manage_transaction` call.
  Future<TransactionRecord> _resolveTransaction(
    Map<String, Object?> args,
  ) async {
    final id = _optionalString(args['transaction_id']);
    if (id != null) {
      final row = await _transactions.findById(id);
      if (row == null) {
        throw const NotFoundException('تراکنشی با این شناسه پیدا نشد.');
      }
      return row;
    }
    final description = _optionalString(args['match_description']);
    final dateRaw = _optionalString(args['match_date']);
    if (description == null && dateRaw == null) {
      throw const ValidationException(
        'برای پیدا کردن تراکنش، شناسه یا توضیح/تاریخ آن را بده.',
      );
    }
    final CalendarDate? date = dateRaw == null
        ? null
        : _parser.parseDate(dateRaw, field: 'تاریخ تراکنش').date;
    final rows = await _transactions.list(
      TransactionFilter(
        start: date?.stored,
        end: date?.stored,
        searchQuery: description,
        limit: 10,
      ),
    );
    if (rows.length == 1) return rows.first;
    if (rows.isEmpty) {
      throw const ValidationException(
        'تراکنشی با این مشخصات پیدا نشد. با query_records فهرست تراکنش‌ها را ببین.',
      );
    }
    throw ValidationException(
      'چند تراکنش با این مشخصات پیدا شد: '
      '${rows.take(5).map((row) => '${row.description ?? row.type.labelFa} (${row.amountRial.value} ریال، ${CalendarDate.fromStored(row.transactionDate).toIso()})').join('، ')}. کدام یکی؟',
    );
  }

  /// Resolves the transfer targeted by a `manage_transfer` call.
  Future<TransferRecord> _resolveTransfer(
    Map<String, Object?> args,
    CurrencyUnit defaultCurrency,
  ) async {
    final id = _optionalString(args['transfer_id']);
    if (id != null) {
      final row = await _transfers.findById(id);
      if (row == null) {
        throw const NotFoundException('انتقالی با این شناسه پیدا نشد.');
      }
      return row;
    }
    final amountRaw = args['match_amount'];
    final dateRaw = _optionalString(args['match_date']);
    if (amountRaw == null && dateRaw == null) {
      throw const ValidationException(
        'برای پیدا کردن انتقال، شناسه یا مبلغ/تاریخ آن را بده.',
      );
    }
    final amount = amountRaw == null
        ? null
        : _parser.parseMoney(
            amountRaw,
            args['match_amount_unit'],
            fallbackUnit: defaultCurrency,
            field: 'مبلغ انتقال',
          );
    final date = dateRaw == null
        ? null
        : _parser.parseDate(dateRaw, field: 'تاریخ انتقال').date;
    final rows = (await _transfers.list(limit: 200)).where((row) {
      if (amount != null && row.amountRial != amount) return false;
      if (date != null && CalendarDate.fromStored(row.transferDate) != date) {
        return false;
      }
      return true;
    }).toList();
    if (rows.length == 1) return rows.first;
    if (rows.isEmpty) {
      throw const ValidationException(
        'انتقالی با این مشخصات پیدا نشد. با query_records فهرست انتقال‌ها را ببین.',
      );
    }
    throw ValidationException(
      'چند انتقال با این مشخصات پیدا شد (${rows.length} مورد). شناسه دقیق را از query_records بردار.',
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

  String _fa(int value) => PersianDigits.toPersian('$value');

  String _oneDecimal(double value) {
    final text = value.toStringAsFixed(1);
    return PersianDigits.toPersian(text);
  }
}
