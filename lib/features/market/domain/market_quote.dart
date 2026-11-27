import '../../../core/money/rial.dart';

/// The kind of asset a [MarketQuote] prices.
///
/// This is the market subsystem's own taxonomy; it is intentionally separate
/// from the user's portfolio model (`AssetKind`) so that quotes for coins and
/// bullion can exist even when no holding uses them.
enum MarketAssetKind {
  /// A fiat currency unit (USD, EUR, ...), quoted per one unit.
  fiat,

  /// A cryptocurrency unit (BTC, USDT, ...), quoted per one coin/token.
  crypto,

  /// One gram of 18-karat gold (`GOL18`) or another gold weight unit.
  goldGram,

  /// One minted gold coin (Azadi, Emami, half/quarter Azadi, Gerami).
  goldCoin,

  /// One gram of fine silver (`XAG`).
  silver,
}

/// A single price point published by one market source.
///
/// [priceRial] is the primary price of one unit in integer Rial. When the
/// source publishes both sides of its book, [buyRial] is the price at which the
/// source buys the unit from the customer and [sellRial] the price at which it
/// sells it. Money is never stored as a floating point number.
final class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.kind,
    required this.priceRial,
    required this.source,
    required this.updatedAt,
    this.buyRial,
    this.sellRial,
  });

  /// Canonical uppercase symbol: an ISO currency code (`USD`), a crypto ticker
  /// (`BTC`), a bullion symbol (`GOL18`, `XAG`, `MITHQAL`) or a coin symbol
  /// (`AZADI`, `EMAMI`, `AZADI_HALF`, `AZADI_QUARTER`, `GERAMI`).
  final String symbol;

  /// Asset class of [symbol].
  final MarketAssetKind kind;

  /// Primary price of one unit in Rial, always positive.
  final Rial priceRial;

  /// Price at which the source buys one unit from the customer, when published.
  final Rial? buyRial;

  /// Price at which the source sells one unit to the customer, when published.
  final Rial? sellRial;

  /// Stable source name: `Bonbast`, `Chand`, `Nobitex` or `Tetherland`.
  final String source;

  /// When the source last refreshed this price. Always in UTC.
  final DateTime updatedAt;

  @override
  String toString() =>
      'MarketQuote($symbol ${priceRial.value} rial from $source)';
}

/// Health of one provider after a fetch attempt.
final class MarketSourceStatus {
  const MarketSourceStatus({
    required this.source,
    required this.ok,
    required this.quoteCount,
    this.error,
  });

  /// Stable source name, matching [MarketQuote.source].
  final String source;

  /// True when the provider returned at least one usable quote.
  final bool ok;

  /// Number of quotes the provider contributed to this fetch.
  final int quoteCount;

  /// Persian description of the failure when [ok] is false, otherwise `null`.
  final String? error;

  @override
  String toString() =>
      'MarketSourceStatus($source, ok: $ok, quotes: $quoteCount)';
}

/// A merged, timestamped view of the market.
///
/// The service builds one snapshot per cache window. Quotes are merged across
/// sources by a fixed priority order (see `MarketPriceService`), and the
/// per-source statuses let callers show what is stale or unavailable.
final class MarketSnapshot {
  MarketSnapshot({
    required List<MarketQuote> quotes,
    required this.fetchedAt,
    required List<MarketSourceStatus> sources,
  }) : quotes = List.unmodifiable(quotes),
       sources = List.unmodifiable(sources);

  /// Merged quotes, one per (kind, symbol), ordered by kind then symbol.
  final List<MarketQuote> quotes;

  /// When this snapshot was assembled, in UTC.
  final DateTime fetchedAt;

  /// Outcome of each provider that took part in this fetch.
  final List<MarketSourceStatus> sources;

  /// Looks a quote up by symbol, ignoring case.
  ///
  /// Returns `null` when the snapshot has no quote for [symbol].
  MarketQuote? quote(String symbol) {
    final normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final quote in quotes) {
      if (quote.symbol.toUpperCase() == normalized) return quote;
    }
    return null;
  }

  /// Looks a quote up by both kind and symbol; symbols are canonical but the
  /// kind check keeps coin versus bullion content from ever mixing.
  MarketQuote? quoteOf(MarketAssetKind kind, String symbol) {
    final normalized = symbol.trim().toUpperCase();
    if (normalized.isEmpty) return null;
    for (final quote in quotes) {
      if (quote.kind == kind && quote.symbol.toUpperCase() == normalized) {
        return quote;
      }
    }
    return null;
  }

  @override
  String toString() =>
      'MarketSnapshot(${quotes.length} quotes, '
      '${sources.where((source) => source.ok).length}/${sources.length} sources)';
}
