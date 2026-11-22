import 'dart:convert';

import 'package:daram/core/money/currency.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/chat/data/sms_focus_prompt.dart';
import 'package:daram/features/chat/domain/sms_chat_focus.dart';
import 'package:flutter_test/flutter_test.dart';

SmsSuggestionRow _row({
  required String id,
  String description = 'پارکینگ',
  int amountRial = 2000000,
  String status = 'pending',
}) => SmsSuggestionRow(
  id: id,
  sender: '1001',
  receivedAt: DateTime.utc(2026, 11, 6, 10),
  template: 'برداشت: [n0] ریال',
  payload: jsonEncode({
    'type': 'expense',
    'amountRial': amountRial,
    'accountId': 'acc-1',
    'accountName': 'حساب ملت',
    'categoryId': 'cat_food',
    'categoryName': 'خوراک و رستوران',
    'date': '2026-11-06',
    'description': description,
  }),
  status: status,
);

void main() {
  test('reply focus pins the exact suggestion and action rules', () {
    final prompt = buildSmsFocusPrompt(
      focus: const SmsChatFocus(replyToId: 'sms-1'),
      rows: [_row(id: 'sms-1')],
      accountIds: {'acc-1'},
      categoryIds: {'cat_food'},
      currency: CurrencyUnit.toman,
    );

    expect(prompt, contains('پاسخ'));
    expect(prompt, contains('sms-1'));
    expect(prompt, contains('200,000 تومان'));
    expect(prompt, contains('2026-11-06'));
    expect(prompt, contains('15 آبان 1405'));
    expect(prompt, contains('آماده تأیید: بله'));
    expect(prompt, contains('confirm_sms_suggestion'));
    expect(prompt, contains('edit_sms_suggestion'));
    expect(prompt, contains('dismiss_sms_suggestion'));
    expect(prompt, contains('review_sms_suggestions'));
  });

  test('group focus lists every selected suggestion and its status', () {
    final prompt = buildSmsFocusPrompt(
      focus: const SmsChatFocus(selectedIds: {'sms-1', 'sms-2'}),
      rows: [
        _row(id: 'sms-1'),
        _row(
          id: 'sms-2',
          description: 'تاکسی',
          amountRial: 0,
          status: 'needsReview',
        ),
      ],
      accountIds: {'acc-1'},
      categoryIds: {'cat_food'},
      currency: CurrencyUnit.toman,
    );

    expect(prompt, contains('2 پیشنهاد پیامکی'));
    expect(prompt, contains('sms-1'));
    expect(prompt, contains('sms-2'));
    expect(prompt, contains('مبلغ: نامشخص'));
    expect(prompt, contains('نیازمند بررسی'));
    expect(prompt, contains('آماده تأیید: خیر'));
    expect(prompt, contains('برای هر مورد یک فراخوانی جدا'));
  });

  test('no focus means no hidden prompt block', () {
    expect(
      buildSmsFocusPrompt(
        focus: const SmsChatFocus(),
        rows: [_row(id: 'sms-1')],
        accountIds: const {'acc-1'},
        categoryIds: const {'cat_food'},
        currency: CurrencyUnit.toman,
      ),
      isEmpty,
    );
  });

  test('unavailable rows tell the model not to invent an action', () {
    final prompt = buildSmsFocusPrompt(
      focus: const SmsChatFocus(replyToId: 'sms-missing'),
      rows: const [],
      accountIds: const {},
      categoryIds: const {},
      currency: CurrencyUnit.toman,
    );
    expect(prompt, contains('دیگر در دسترس نیستند'));
    expect(prompt, contains('هیچ ابزاری صدا نزن'));
  });
}
