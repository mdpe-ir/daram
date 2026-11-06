import 'package:meta/meta.dart';
import 'package:shamsi_date/shamsi_date.dart';

import '../formatting/persian_formatting.dart';
import 'calendar_date.dart';

/// Result of resolving a Persian date expression deterministically.
@immutable
final class ParsedDate {
  const ParsedDate({
    required this.date,
    this.ambiguous = false,
    this.note,
    this.matched = '',
  });

  const ParsedDate.failed(this.note)
    : date = null,
      ambiguous = true,
      matched = '';

  final CalendarDate? date;

  /// True when the expression could reasonably mean more than one date
  /// (for example a missing year). The UI/AI then asks a clarifying question.
  final bool ambiguous;

  final String? note;
  final String matched;

  bool get isSuccess => date != null;
}

/// Deterministic Persian relative-date parser.
///
/// The LLM is never trusted to normalise dates by itself: every date that
/// originates from natural language passes through this parser (with the
/// current date injected). When a year is missing the result is marked as
/// ambiguous instead of guessing silently.
class PersianDateParser {
  const PersianDateParser({this.reference});

  /// Reference date used instead of `today` (useful for deterministic tests).
  final CalendarDate? reference;

  CalendarDate get _today => reference ?? CalendarDate.today();

  static const Map<String, int> _monthIndex = <String, int>{
    'فروردین': 1,
    'اردیبهشت': 2,
    'خرداد': 3,
    'تیر': 4,
    'مرداد': 5,
    'شهریور': 6,
    'مهر': 7,
    'آبان': 8,
    'آذر': 9,
    'دی': 10,
    'بهمن': 11,
    'اسفند': 12,
  };

  static const Map<String, int> _ordinals = <String, int>{
    'اول': 1,
    'یکم': 1,
    'دوم': 2,
    'سوم': 3,
    'چهارم': 4,
    'پنجم': 5,
    'ششم': 6,
    'هفتم': 7,
    'هشتم': 8,
    'نهم': 9,
    'دهم': 10,
    'یازدهم': 11,
    'دوازدهم': 12,
    'سیزدهم': 13,
    'چهاردهم': 14,
    'پانزدهم': 15,
    'شانزدهم': 16,
    'هفدهم': 17,
    'هجدهم': 18,
    'نوزدهم': 19,
    'بیستم': 20,
    'بیست و یکم': 21,
    'بیست و دوم': 22,
    'بیست و سوم': 23,
    'بیست و چهارم': 24,
    'بیست و پنجم': 25,
    'بیست و ششم': 26,
    'بیست و هفتم': 27,
    'بیست و هشتم': 28,
    'بیست و نهم': 29,
    'سی‌ام': 30,
    'سی ام': 30,
  };

  /// Parses [input] into a concrete calendar date.
  ParsedDate parse(String input) {
    final text = _normalize(input);
    if (text.isEmpty) return const ParsedDate.failed('تاریخ خالی است.');

    final keyword = _keyword(text);
    if (keyword != null) return keyword;

    // Numeric Jalali date: 1403/05/23, 1403-5-23, ۱۴۰۳.۵.۲۳
    final numeric = RegExp(r'^(\d{4})[\/\-.](\d{1,2})[\/\-.](\d{1,2})$')
        .firstMatch(text);
    if (numeric != null) {
      final year = int.parse(numeric.group(1)!);
      final month = int.parse(numeric.group(2)!);
      final day = int.parse(numeric.group(3)!);
      if (year >= 1200 && year <= 1599) {
        return _fromJalali(year, month, day, matched: input);
      }
      return _fromGregorian(year, month, day, matched: input);
    }

    // «پنجم دی» / «۲۳ مرداد» / «بیست و سوم مرداد ۱۴۰۳»
    final monthNameMatch = _findMonthName(text);
    if (monthNameMatch != null) {
      final before = text.substring(0, monthNameMatch.start).trim();
      final after = text.substring(monthNameMatch.end).trim();
      final day = _parseDay(before);
      if (day == null) {
        return ParsedDate.failed('روز ماه در «$input» مشخص نیست.');
      }

      int? year;
      if (after.isNotEmpty) {
        final yearMatch = RegExp(r'(\d{4})').firstMatch(after);
        if (yearMatch != null) year = int.parse(yearMatch.group(1)!);
      }

      final currentJalali = _today.jalali;
      if (year != null) {
        return _fromJalali(year, monthNameMatch.month, day, matched: input);
      }
      // No year given: prefer the most recent occurrence in the past year.
      var candidateYear = currentJalali.year;
      var candidate = CalendarDate.fromJalali(
        candidateYear,
        monthNameMatch.month,
        day,
      );
      if (candidate > _today) {
        candidateYear -= 1;
        candidate = CalendarDate.fromJalali(
          candidateYear,
          monthNameMatch.month,
          day,
        );
      }
      return ParsedDate(
        date: candidate,
        ambiguous: true,
        note: 'سال ذکر نشده است؛ نزدیک‌ترین تاریخ در گذشته فرض شد.',
        matched: input,
      );
    }

    return ParsedDate.failed('تاریخ «$input» قابل تشخیص نیست.');
  }

