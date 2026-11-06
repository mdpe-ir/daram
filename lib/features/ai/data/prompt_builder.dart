import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/iranian_banks.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/currency.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/jalali_text.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../loans/domain/loan.dart';
import '../domain/ai_models.dart';

/// Dynamic values injected into the Persian system prompt.
class PromptContext {
  const PromptContext({
    required this.now,
    required this.currency,
    required this.accounts,
    required this.categories,
    required this.loans,
    this.toolMode = AIToolMode.native,
  });

  final DateTime now;
  final CurrencyUnit currency;
  final List<AccountWithBalance> accounts;
  final List<Category> categories;
  final List<Loan> loans;
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
              'اگر عملیات مالی لازم نیست، آرایه actions خالی باشد. هیچ متن، توضیح یا ``` پیش از JSON نگذار.';

    final examplesText = examples.isEmpty
        ? '  (نمونه‌ای بارگذاری نشده است.)'
        : examples.map(_formatExample).join('\n');

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
      '{{examples}}': examplesText,
    };

    var prompt = template;
    for (final entry in values.entries) {
      prompt = prompt.replaceAll(entry.key, entry.value);
    }
    return prompt;
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
