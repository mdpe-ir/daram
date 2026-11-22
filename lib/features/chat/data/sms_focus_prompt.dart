import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/currency.dart';
import '../../../core/time/jalali_text.dart';
import '../../../data/database/app_database.dart';
import '../../sms/data/sms_review_repository.dart';
import '../domain/sms_chat_focus.dart';

/// Builds the hidden prompt block that tells the model exactly which SMS
/// suggestions the user replied to or selected in the chat.
///
/// The ids come from cards that were already shown to the user, so the normal
/// "was this suggestion presented?" guard in the tool executor still applies.
String buildSmsFocusPrompt({
  required SmsChatFocus focus,
  required List<SmsSuggestionRow> rows,
  required Set<String> accountIds,
  required Set<String> categoryIds,
  required CurrencyUnit currency,
}) {
  if (!focus.hasContent) return '';
  if (rows.isEmpty) {
    return '''
# پیشنهادهای پیامکی انتخاب‌شده در چت

کاربر به یک یا چند پیشنهاد پیامکی در چت پاسخ داده یا آن‌ها را انتخاب کرده است، اما این پیشنهادها دیگر در دسترس نیستند. هیچ ابزاری صدا نزن؛ به کاربر بگو فهرست پیامک‌ها را دوباره باز کند و پیشنهاد تازه بگیرد.
''';
  }

  final formatter = MoneyFormatter(unit: currency, usePersianDigits: false);
  final datetime = JalaliText(persianDigits: false);
  final buffer = StringBuffer()
    ..writeln('# پیشنهادهای پیامکی انتخاب‌شده در چت')
    ..writeln();

  if (focus.hasReply) {
    buffer.writeln(
      'کاربر با «پاسخ» به این پیشنهاد پیامکی در چت نوشته است. پیام بعدی کاربر فقط دربارهٔ همین پیشنهاد است:',
    );
  } else {
    buffer.writeln(
      'کاربر ${rows.length} پیشنهاد پیامکی را در چت انتخاب کرده است. پیام بعدی کاربر فقط دربارهٔ همین موارد است:',
    );
  }
  buffer.writeln();

  for (final row in rows) {
    final draft = SmsReviewRepository.draftOf(row);
    final ready = SmsReviewRepository.isReady(
      row,
      accountIds: accountIds,
      categoryIds: categoryIds,
    );
    buffer.writeln(
      '- suggestion_id: `${row.id}`'
      ' | نوع: ${draft.type.labelFa}'
      ' | مبلغ: ${draft.amountRial.isZero ? 'نامشخص' : formatter.format(draft.amountRial)}'
      ' | حساب: ${draft.accountName.isEmpty ? 'نامشخص' : draft.accountName}'
      ' | دسته‌بندی: ${draft.categoryName ?? 'بدون دسته‌بندی'}'
      ' | تاریخ: ${draft.date.toIso()} (${datetime.date(draft.date)})'
      ' | سرشماره: ${row.sender}'
      ' | توضیح: ${draft.description ?? '—'}'
      ' | وضعیت: ${_statusLabel(row.status)}'
      ' | ویرایش‌شده: ${row.editedAt != null ? 'بله' : 'خیر'}'
      ' | آماده تأیید: ${ready ? 'بله' : 'خیر'}',
    );
  }

  buffer
    ..writeln()
    ..writeln('قواعد:')
    ..writeln(
      '- این شناسه‌ها قطعی‌اند و از کارت‌های نمایش‌داده‌شده گرفته شده‌اند؛ لازم نیست دوباره review_sms_suggestions را صدا بزنی.',
    )
    ..writeln(
      '- برای تأیید هر مورد `confirm_sms_suggestion`، برای ویرایش `edit_sms_suggestion` و برای رد `dismiss_sms_suggestion` را با همان suggestion_id صدا بزن.',
    )
    ..writeln(
      '- اگر کاربر دربارهٔ چند مورد یک تصمیم گرفت، برای هر مورد یک فراخوانی جدا بزن و نتیجه هر کدام را کوتاه بگو.',
    )
    ..writeln(
      '- فقط وقتی تصمیم را اجرا کن که پیام کاربر صریح باشد. «باشه»، سکوت یا جملهٔ مبهم تأیید نیست؛ اگر معلوم نیست کدام مورد یا چه تغییری، بپرس.',
    )
    ..writeln(
      '- موردی که وضعیت ثبت‌شده یا ردشده دارد را دوباره تغییر نده؛ به کاربر بگو قبلاً تعیین تکلیف شده است.',
    )
    ..writeln(
      '- موردی که آماده تأیید نیست را اول با edit_sms_suggestion اصلاح کن یا بگو چه چیزی کم دارد؛ مبلغ یا حساب را حدس نزن.',
    )
    ..writeln(
      '- اگر پیام کاربر فقط سؤال یا توضیح است و تصمیمی نمی‌خواهد، هیچ ابزاری صدا نزن و از همین اطلاعات جواب بده.',
    );

  return buffer.toString();
}

String _statusLabel(String status) => switch (status) {
  'pending' => 'در انتظار تأیید',
  'needsReview' => 'نیازمند بررسی',
  'possibleDuplicate' => 'شاید تکراری',
  'confirmed' => 'ثبت‌شده',
  'dismissed' => 'ردشده',
  _ => status,
};