  /// Parses a Persian date range such as
  /// «از اول مرداد تا اول شهریور».
  ({ParsedDate start, ParsedDate end})? parseRange(String input) {
    final text = _normalize(input)
        .replaceAll(RegExp(r'^(گزارش|هزینه‌?های?|درآمدهای?)\s*'), '')
        .replaceAll('از', '')
        .replaceAll('تا', '|')
        .replaceAll('لغایت', '|');
    final parts = text.split('|');
    if (parts.length != 2) return null;
    return (start: parse(parts[0]), end: parse(parts[1]));
  }

  ParsedDate? _keyword(String text) {
    final today = _today;
    switch (text) {
      case 'امروز':
        return ParsedDate(date: today, matched: text);
      case 'دیروز':
        return ParsedDate(date: today.addDays(-1), matched: text);
      case 'پریروز':
        return ParsedDate(date: today.addDays(-2), matched: text);
      case 'فردا':
        return ParsedDate(date: today.addDays(1), matched: text);
      case 'پس فردا':
      case 'پس‌فردا':
        return ParsedDate(date: today.addDays(2), matched: text);
      case 'اول ماه':
      case 'اول این ماه':
        return ParsedDate(date: today.startOfJalaliMonth, matched: text);
      case 'آخر ماه':
      case 'آخر این ماه':
        return ParsedDate(date: today.endOfJalaliMonth, matched: text);
      case 'اول ماه گذشته':
      case 'اول ماه قبل':
      case 'اول ماه پیش':
        final previous = _shiftMonths(today, -1);
        return ParsedDate(date: previous.startOfJalaliMonth, matched: text);
      case 'آخر ماه گذشته':
      case 'آخر ماه قبل':
      case 'آخر ماه پیش':
        return ParsedDate(
          date: _shiftMonths(today, -1).endOfJalaliMonth,
          matched: text,
        );
      case 'اول سال':
        return ParsedDate(date: today.startOfJalaliYear, matched: text);
    }

    final weekMatch = RegExp(
      r'^(هفته|هفتهٔ|هفته ی)\s*(پیش|قبل|گذشته|بعد|آینده)$',
    ).firstMatch(text);
    if (weekMatch != null) {
      final forward = <String>{'بعد', 'آینده'}.contains(weekMatch.group(2));
      return ParsedDate(
        date: today.addDays(forward ? 7 : -7),
        ambiguous: true,
        note: 'روز دقیق هفته مشخص نشده است.',
        matched: text,
      );
    }

    final monthMatch = RegExp(r'^ماه\s*(پیش|قبل|گذشته|بعد|آینده)$')
        .firstMatch(text);
    if (monthMatch != null) {
      final forward = <String>{'بعد', 'آینده'}.contains(monthMatch.group(1));
      final shifted = _shiftMonths(today, forward ? 1 : -1);
      return ParsedDate(
        date: shifted,
        ambiguous: true,
        note: 'روز دقیق ماه مشخص نشده است.',
        matched: text,
      );
    }

    final yearMatch = RegExp(r'^(سال|پارسال)\s*(پیش|قبل|گذشته)?$')
        .firstMatch(text);
    if (yearMatch != null) {
      return ParsedDate(
        date: _shiftYears(today, -1),
        ambiguous: true,
        note: 'روز و ماه مشخص نشده است.',
        matched: text,
      );
    }

    return null;
  }

