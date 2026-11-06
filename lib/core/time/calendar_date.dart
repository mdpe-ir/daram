import 'package:meta/meta.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'jalali_text.dart';

/// A timezone-safe calendar date (no time component).
///
/// Persisted as UTC midnight so that day boundaries cannot shift because of the
/// device timezone. All presentation goes through [jalali].
@immutable
final class CalendarDate implements Comparable<CalendarDate> {
  const CalendarDate(this.year, this.month, this.day);

  /// Builds a date from the local calendar components of [dateTime].
  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  /// Builds a date from a stored UTC-midnight value.
  factory CalendarDate.fromStored(DateTime stored) {
    final utc = stored.toUtc();
    return CalendarDate(utc.year, utc.month, utc.day);
  }

  /// Builds a date from a Jalali (Shamsi) date.
  factory CalendarDate.fromJalali(int year, int month, int day) {
    final gregorian = Jalali(year, month, day).toGregorian();
    return CalendarDate(gregorian.year, gregorian.month, gregorian.day);
  }

  /// Parses an ISO `yyyy-mm-dd` string.
  factory CalendarDate.parseIso(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) {
      throw FormatException('تاریخ نامعتبر است: $value');
    }
    return CalendarDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  /// The current local date.
  factory CalendarDate.today() => CalendarDate.fromDateTime(DateTime.now());

  final int year;
  final int month;
  final int day;

  /// The corresponding Jalali date.
  Jalali get jalali => Gregorian(year, month, day).toJalali();

  /// Day of week, Monday = 1 … Sunday = 7 (Gregorian ISO weekday).
  int get isoWeekday => DateTime.utc(year, month, day).weekday;

  /// Persian weekday name (شنبه … جمعه).
  String get weekdayNameFa => persianWeekdays[isoWeekday] ?? '';

  /// The stored representation: UTC midnight.
  DateTime get stored => DateTime.utc(year, month, day);

  /// Whether the date is valid in the Gregorian calendar.
  static bool isValid(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return false;
    final date = DateTime.utc(year, month, day);
    return date.year == year && date.month == month && date.day == day;
  }

  /// ISO `yyyy-mm-dd`.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Adds a number of days.
  CalendarDate addDays(int days) {
    final shifted = DateTime.utc(year, month, day).add(Duration(days: days));
    return CalendarDate(shifted.year, shifted.month, shifted.day);
  }

  /// Difference in whole days (`this - other`).
  int differenceInDays(CalendarDate other) => DateTime.utc(
    year,
    month,
    day,
  ).difference(DateTime.utc(other.year, other.month, other.day)).inDays;

  /// Shifts the date by [months] in the Jalali calendar, clamping the day to
  /// the length of the target month.
  CalendarDate addJalaliMonths(int months) {
    final j = jalali;
    var year = j.year;
    var month = j.month + months;
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    final firstOfMonth = CalendarDate.fromJalali(year, month, 1);
    final maxDay = firstOfMonth.endOfJalaliMonth.jalali.day;
    return CalendarDate.fromJalali(
      year,
      month,
      j.day > maxDay ? maxDay : j.day,
    );
  }

  /// First day of the Jalali month containing this date.
  CalendarDate get startOfJalaliMonth {
    final j = jalali;
    return CalendarDate.fromJalali(j.year, j.month, 1);
  }

  /// First day of the next Jalali month.
  CalendarDate get startOfNextJalaliMonth {
    final j = jalali;
    return j.month == 12
        ? CalendarDate.fromJalali(j.year + 1, 1, 1)
        : CalendarDate.fromJalali(j.year, j.month + 1, 1);
  }

  /// Last day of the Jalali month containing this date.
  CalendarDate get endOfJalaliMonth => startOfNextJalaliMonth.addDays(-1);

  /// First day of the Jalali year containing this date.
  CalendarDate get startOfJalaliYear =>
      CalendarDate.fromJalali(jalali.year, 1, 1);

  /// First day of the next Jalali year.
  CalendarDate get startOfNextJalaliYear =>
      CalendarDate.fromJalali(jalali.year + 1, 1, 1);

  /// True when the date falls inside `[start, end]` inclusive.
  bool isWithin(CalendarDate start, CalendarDate end) =>
      compareTo(start) >= 0 && compareTo(end) <= 0;

  @override
  int compareTo(CalendarDate other) {
    final byYear = year.compareTo(other.year);
    if (byYear != 0) return byYear;
    final byMonth = month.compareTo(other.month);
    if (byMonth != 0) return byMonth;
    return day.compareTo(other.day);
  }

  /// True when this date is strictly before [other].
  bool isBefore(CalendarDate other) => compareTo(other) < 0;

  /// True when this date is strictly after [other].
  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  bool operator <(CalendarDate other) => compareTo(other) < 0;
  bool operator <=(CalendarDate other) => compareTo(other) <= 0;
  bool operator >(CalendarDate other) => compareTo(other) > 0;
  bool operator >=(CalendarDate other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// Inclusive date range used by reports and filters.
@immutable
final class DateRange {
  const DateRange(this.start, this.end);

  final CalendarDate start;
  final CalendarDate end;

  /// The stored lower bound (inclusive).
  DateTime get startStored => start.stored;

  /// The stored upper bound (exclusive) for half-open SQL ranges.
  DateTime get endExclusiveStored => end.addDays(1).stored;

  int get lengthInDays => start.differenceInDays(end).abs() + 1;

  bool contains(CalendarDate date) => date.isWithin(start, end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}
