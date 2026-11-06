import 'package:daram/core/money/currency.dart';
import 'package:daram/core/persian/amount_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = AmountParser();

  group('AmountParser', () {
    test('parses a Persian-style expense sentence', () {
      final result = parser.parse('امروز ۲۵۰ هزار تومن ناهار خوردم');
      expect(result.isSuccess, isTrue);
      expect(result.rial!.value, 2500000);
      expect(result.currencyExplicit, isTrue);
    });

    test('parses word numbers and toman', () {
      expect(parser.parse('سه میلیون').rial!.value, 30000000);
      expect(parser.parse('ده تومن').rial!.value, 100);
      expect(parser.parse('سیصد و پنجاه تومن').rial!.value, 3500);
    });

    test('parses a fraction', () {
      expect(parser.parse('یک و نیم میلیون').rial!.value, 15000000);
      expect(parser.parse('نیم میلیون تومان').rial!.value, 5000000);
    });

    test('parses milliard', () {
      expect(parser.parse('۲ میلیارد').rial!.value, 20000000000);
    });

    test('respects an explicit rial unit', () {
      final result = parser.parse('۵۰۰,۰۰۰ ریال');
      expect(result.rial!.value, 500000);
      expect(result.currencyExplicit, isTrue);
    });

    test('uses the fallback unit when unit is not stated', () {
      final rial = parser.parse('۵۰۰ هزار', fallbackUnit: CurrencyUnit.rial);
      expect(rial.rial!.value, 500000);
      expect(rial.currencyExplicit, isFalse);
    });

    test('parses amounts in the middle of a sentence', () {
      final result = parser.parse(
        '۵۰۰ هزار تومن از کارت ملتم زدم به بلو بانکم',
      );
      expect(result.rial!.value, 5000000);
      expect(result.matchedText, '500 هزار');
    });

    test('handles Arabic digits', () {
      expect(parser.parse('٢٥٠ هزار تومان').rial!.value, 2500000);
    });

    test('fails without a number', () {
      expect(parser.parse('سلام حالت چطوره').isSuccess, isFalse);
    });

    test('marks a small unit-less amount as ambiguous', () {
      final result = parser.parse('۵۰۰ خرج کردم');
      expect(result.ambiguous, isTrue);
    });
  });
}