  ({int start, int end, int month})? _findMonthName(String text) {
    for (final entry in _monthIndex.entries) {
      final index = text.indexOf(entry.key);
      if (index != -1) {
        return (
          start: index,
          end: index + entry.key.length,
          month: entry.value,
        );
      }
    }
    return null;
  }

  int? _parseDay(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final numeric = RegExp(r'^(\d{1,2})$').firstMatch(trimmed);
    if (numeric != null) {
      final day = int.parse(numeric.group(1)!);
      return day >= 1 && day <= 31 ? day : null;
    }
    return _ordinals[trimmed] ?? _wordToNumber(trimmed);
  }

  int? _wordToNumber(String value) {
    const ones = <String, int>{
      'یک': 1,
      'دو': 2,
      'سه': 3,
      'چهار': 4,
      'پنج': 5,
      'شش': 6,
      'هفت': 7,
      'هشت': 8,
      'نه': 9,
      'ده': 10,
      'یازده': 11,
      'دوازده': 12,
      'سیزده': 13,
      'چهارده': 14,
      'پانزده': 15,
      'شانزده': 16,
      'هفده': 17,
      'هجده': 18,
      'نوزده': 19,
      'بیست': 20,
      'سی': 30,
      'چهل': 40,
      'پنجاه': 50,
      'شصت': 60,
      'هفتاد': 70,
      'هشتاد': 80,
      'نود': 90,
    };
    final parts = value.split(RegExp(r'\s+و\s+|\s+'));
    var total = 0;
    var matched = false;
    for (final part in parts) {
      if (part.isEmpty) continue;
      final number = ones[part];
      if (number != null) {
        total += number;
        matched = true;
      }
    }
    return matched ? total : null;
  }

  ParsedDate _fromJalali(
    int year,
    int month,
    int day, {
    required String matched,
  }) {
    try {
      final jalali = Jalali(year, month, day);
      return ParsedDate(
        date: CalendarDate.fromJalali(jalali.year, jalali.month, jalali.day),
        matched: matched,
      );
    } on Object {
      return ParsedDate.failed('تاریخ شمسی $year/$month/$day معتبر نیست.');
    }
  }

  ParsedDate _fromGregorian(
    int year,
    int month,
    int day, {
    required String matched,
  }) {
    if (!CalendarDate.isValid(year, month, day)) {
      return ParsedDate.failed('تاریخ $year/$month/$day معتبر نیست.');
    }
    return ParsedDate(date: CalendarDate(year, month, day), matched: matched);
  }

  CalendarDate _shiftMonths(CalendarDate date, int months) {
    final j = date.jalali;
    var newYear = j.year;
    var newMonth = j.month + months;
    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear -= 1;
    }
    final maxDay = CalendarDate.fromJalali(
      newYear,
      newMonth,
      1,
    ).endOfJalaliMonth.jalali.day;
    final day = j.day > maxDay ? maxDay : j.day;
    return CalendarDate.fromJalali(newYear, newMonth, day);
  }

  CalendarDate _shiftYears(CalendarDate date, int years) {
    final j = date.jalali;
    final targetYear = j.year + years;
    var day = j.day;
    final maxDay = CalendarDate.fromJalali(
      targetYear,
      j.month,
      1,
    ).endOfJalaliMonth.jalali.day;
    if (day > maxDay) day = maxDay;
    return CalendarDate.fromJalali(targetYear, j.month, day);
  }

  String _normalize(String input) {
    var text = PersianDigits.toLatin(input)
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('\u200c', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    text = text.replaceAll('.', '/');
    text = text.replaceAll('،', ' ').trim();
    return text;
  }
}
