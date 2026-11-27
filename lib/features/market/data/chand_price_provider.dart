import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/market_quote.dart';
import '../domain/market_symbols.dart';
import 'price_math.dart';
import 'price_provider.dart';

/// Prices fiat currencies, crypto and gold from the Chand feed.
///
/// Chand (`hansha.online/latest`) publishes a flat JSON array. Each item has an
/// abbreviation (`ab`), an optional type (`ty`: `cu` fiat, `cc` crypto, `co`
/// gold coin, `go` gold by weight) and a list of price snapshots (`ps`); the
/// first snapshot is the latest. Prices are in Toman per unit and are converted
/// to integer Rial.
final class ChandPriceProvider implements PriceProvider {
  const ChandPriceProvider();

  /// Stable source name used in quotes and merge priority.
  static const String sourceName = 'Chand';

  /// Endpoint returning the latest Chand snapshot.
  static const String latestUrl = 'https://hansha.online/latest';

  /// Browser-like user agent; some Iranian hosts reject default agents.
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36';

  /// Chand abbreviation to canonical gold-coin symbol.
  static const Map<String, String> _goldCoinSymbols = <String, String>{
    'azadi': 'AZADI',
    'emami': 'EMAMI',
    'half': 'AZADI_HALF',
    'quarter': 'AZADI_QUARTER',
    'gerami': 'GERAMI',
  };

  /// Chand abbreviation to canonical gold-by-weight symbol.
  ///
  /// Chand's `gram` feed is the 18-karat gram price, the same unit as Bonbast's
  /// `gol18`, so both providers publish it as [goldGramSymbol].
  static const Map<String, String> _goldWeightSymbols = <String, String>{
    'gram': goldGramSymbol,
    'mithqal': mithqalSymbol,
  };

  @override
  String get name => sourceName;

  @override
  Future<List<MarketQuote>> fetch(Dio dio) async {
    final Response<String> response;
    try {
      response = await dio.get<String>(
        latestUrl,
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
        'اتصال به چاند برقرار نشد. دوباره تلاش کن.',
        debugDetail: _describe(error),
      );
    }
    return parseBody(response.data ?? '', fetchedAt: DateTime.now().toUtc());
  }

  /// Parses a raw Chand JSON body.
  static List<MarketQuote> parseBody(String body, {DateTime? fetchedAt}) {
    final items = decodeJsonList(body);
    if (items == null) {
      throw const ValidationException(
        'پاسخ نرخ چاند معتبر نیست.',
        debugDetail: 'chand response is not a json array',
      );
    }
    return parseItems(items, fetchedAt: fetchedAt);
  }

  /// Parses already-decoded Chand items into canonical quotes.
  ///
  /// Items with an unknown abbreviation, an empty price list or an unusable
  /// number are skipped; a payload without any usable quote throws.
  static List<MarketQuote> parseItems(
    List<Object?> items, {
    DateTime? fetchedAt,
  }) {
    final fallbackTime = fetchedAt ?? DateTime.now().toUtc();
    final quotes = <MarketQuote>[];

    for (final item in items) {
      if (item is! Map) continue;
      final abbreviation = item['ab'];
      if (abbreviation is! String) continue;
      final key = abbreviation.trim().toLowerCase();
      if (key.isEmpty) continue;
      final target = _targetFor(key);
      if (target == null) continue;

      final snapshots = item['ps'];
      if (snapshots is! List || snapshots.isEmpty) continue;
      final latest = snapshots.first;
      if (latest is! Map) continue;

      final sell = tomanToRial(latest['sp']);
      final buy = tomanToRial(latest['bp']);
      final price = sell ?? buy;
      if (price == null) continue;

      final timestamp = latest['ts'];
      final updatedAt = timestamp is String
          ? DateTime.tryParse(timestamp)?.toUtc()
          : null;

      quotes.add(
        MarketQuote(
          symbol: target.symbol,
          kind: target.kind,
          priceRial: price,
          sellRial: sell,
          buyRial: buy,
          source: sourceName,
          updatedAt: updatedAt ?? fallbackTime,
        ),
      );
    }

    if (quotes.isEmpty) {
      throw const ValidationException(
        'پاسخ نرخ چاند نرخی نداشت.',
        debugDetail: 'chand payload contained no usable price',
      );
    }
    return quotes;
  }

  static ({MarketAssetKind kind, String symbol})? _targetFor(String key) {
    final upper = key.toUpperCase();
    if (fiatSymbols.contains(upper)) {
      return (kind: MarketAssetKind.fiat, symbol: upper);
    }
    if (cryptoSymbols.contains(upper)) {
      return (kind: MarketAssetKind.crypto, symbol: upper);
    }
    final coin = _goldCoinSymbols[key];
    if (coin != null) {
      return (kind: MarketAssetKind.goldCoin, symbol: coin);
    }
    final weight = _goldWeightSymbols[key];
    if (weight != null) {
      return (kind: MarketAssetKind.goldGram, symbol: weight);
    }
    return null;
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
