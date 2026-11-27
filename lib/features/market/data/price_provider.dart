import 'package:dio/dio.dart';

import '../domain/market_quote.dart';

/// A live market price source.
///
/// Implementations fetch from one upstream feed and return quotes in the
/// market subsystem's canonical symbols. Parsing is exposed separately as pure
/// static functions on each implementation, so tests can exercise it against
/// captured payloads without any network access.
///
/// [fetch] must throw a descriptive exception (normally `ValidationException`)
/// when the feed is unreachable or its payload is malformed; the service turns
/// that into a failed [MarketSourceStatus] instead of failing the whole
/// snapshot.
abstract interface class PriceProvider {
  /// Stable source name, used as [MarketQuote.source] and as the merge-priority
  /// key. It must not change between releases.
  String get name;

  /// Fetches the current quotes for [dio].
  Future<List<MarketQuote>> fetch(Dio dio);
}

/// A provider whose quote depends on prices from other providers.
///
/// Derived providers are not fetched in the normal parallel phase; the service
/// first merges the direct quotes into an interim [MarketSnapshot] and then
/// asks each derived provider for extra quotes. The silver spot price is the
/// only current user: it needs the USD/Toman rate to turn USD per ounce into
/// Rial per gram.
abstract interface class DerivedPriceProvider {
  /// Stable source name, matching the quotes it returns.
  String get name;

  /// Produces extra quotes from the already merged [merged] snapshot.
  Future<List<MarketQuote>> derive(Dio dio, MarketSnapshot merged);
}
