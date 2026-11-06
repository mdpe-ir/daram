import '../../../core/time/calendar_date.dart';

/// Convenience date ranges used by the dashboard and reports.
enum DateRangePreset {
  today('امروز'),
  thisWeek('این هفته'),
  thisMonth('این ماه'),
  lastMonth('ماه گذشته'),
  custom('بازه دلخواه');

  const DateRangePreset(this.labelFa);

  final String labelFa;
}

DateRange dateRangeFor(DateRangePreset preset, {CalendarDate? today}) {
  final reference = today ?? CalendarDate.today();
  switch (preset) {
    case DateRangePreset.today:
      return DateRange(reference, reference);
    case DateRangePreset.thisWeek:
      // The Persian week starts on Saturday.
      final daysSinceSaturday = (reference.isoWeekday + 1) % 7;
      final start = reference.addDays(-daysSinceSaturday);
      return DateRange(start, reference);
    case DateRangePreset.thisMonth:
      return DateRange(reference.startOfJalaliMonth, reference);
    case DateRangePreset.lastMonth:
      final currentStart = reference.startOfJalaliMonth;
      final previousStart = currentStart.addDays(-1).startOfJalaliMonth;
      return DateRange(previousStart, currentStart.addDays(-1));
    case DateRangePreset.custom:
      return DateRange(reference.startOfJalaliMonth, reference);
  }
}

/// The start of the current Jalali year, used for long-range exports.
DateRange currentJalaliYearRange({CalendarDate? today}) {
  final reference = today ?? CalendarDate.today();
  return DateRange(reference.startOfJalaliYear, reference);
}
