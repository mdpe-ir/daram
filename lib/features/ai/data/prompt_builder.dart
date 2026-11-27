import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/category_icons.dart';
import '../../../core/constants/category_styles.dart';
import '../../../core/constants/iranian_banks.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/currency.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/jalali_text.dart';
import '../../accounts/domain/account.dart';
import '../../assets/domain/asset_holding.dart';
import '../../categories/domain/category.dart';
import '../../chat/domain/chat_models.dart';
import '../../chat/domain/drafts.dart';
import '../../loans/domain/loan.dart';
import '../../transactions/domain/transaction_record.dart';
import '../../obligations/domain/obligation.dart';
import '../domain/ai_models.dart';

/// Dynamic values injected into the Persian system prompt.
class PromptContext {
  const PromptContext({
    required this.now,
    required this.currency,
    required this.accounts,
    required this.categories,
    required this.loans,
    this.assets = const <AssetHolding>[],
    this.obligations = const <Obligation>[],
    this.pendingActions = const <PendingAction>[],
    this.recentOperations = const <FinancialOperation>[],
    this.recentTransactions = const <TransactionRecord>[],
    this.replyTo,
    this.tools = const <ToolDefinition>[],
    this.toolMode = AIToolMode.native,
  });

  final DateTime now;
  final CurrencyUnit currency;
  final List<AccountWithBalance> accounts;
  final List<Category> categories;
  final List<Loan> loans;

  /// Valued holdings shown to the model so it can discuss the portfolio.
  final List<AssetHolding> assets;

  /// Informal receivables/payables (money lent to or borrowed from people).
  final List<Obligation> obligations;

  /// Drafts that are still waiting for the user's confirmation.
  final List<PendingAction> pendingActions;

  /// Recently applied operations, for continuity across turns.
  final List<FinancialOperation> recentOperations;

  /// The newest transactions, so the model can reference and edit them by id.
  final List<TransactionRecord> recentTransactions;

  /// The message the user is replying to, when they quoted one.
  final ChatMessage? replyTo;

  /// Bundled tool definitions, so the model knows every tool by name even when
  /// the provider does not support native tool calling.
  final List<ToolDefinition> tools;
  final AIToolMode toolMode;
}

/// Builds the system prompt from the bundled template plus live app context.
///
/// Only the context required for the current request is sent: accounts,
/// categories and loan summaries — never the full financial database.
class PromptBuilder {
  PromptBuilder({required this.template, required this.examples});

  final String template;
  final List<Map<String, Object?>> examples;

  static const List<String> exampleAssets = <String>[
    'assets/ai/examples/amount_parsing.json',
    'assets/ai/examples/jalali_date_parsing.json',
    'assets/ai/examples/transfer_detection.json',
    'assets/ai/examples/loan_parsing.json',
    'assets/ai/examples/ambiguous_input.json',
  ];

  static Future<PromptBuilder> load(AssetBundle bundle) async {
    final template = await bundle.loadString('assets/ai/system_prompt_fa.md');
    final examples = <Map<String, Object?>>[];
    for (final path in exampleAssets) {
      final decoded = jsonDecode(await bundle.loadString(path));
      if (decoded is Map && decoded['examples'] is List) {
        for (final example in decoded['examples'] as List) {
          if (example is Map) {
            examples.add(example.map((key, value) => MapEntry('$key', value)));
          }
        }
      }
    }
    return PromptBuilder(template: template, examples: examples);
  }

