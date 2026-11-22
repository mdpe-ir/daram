import 'package:daram/core/constants/world_currencies.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog uses unique, well-formed ISO codes', () {
    final codes = worldCurrencies.map((currency) => currency.code).toList();
    expect(codes.toSet().length, codes.length);
    for (final currency in worldCurrencies) {
      expect(currency.code, matches(RegExp(r'^[A-Z]{3}$')));
      expect(currency.nameFa.trim(), isNotEmpty);
    }
    expect(worldCurrencies.length, greaterThanOrEqualTo(60));
    expect(worldCurrencies.where((currency) => currency.popular).length, 12);
  });

  test('every currency ships a bundled circular flag', () async {
    for (final currency in worldCurrencies) {
      expect(
        currency.countryCode,
        matches(RegExp(r'^[a-z]{2}$')),
        reason: currency.code,
      );
      final asset = currency.flagAsset;
      expect(asset, 'assets/flags/${currency.countryCode}.svg');
      final data = await rootBundle.load(asset!);
      expect(data.lengthInBytes, greaterThan(200), reason: asset);
    }
    expect(currencyOrCode('xbt').flagAsset, isNull);
  });

  test('lookup is case-insensitive and tolerant of spaces', () {
    expect(currencyByCode('USD')?.code, 'USD');
    expect(currencyByCode('usd')?.code, 'USD');
    expect(currencyByCode(' usd ')?.code, 'USD');
    expect(currencyByCode('AED')?.nameFa, 'درهم امارات');
    expect(currencyByCode(''), isNull);
    expect(currencyByCode(null), isNull);
    expect(currencyByCode('XYZ'), isNull);
  });

  test('search matches Persian name, country and code', () {
    expect(searchCurrencies('دلار').first.code, 'USD');
    expect(searchCurrencies('دلار آمریکا').map((c) => c.code), ['USD']);
    // Arabic yeh/kaf, a missing ZWNJ and bare alef still match.
    expect(searchCurrencies('امريكا').first.code, 'USD');
    expect(searchCurrencies('هنگ کنگ').first.code, 'HKD');
    expect(searchCurrencies('eur').first.code, 'EUR');
    expect(searchCurrencies('').length, worldCurrencies.length);
  });

  test('unknown saved codes still render through currencyOrCode', () {
    final known = currencyOrCode('gbp');
    expect(known.code, 'GBP');
    expect(known.nameFa, 'پوند انگلیس');

    final unknown = currencyOrCode('xbt');
    expect(unknown.code, 'XBT');
    expect(unknown.nameFa, 'XBT');
    expect(unknown.countryFa, isEmpty);
  });
}
