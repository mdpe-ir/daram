import 'package:daram/core/constants/crypto_assets.dart';
import 'package:daram/features/assets/data/navasan_rates.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog has unique, well-formed ticker symbols', () {
    final symbols = cryptoAssets.map((coin) => coin.symbol).toList();
    expect(symbols.toSet().length, symbols.length);
    for (final coin in cryptoAssets) {
      expect(coin.symbol, matches(RegExp(r'^[A-Z]{3,10}$')));
      expect(coin.nameFa.trim(), isNotEmpty);
      expect(coin.nameEn.trim(), isNotEmpty);
    }
    expect(cryptoAssets.length, greaterThanOrEqualTo(30));
    expect(cryptoAssets.where((coin) => coin.popular).length, 12);
    expect(cryptoAssets.first.symbol, 'BTC');
  });

  test('every coin ships a bundled icon', () async {
    for (final coin in cryptoAssets) {
      final asset = coin.iconAsset;
      expect(asset, 'assets/crypto/${coin.symbol.toLowerCase()}.svg');
      final data = await rootBundle.load(asset!);
      expect(data.lengthInBytes, greaterThan(200), reason: asset);
    }
  });

  test('only quoted coins offer the fetch button', () {
    final quoted = cryptoAssets.where((coin) => coin.hasQuote).toList();
    expect(quoted.map((coin) => coin.symbol), ['BTC']);
    for (final coin in cryptoAssets) {
      expect(
        coin.hasQuote,
        NavasanRates.quotedCryptoContains(coin.symbol.toLowerCase()),
        reason: coin.symbol,
      );
    }
  });

  test('lookup is case-insensitive and tolerant of spaces', () {
    expect(cryptoBySymbol('btc')?.symbol, 'BTC');
    expect(cryptoBySymbol(' USDT ')?.nameFa, 'تتر');
    expect(cryptoBySymbol('SHIB'), isNull);
    expect(cryptoBySymbol(''), isNull);
    expect(cryptoBySymbol(null), isNull);
  });

  test('search matches Persian name, English name and symbol', () {
    expect(searchCryptoAssets('بیت‌کوین').first.symbol, 'BTC');
    expect(searchCryptoAssets('بیت کوین').first.symbol, 'BTC');
    expect(searchCryptoAssets('bitcoin').first.symbol, 'BTC');
    expect(searchCryptoAssets('usdt').first.symbol, 'USDT');
    expect(searchCryptoAssets('تتر').first.symbol, 'USDT');
    expect(searchCryptoAssets('هیچ‌چیز').isEmpty, isTrue);
    expect(searchCryptoAssets('').length, cryptoAssets.length);
  });

  test('codes outside the catalog render without an icon', () {
    final coin = cryptoOrSymbol('shib');
    expect(coin.symbol, 'SHIB');
    expect(coin.nameFa, 'SHIB');
    expect(coin.iconAsset, isNull);
    expect(coin.hasQuote, isFalse);
  });
}