  String build(PromptContext context) {
    final now = context.now.toLocal();
    final today = CalendarDate.fromDateTime(now);
    final jalali = today.jalali;
    final formatter = NumberFormat('00');
    final time =
        '${formatter.format(now.hour)}:${formatter.format(now.minute)}';
    final timezone = _timezoneName(now);
    final money = MoneyFormatter(
      unit: context.currency,
      usePersianDigits: false,
    );

    final accounts = context.accounts.isEmpty
        ? '  (هنوز حسابی ثبت نشده است؛ برای ثبت هر تراکنش ابتدا حساب بساز.)'
        : context.accounts
              .map(
                (item) =>
                    '  - ${item.account.accountName} | ${item.account.bankName} | شناسه: ${item.account.id} | موجودی: ${money.format(item.balance)} | آخرین چهار رقم کارت: ${item.account.cardLastFour ?? '—'}',
              )
              .join('\n');

    final categories = context.categories.isEmpty
        ? '  (دسته‌بندی پیش‌فرض موجود نیست.)'
        : [
            '  هزینه‌ها: ${context.categories.where((c) => c.type.name == 'expense').map((c) => c.name).join('، ')}',
            '  درآمدها: ${context.categories.where((c) => c.type.name == 'income').map((c) => c.name).join('، ')}',
          ].join('\n');

    final loans = context.loans.isEmpty
        ? '  (وام فعالی وجود ندارد.)'
        : context.loans
              .map(
                (loan) =>
                    '  - ${loan.title} | شناسه: ${loan.id} | اصل: ${money.format(loan.principalAmountRial)} | اقساط: ${loan.paidInstallments}/${loan.installmentCount} | بدهی باقی‌مانده: ${money.format(loan.outstandingRial)} | سررسید بعدی: ${loan.nextDueDate == null ? '—' : JalaliText(persianDigits: false).date(CalendarDate.fromStored(loan.nextDueDate!))}',
              )
              .join('\n');

    final toolModeInstructions = context.toolMode == AIToolMode.native
        ? 'ابزارها از طریق function calling در دسترس هستند. فقط برای اعمال مالی واقعی از آن‌ها استفاده کن. '
              'اگر اطلاعات لازم کامل نیست، ابزار را صدا نزن و سؤال کن.'
        : 'تو به function calling دسترسی نداری. برای هر پاسخ، فقط و فقط یک شیء JSON معتبر برگردان با این ساختار: '
              '{"message": "متن پاسخ فارسی برای کاربر", "actions": [{"tool": "add_transaction", "arguments": {...}}]}. '
              'نام ابزار را فقط از فهرست «ابزارهای در دسترس» بردار و آرگومان‌ها را دقیقاً با همان ابزار پر کن. '
              'اگر عملیات مالی لازم نیست، آرایه actions خالی باشد. هیچ متن، توضیح یا ``` پیش از JSON نگذار.';

    final toolsText = context.tools.isEmpty
        ? '  (فهرست ابزارها در دسترس نیست.)'
        : context.tools.map(_formatTool).join('\n');

    final examplesText = examples.isEmpty
        ? '  (نمونه‌ای بارگذاری نشده است.)'
        : examples.map(_formatExample).join('\n');

    final assetsText = context.assets.isEmpty
        ? '  (دارایی ثبت نشده است.)'
        : context.assets
              .map((asset) {
                final rate = asset.rateRial;
                final value = asset.estimatedValue;
                return '  - ${asset.name} | ${asset.kind.label} | مقدار: ${asset.quantity.decimal} ${asset.unitLabel} '
                    '| نرخ: ${rate == null ? 'بدون نرخ' : money.format(rate)} '
                    '| ارزش تخمینی: ${value == null ? '—' : money.format(value)} '
                    '| شناسه: ${asset.id}';
              })
              .join('\n');

    final obligationsText = context.obligations.isEmpty
        ? '  (طلب یا بدهی ثبت نشده است.)'
        : context.obligations
              .map((item) {
                return '  - ${item.counterparty} | ${item.isReceivable ? 'طلب' : 'بدهی'} '
                    '| مبلغ: ${money.format(item.amount)} | مانده: ${money.format(item.remaining)} '
                    '| سررسید: ${item.dueDate == null ? '—' : JalaliText(persianDigits: false).date(item.dueDate!)} '
                    '| شناسه: ${item.id}';
              })
              .join('\n');

    final pendingText = context.pendingActions.isEmpty
        ? '  (پیش‌نویس بازی وجود ندارد.)'
        : context.pendingActions
              .map((action) {
                final draft = FinancialDraft.fromPendingAction(action);
                final title =
                    draft?.title ??
                    (action.payload['summary'] ?? 'پیش‌نویس مالی');
                return '  - شناسه: ${action.id} | ابزار: ${action.actionType} '
                    '| عنوان: $title | وضعیت: در انتظار تأیید '
                    '| جزئیات: ${jsonEncode(action.payload)}';
              })
              .join('\n');

    final operationsText = context.recentOperations.isEmpty
        ? '  (عملیات اخیری ثبت نشده است.)'
        : context.recentOperations
              .map((operation) {
                return '  - ${operation.summary} | نوع: ${operation.kind.labelFa} '
                    '| وضعیت: ${operation.status} '
                    '| زمان: ${JalaliText(persianDigits: false).date(CalendarDate.fromDateTime(operation.createdAt.toLocal()))}';
              })
              .join('\n');

    final recentTransactionsText = context.recentTransactions.isEmpty
        ? '  (تراکنشی ثبت نشده است.)'
        : context.recentTransactions
              .map((row) {
                final date = CalendarDate.fromStored(row.transactionDate);
                return '  - شناسه: ${row.id} | ${row.type.labelFa} | ${money.format(row.amountRial)} '
                    '| دسته: ${row.categoryName ?? 'بدون دسته'} | حساب: ${row.accountName ?? '—'} '
                    '| تاریخ: ${JalaliText(persianDigits: false).date(date)} '
                    '| توضیح: ${row.description ?? '—'}';
              })
              .join('\n');

    final reply = context.replyTo;
    final replyText = reply == null
        ? '  (کاربر به پیام مشخصی پاسخ نداده است.)'
        : '  کاربر به این پیام ${reply.isUser ? 'خودش' : 'دستیار'} پاسخ داده است:\n'
              '  «${_truncate(reply.content, 700)}»';

    final todayText = today.toIso();

    final values = <String, String>{
      '{{current_datetime}}':
          '${now.year}-${formatter.format(now.month)}-${formatter.format(now.day)} $time',
      '{{current_gregorian_date}}':
          '${now.year}-${formatter.format(now.month)}-${formatter.format(now.day)}',
      '{{current_jalali_date}}':
          '${jalali.year}/${formatter.format(jalali.month)}/${formatter.format(jalali.day)}',
      '{{current_weekday}}': today.weekdayNameFa,
      '{{current_time}}': time,
      '{{timezone}}': timezone,
      '{{display_currency}}': context.currency == CurrencyUnit.toman
          ? 'تومان'
          : 'ریال',
      '{{accounts}}': accounts,
      '{{categories}}': categories,
      '{{loans}}': loans,
      '{{tool_mode_instructions}}': toolModeInstructions,
      '{{tools}}': toolsText,
      '{{category_icons}}': categoryIconSlugs.join('، '),
      '{{category_colors}}': categoryColorPalette
          .map((option) => '${option.nameFa} (${option.hex})')
          .join('، '),
      '{{examples}}': examplesText,
      '{{assets}}': assetsText,
      '{{obligations}}': obligationsText,
      '{{pending_drafts}}': pendingText,
      '{{recent_operations}}': operationsText,
      '{{recent_transactions}}': recentTransactionsText,
      '{{reply_context}}': replyText,
      '{{today}}': todayText,
    };

    var prompt = template;
    for (final entry in values.entries) {
      prompt = prompt.replaceAll(entry.key, entry.value);
    }
    return prompt;
  }

