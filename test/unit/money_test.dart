import 'package:daram/core/formatting/persian_formatting.dart';
import 'package:daram/core/money/currency.dart';
import 'package:daram/core/money/rial.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rial', () {
    test('stores integer rial and converts toman exactly', () {
      final amount = Rial.fromToman(250000);
      expect(amount.value, 2500000);
      expect(amount.toTomanTruncated(), 250000);
    });

    test('never rounds a fractional toman input', () {
      expect(Rial.fromTomanExact('1.5').value, 15);
      expect(() => Rial.fromTomanExact('1.55'), throwsA(isA<MoneyException>()));
    });

    test('rejects unsafe magnitudes', () {
      expect(
        () => Rial(Rial.maxAbsoluteValue + 1),
        throwsA(isA<MoneyException>()),
      );
      expect(
        () => Rial.fromToman(Rial.maxAbsoluteValue ~/ 10 + 1),
        throwsA(isA<MoneyException>()),
      );
    });

    test('arithmetic is exact and checked', () {
      final a = Rial(123456789);
      final b = Rial(987654321);
      expect((a + b).value, 1111111110);
      expect((b - a).value, 864197532);
      expect(a.multiply(3).value, 370370367);
      expect(Rial.sum([a, b]).value, 1111111110);
    });

    test('equality and comparison', () {
      expect(Rial(100), Rial.fromToman(10));
      expect(Rial(100) > Rial(99), isTrue);
      expect(Rial(-5).isNegative, isTrue);
      expect(Rial.zero.isZero, isTrue);
    });
  });

  group('PersianDigits', () {
    test('normalises Persian and Arabic digits to Latin', () {
      expect(PersianDigits.toLatin('۱۲۳۴۵۶۷۸۹۰'), '1234567890');
      expect(PersianDigits.toLatin('٠١٢٣٤٥٦٧٨٩'), '0123456789');
      expect(PersianDigits.toLatin('۱۲۳,۴۵۶'), '123,456');
    });

    test('converts back to Persian digits', () {
      expect(PersianDigits.toPersian('1403-05-23'), '۱۴۰۳-۰۵-۲۳');
    });
  });

  group('MoneyFormatter', () {
    test('formats toman with grouping and Persian digits', () {
      const formatter = MoneyFormatter(unit: CurrencyUnit.toman);
      expect(formatter.format(Rial.fromToman(250000)), '۲۵۰,۰۰۰ تومان');
    });

    test('formats rial without conversion', () {
      const formatter = MoneyFormatter(unit: CurrencyUnit.rial);
      expect(formatter.format(Rial(2500000)), '۲,۵۰۰,۰۰۰ ریال');
    });

    test('keeps a rial remainder instead of silently rounding', () {
      const formatter = MoneyFormatter(unit: CurrencyUnit.toman);
      expect(formatter.format(Rial(5)), '۰٫۵ تومان');
      expect(formatter.format(Rial(15)), '۱٫۵ تومان');
    });

    test('uses Latin digits when requested', () {
      const formatter = MoneyFormatter(
        unit: CurrencyUnit.toman,
        usePersianDigits: false,
      );
      expect(formatter.format(Rial.fromToman(1200000)), '1,200,000 تومان');
      expect(formatter.formatSigned(Rial.fromToman(10)), '+10 تومان');
    });
  });
}
