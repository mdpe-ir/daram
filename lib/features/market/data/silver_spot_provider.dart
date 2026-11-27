import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../domain/market_quote.dart';
import '../domain/market_symbols.dart';
import 'price_provider.dart';

/// Real silver spot price (COMEX front-month, USD per troy ounce) converted to
/// Rial per gram.
///
/// Bonbast and Chand do not publish silver, and the previous rate provider only
/// had a silver quote of its own. Yahoo Finance's public chart endpoint carries
/// the COMEX silver future, so DARAM keeps real silver coverage: the USD/oz
/// price is fetched here and converted with the USD/Toman quote that the other
/// providers already produced in the same snapshot.
class SilverSpotProvider implements PriceProvider, DerivedPriceProvider {
  const SilverSpotProvider();

  /// Stable source name used for [MarketQuote.source].
  static const String sourceName = 'Yahoo Finance';

  /// Public chart endpoint for the COMEX silver front-month future (`SI=F`).
  static const String spotUrl =
      'https://query1.finance.yahoo.com/v8/finance/chart/SI=F'
      '?interval=1d&range=1d';

  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36';

  /// Troy ounces per gram expressed in micro-units: 1 oz = 31.1034768 g.
  static const int _microGramsPerOunce = 311034768;

  @override
  String get name => sourceName;

  /// Silver needs the USD/Toman rate from the merged snapshot, so the normal
  /// fetch phase contributes nothing; [derive] does the work.
  @override
  Future<List<MarketQuote>> fetch(Dio dio) async => const <MarketQuote>[];

  @override
  Future<List<MarketQuote>> derive(Dio dio, MarketSnapshot merged) async {
    final usd = merged.quoteOf(MarketAssetKind.fiat, 'USD');
    if (usd == null) return const <MarketQuote>[];
    final usdRial = usd.sellRial ?? usd.priceRial;
    if (usdRial.value <= 0) return const <MarketQuote>[];

    final response = await dio.get<String>(
      spotUrl,
      options: Options(
        responseType: ResponseType.plain,
        headers: {'User-Agent': userAgent, 'Accept': 'application/json'},
      ),
    );
    final body = response.data;
    if (body == null || body.trim().isEmpty) {
      throw const ValidationException(
        'پاسخ نرخ نقره خالی بود.',
        code: 'silver_empty_response',
      );
    }
    final spot = parseSpotBody(body);
    if (spot == null) {
      throw const ValidationException(
        'نرخ نقره از منبع جهانی قابل خواندن نبود.',
        code: 'silver_invalid_payload',
      );
    }
    final rial = convertToRialPerGram(
      microUsdPerOunce: spot.microUsd,
      rialPerUsd: usdRial.value,
    );
    if (rial == null) {
      throw const ValidationException(
        'نرخ نقره خارج از محدوده معتبر است.',
        code: 'silver_rate_out_of_range',
      );
    }
    return <MarketQuote>[
      MarketQuote(
        symbol: silverSymbol,
        kind: MarketAssetKind.silver,
        priceRial: rial,
        source: sourceName,
        updatedAt: spot.updatedAt,
      ),
    ];
  }

  /// Parses the Yahoo Finance chart payload into micro-USD per troy ounce.
  ///
  /// Pure so tests can run against a captured payload. Returns `null` when the
  /// JSON has no usable price.
  static ({int microUsd, DateTime updatedAt})? parseSpotBody(String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;
    final chart = decoded['chart'];
    if (chart is! Map) return null;
    final result = chart['result'];
    if (result is! List || result.isEmpty) return null;
    final first = result.first;
    if (first is! Map) return null;
    final meta = first['meta'];
    if (meta is! Map) return null;

    double? price;
    final rawPrice = meta['regularMarketPrice'];
    if (rawPrice is num && rawPrice > 0) {
      price = rawPrice.toDouble();
    }
    if (price == null) {
      // Older payloads only carry the close series.
      final indicators = first['indicators'];
      if (indicators is Map) {
        final quotes = indicators['quote'];
        if (quotes is List && quotes.isNotEmpty && quotes.first is Map) {
          final closes = (quotes.first as Map)['close'];
          if (closes is List) {
            for (final close in closes.reversed) {
              if (close is num && close > 0) {
                price = close.toDouble();
                break;
              }
            }
          }
        }
      }
    }
    if (price == null) return null;

    final rawTime = meta['regularMarketTime'];
    final seconds = rawTime is num ? rawTime.toInt() : null;
    final updatedAt = seconds == null || seconds <= 0
        ? DateTime.now().toUtc()
        : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
    final microUsd = (price * 1000000).round();
    if (microUsd <= 0) return null;
    return (microUsd: microUsd, updatedAt: updatedAt);
  }

  /// Converts a micro-USD price per troy ounce to Rial per gram, rounding half
  /// up exactly (no floating point money).
  static Rial? convertToRialPerGram({
    required int microUsdPerOunce,
    required int rialPerUsd,
  }) {
    if (microUsdPerOunce <= 0 || rialPerUsd <= 0) return null;
    // rial/g = microUsd * 1e-6 * rialPerUsd * 10 / 311,034,768
    final numerator =
        BigInt.from(microUsdPerOunce) *
        BigInt.from(rialPerUsd) *
        BigInt.from(10);
    final denominator = BigInt.from(_microGramsPerOunce);
    final rounded = (numerator + denominator ~/ BigInt.two) ~/ denominator;
    if (rounded <= BigInt.zero ||
        rounded > BigInt.from(Rial.maxAbsoluteValue)) {
      return null;
    }
    return Rial(rounded.toInt());
  }
}