  String _truncate(String value, int max) {
    final trimmed = value.trim();
    return trimmed.length <= max ? trimmed : '${trimmed.substring(0, max)}…';
  }

  String _formatTool(ToolDefinition tool) {
    final parameters = tool.parameters['properties'];
    if (parameters is! Map) return '  - ${tool.name}: ${tool.description}';
    final fields = parameters.keys.map((key) => '$key').join('، ');
    return '  - ${tool.name}: ${tool.description}\n    آرگومان‌ها: $fields';
  }

  String _formatExample(Map<String, Object?> example) {
    final user = example['user'];
    final assistant = example['assistant'];
    final calls = example['tool_calls'];
    final buffer = StringBuffer(
      '  - کاربر: ${user ?? ''}\n    دارام: ${assistant ?? ''}',
    );
    if (calls is List && calls.isNotEmpty) {
      buffer.write('\n    ابزارها:');
      for (final call in calls) {
        if (call is Map) {
          buffer.write(' ${call['name']}(${jsonEncode(call['arguments'])});');
        }
      }
    } else {
      buffer.write('\n    ابزارها: بدون فراخوانی');
    }
    return buffer.toString();
  }

  String _timezoneName(DateTime now) {
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final names = {'Iran': 'Asia/Tehran', 'Asia/Tehran': 'Asia/Tehran'};
    return '${names[now.timeZoneName] ?? now.timeZoneName} (UTC$sign$hours:$minutes)';
  }

  /// Human-readable bank list used in validation errors.
  static String bankHint() =>
      iranianBanks.take(12).map((bank) => bank.nameFa).join('، ');
}
