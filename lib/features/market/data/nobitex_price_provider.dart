import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/market_quote.dart';
import '../domain/market_symbols.dart';
import 'price_math.dart';
import 'price_provider.dart';

/// Prices crypto assets from Nobitex's public market statistics.
///
/// The endpoint returns one entry per market pair; this provider reads the
/// `<ticker>-rls` pairs, whose `latest`, `bestSell` and `bestBuy` values are
/// already in Rial. Every supported symbol is published in one response, so a
/// single request fills the crypto side of the snapshot.
final class NobitexPriceProvider implements PriceProvider {
  const NobitexPriceProvider();

  /// Stable source name used in quotes and merge priority.
  static const String sourceName = 'Nobitex';

  /// Endpoint returning market statistics for every Nobitex pair.
  static const String marketStatsUrl = 'https://api.nobitex.ir/market/stats';

  /// Browser-like user agent.
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36';

  @override
  String get name => sourceName;

  @override
  Future<List<MarketQuote>> fetch(Dio dio) async {
    final Response<String> response;
    try {
      response = await dio.get<String>(
        marketStatsUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: <String, String>{
            'User-Agent': userAgent,
            'Accept': 'application/json',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );
    } on DioException catch (error) {
      throw ValidationException(
        'اتصال به نوبیتکس برقرار نشد. دوباره تلاش کن.',
        debugDetail: _describe(error),
      );
    }
    return parseBody(response.data ?? '', fetchedAt: DateTime.now().toUtc());
  }

  /// Parses a raw Nobitex market-stats body.
  static List<MarketQuote> parseBody(String body, {DateTime? fetchedAt}) {
    final json = decodeJsonObject(body);
    if (json == null) {
      throw const ValidationException(
        'پاسخ نرخ نوبیتکس معتبر نیست.',
        debugDetail: 'nobitex response is not a json object',
      );
    }
    return parseJson(json, fetchedAt: fetchedAt);
  }

  /// Parses already-decoded Nobitex market statistics into canonical quotes.
  static List<MarketQuote> parseJson(
    Map<String, Object?> json, {
    DateTime? fetchedAt,
  }) {
    final status = json['status'];
    if (status != 'ok') {
      throw ValidationException(
        'پاسخ نرخ نوبیتکس خطا داشت.',
        debugDetail: 'nobitex status: ${status ?? 'missing'}',
      );
    }
    final stats = json['stats'];
    if (stats is! Map) {
      throw const ValidationException(
        'پاسخ نرخ نوبیتکس معتبر نیست.',
        debugDetail: 'nobitex stats is not a json object',
      );
    }

    final updatedAt = fetchedAt ?? DateTime.now().toUtc();
    final quotes = <MarketQuote>[];
    for (final symbol in cryptoSymbols) {
      final market = stats['${symbol.toLowerCase()}-rls'];
      if (market is! Map) continue;
      final latest = rialFromDecimal(market['latest']);
      final sell = rialFromDecimal(market['bestSell']);
      final buy = rialFromDecimal(market['bestBuy']);
      final price = latest ?? sell ?? buy;
      if (price == null) continue;
      quotes.add(
        MarketQuote(
          symbol: symbol,
          kind: MarketAssetKind.crypto,
          priceRial: price,
          sellRial: sell,
          buyRial: buy,
          source: sourceName,
          updatedAt: updatedAt,
        ),
      );
    }

    if (quotes.isEmpty) {
      throw const ValidationException(
        'پاسخ نرخ نوبیتکس نرخی نداشت.',
        debugDetail: 'nobitex payload contained no usable price',
      );
    }
    return quotes;
  }

  static String _describe(DioException error) {
    final status = error.response?.statusCode;
    return <String>[
      error.requestOptions.uri.toString(),
      error.type.name,
      if (status != null) 'HTTP $status',
      if (error.message != null) error.message!,
    ].join(' | ');
  }
}
