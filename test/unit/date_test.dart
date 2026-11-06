import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/core/time/jalali_text.dart';
import 'package:daram/core/time/persian_date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarDate', () {
    test('converts to Jalali correctly', () {
      final date = CalendarDate(2024, 8, 13);
      final j = date.jalali;
      expect(j.year, 1403);
      expect(j.month, 5);
      expect(j.day, 23);
    });

    test('converts from Jalali correctly', () {
      final date = CalendarDate.fromJalali(1403, 5, 23);
      expect(date, CalendarDate(2024, 8, 13));
    });

    test('stores UTC midnight to avoid timezone drift', () {
      final date = CalendarDate(2024, 3, 20);
      expect(date.stored.isUtc, isTrue);
      expect(date.stored, DateTime.utc(2024, 3, 20));
      expect(CalendarDate.fromStored(date.stored), date);
    });

    test('handles month boundaries', () {
      final date = CalendarDate.fromJalali(1403, 12, 29);
      expect(date.endOfJalaliMonth, CalendarDate.fromJalali(1403, 12, 30));
      expect(date.startOfNextJalaliMonth, CalendarDate.fromJalali(1404, 1, 1));
    });

    test('validates gregorian dates', () {
      expect(CalendarDate.isValid(2024, 2, 29), isTrue);
      expect(CalendarDate.isValid(2023, 2, 29), isFalse);
    });

    test('formats Jalali text', () {
      final date = CalendarDate(2024, 8, 13);
      expect(const JalaliText().date(date), '۲۳ مرداد ۱۴۰۳');
      expect(const JalaliText().numeric(date), '۱۴۰۳/۰۵/۲۳');
      expect(const JalaliText().relative(date, reference: date), 'امروز');
    });
  });

  group('PersianDateParser', () {
    final parser = PersianDateParser(
      reference: CalendarDate(2024, 7, 20),
    ); // 1403/04/30

    test('resolves relative day words', () {
      expect(parser.parse('امروز').date, CalendarDate(2024, 7, 20));
      expect(parser.parse('دیروز').date, CalendarDate(2024, 7, 19));
      expect(parser.parse('پریروز').date, CalendarDate(2024, 7, 18));
      expect(parser.parse('فردا').date, CalendarDate(2024, 7, 21));
    });

    test('resolves Jalali month names with an explicit year', () {
      expect(parser.parse('۲۳ مرداد ۱۴۰۳').date, CalendarDate(2024, 8, 13));
      expect(
        parser.parse('بیست و سوم مرداد ۱۴۰۳').date,
        CalendarDate(2024, 8, 13),
      );
    });

    test('marks a missing year as ambiguous and picks the past', () {
      final result = parser.parse('پنجم دی');
      expect(result.isSuccess, isTrue);
      expect(result.ambiguous, isTrue);
      expect(result.date, CalendarDate.fromJalali(1402, 10, 5));
    });

    test('resolves numeric Jalali dates', () {
      expect(parser.parse('۱۴۰۳/۰۵/۲۳').date, CalendarDate(2024, 8, 13));
    });

    test('resolves month boundaries', () {
      expect(parser.parse('اول ماه').date, CalendarDate.fromJalali(1403, 4, 1));
      expect(
        parser.parse('آخر ماه').date,
        CalendarDate.fromJalali(1403, 4, 31),
      );
    });

    test('resolves a Persian date range', () {
      final range = PersianDateParser(reference: CalendarDate(2024, 9, 1))
          .parseRange('از اول مرداد تا اول شهریور');
      expect(range, isNotNull);
      expect(range!.start.date, CalendarDate.fromJalali(1403, 5, 1));
      expect(range.end.date, CalendarDate.fromJalali(1403, 6, 1));
    });

    test('fails clearly on garbage input', () {
      final result = parser.parse('یک روز خوب');
      expect(result.isSuccess, isFalse);
    });
  });
}
