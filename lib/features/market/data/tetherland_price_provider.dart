import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/market_quote.dart';
import '../domain/market_symbols.dart';
import 'price_math.dart';
import 'price_provider.dart';

/// Prices crypto assets from Tetherland's public APIs.
///
/// Tetherland splits its data over two endpoints: the legacy `/currencies`
/// endpoint publishes the USDT price in Toman, and the newer
/// `service.tetherland.com/api/v5/currencies` endpoint publishes the other coins
/// with a Toman amount. Both responses are combined into one quote list; when
/// one endpoint fails the other still contributes so a partial outage does not
/// take the whole source down.
final class TetherlandPriceProvider implements PriceProvider {
  const TetherlandPriceProvider();

  /// Stable source name used in quotes and merge priority.
  static const String sourceName = 'Tetherland';

  /// Legacy endpoint that publishes the USDT price in Toman.
  static const String usdtUrl = 'https://api.tetherland.com/currencies';

  /// Endpoint that publishes the other crypto prices.
  static const String currenciesUrl =
      'https://service.tetherland.com/api/v5/currencies';

  /// Browser-like user agent.
  static const String userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 '
      'Mobile/15E148 Safari/604.1';

  /// Referer requested by Tetherland's API gateway.
  static const String referer = 'https://tetherland.com/';

  /// Origin requested by Tetherland's API gateway.
  static const String origin = 'https://tetherland.com';

  @override
  String get name => sourceName;

  @override
  Future<List<MarketQuote>> fetch(Dio dio) async {
    final fetchedAt = DateTime.now().toUtc();
    MarketQuote? usdt;
    Object? usdtError;
    try {
      usdt = parseUsdtBody(
        (await _get(dio, usdtUrl)).data ?? '',
        fetchedAt: fetchedAt,
      );
    } on Object catch (error) {
      usdtError = error;
    }

    List<MarketQuote> others = const <MarketQuote>[];
    Object? othersError;
    try {
      others = parseCurrenciesBody(
        (await _get(dio, currenciesUrl)).data ?? '',
        usdtRial: usdt?.priceRial.value,
        fetchedAt: fetchedAt,
      );
    } on Object catch (error) {
      othersError = error;
    }

    final quotes = <MarketQuote>[?usdt, ...others];
    if (quotes.isEmpty) {
      throw ValidationException(
        'دریافت نرخ از تترلند انجام نشد. دوباره تلاش کن.',
        debugDetail:
            'usdt: ${usdtError ?? 'ok'} | currencies: ${othersError ?? 'ok'}',
      );
    }
    return quotes;
  }

  /// Parses the legacy USDT payload: `data.currencies.USDT.price` in Toman.
  static MarketQuote parseUsdtBody(String body, {DateTime? fetchedAt}) {
    final json = decodeJsonObject(body);
    final data = json?['data'];
    final currencies = data is Map ? data['currencies'] : null;
    final usdtRaw = currencies is Map ? currencies['USDT'] : null;
    final price = usdtRaw is Map ? tomanToRial(usdtRaw['price']) : null;
    if (price == null) {
      throw const ValidationException(
        'نرخ تتر تترلند در دسترس نیست.',
        debugDetail: 'tetherland usdt payload has no usable price',
      );
    }
    return MarketQuote(
      symbol: 'USDT',
      kind: MarketAssetKind.crypto,
      priceRial: price,
      source: sourceName,
      updatedAt: fetchedAt ?? DateTime.now().toUtc(),
    );
  }

  /// Parses the newer currency payload: `data[]` items with `symbol`,
  /// `toman_amount` (Toman) and `price` (USD).
  ///
  /// [usdtRial] is the Rial price of one USDT from [parseUsdtBody]; when an item
  /// omits its Toman amount the Rial price is derived from its USD price and
  /// that factor. Items that are not in [cryptoSymbols], `USDT` itself and
  /// unusable numbers are skipped; a payload without any usable quote throws.
  static List<MarketQuote> parseCurrenciesBody(
    String body, {
    int? usdtRial,
    DateTime? fetchedAt,
  }) {
    final json = decodeJsonObject(body);
    if (json == null) {
      throw const ValidationException(
        'پاسخ نرخ رمزارزهای تترلند معتبر نیست.',
        debugDetail: 'tetherland currencies response is not a json object',
      );
    }
    final data = json['data'];
    if (data is! List) {
      throw const ValidationException(
        'پاسخ نرخ رمزارزهای تترلند معتبر نیست.',
        debugDetail: 'tetherland currencies data is not a json array',
      );
    }

    final updatedAt = fetchedAt ?? DateTime.now().toUtc();
    final quotes = <MarketQuote>[];
    for (final item in data) {
      if (item is! Map) continue;
      final rawSymbol = item['symbol'];
      if (rawSymbol is! String) continue;
      final symbol = rawSymbol.trim().toUpperCase();
      if (symbol == 'USDT' || !cryptoSymbols.contains(symbol)) continue;

      final toman = tomanToRial(item['toman_amount']);
      final derived = usdtRial == null
          ? null
          : multiplyDecimal(item['price'], usdtRial);
      final price = toman ?? derived;
      if (price == null) continue;
      quotes.add(
        MarketQuote(
          symbol: symbol,
          kind: MarketAssetKind.crypto,
          priceRial: price,
          source: sourceName,
          updatedAt: updatedAt,
        ),
      );
    }

    if (quotes.isEmpty) {
      throw const ValidationException(
        'پاسخ نرخ رمزارزهای تترلند نرخی نداشت.',
        debugDetail: 'tetherland currencies payload contained no usable price',
      );
    }
    return quotes;
  }

  Future<Response<String>> _get(Dio dio, String url) async {
    try {
      return await dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: <String, String>{
            'User-Agent': userAgent,
            'Accept': 'application/json',
            'Accept-Language': 'en-US,en;q=0.9',
            'Referer': referer,
            'Origin': origin,
          },
        ),
      );
    } on DioException catch (error) {
      throw ValidationException(
        'اتصال به تترلند برقرار نشد.',
        debugDetail: _describe(error),
      );
    }
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
