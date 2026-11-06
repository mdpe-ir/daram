import 'package:shamsi_date/shamsi_date.dart';

import '../formatting/persian_formatting.dart';
import 'calendar_date.dart';

/// Persian month names indexed 1..12.
const List<String> jalaliMonthNames = <String>[
  'فروردین',
  'اردیبهشت',
  'خرداد',
  'تیر',
  'مرداد',
  'شهریور',
  'مهر',
  'آبان',
  'آذر',
  'دی',
  'بهمن',
  'اسفند',
];

/// Persian weekday names indexed by ISO weekday (Monday = 1 … Sunday = 7).
const Map<int, String> persianWeekdays = <int, String>{
  DateTime.monday: 'دوشنبه',
  DateTime.tuesday: 'سه‌شنبه',
  DateTime.wednesday: 'چهارشنبه',
  DateTime.thursday: 'پنجشنبه',
  DateTime.friday: 'جمعه',
  DateTime.saturday: 'شنبه',
  DateTime.sunday: 'یکشنبه',
};

/// Formats dates in Jalali for the Persian interface.
class JalaliText {
  const JalaliText({this.persianDigits = true});

  final bool persianDigits;

  String _digits(String value) =>
      persianDigits ? PersianDigits.toPersian(value) : value;

  /// «۲۳ مرداد ۱۴۰۳»
  String date(CalendarDate date) {
    final j = date.jalali;
    return _digits(
      '${_faNumber(j.day)} ${jalaliMonthNames[j.month - 1]} ${j.year}',
    );
  }

  /// «شنبه، ۲۳ مرداد ۱۴۰۳»
  String dateWithWeekday(CalendarDate date) =>
      '${date.weekdayNameFa}، ${this.date(date)}';

  /// «مرداد ۱۴۰۳»
  String monthYear(CalendarDate date) {
    final j = date.jalali;
    return _digits('${jalaliMonthNames[j.month - 1]} ${j.year}');
  }

  /// «۱۴۰۳/۰۵/۲۳»
  String numeric(CalendarDate date) {
    final j = date.jalali;
    return _digits(
      '${j.year}/${j.month.toString().padLeft(2, '0')}/${j.day.toString().padLeft(2, '0')}',
    );
  }

  /// «۲۳ مرداد»
  String dayMonth(CalendarDate date) {
    final j = date.jalali;
    return _digits('${_faNumber(j.day)} ${jalaliMonthNames[j.month - 1]}');
  }

  /// Relative label such as «امروز»، «دیروز» or a short date.
  String relative(CalendarDate date, {CalendarDate? reference}) {
    final today = reference ?? CalendarDate.today();
    final difference = date.differenceInDays(today);
    return switch (difference) {
      0 => 'امروز',
      1 => 'فردا',
      -1 => 'دیروز',
      -2 => 'پریروز',
      2 => 'پس‌فردا',
      _ when difference < 0 && difference > -7 => _digits(
        '${-difference} روز پیش',
      ),
      _ when difference > 0 && difference < 7 => _digits('$difference روز بعد'),
      _ => this.date(date),
    };
  }

  String _faNumber(int value) => _digits(_group(value));

  String _group(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${value < 0 ? '−' : ''}$buffer';
  }

  /// Converts a `Jalali` object to a `CalendarDate`.
  static CalendarDate fromJalali(Jalali jalali) =>
      CalendarDate.fromJalali(jalali.year, jalali.month, jalali.day);
}
