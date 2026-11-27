import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../../assets/domain/asset_quantity.dart';
import '../domain/market_quote.dart';
import '../domain/market_symbols.dart';
import 'bonbast_price_provider.dart';
import 'chand_price_provider.dart';
import 'nobitex_price_provider.dart';
import 'price_provider.dart';
import 'silver_spot_provider.dart';
import 'tetherland_price_provider.dart';

/// Fetches, merges and caches market prices for the whole app.
///
/// All providers run concurrently and each one is bounded by
/// [providerTimeout]. A failing or malformed source only marks that source as
/// unhealthy in [MarketSnapshot.sources]; it never breaks a snapshot built from
/// the remaining sources. The merged snapshot is cached for [cacheTtl] and, when
/// every source fails, the last good snapshot is served stale rather than
/// leaving the UI without prices.
///
/// Merge priority (highest first):
/// * gold and fiat: Bonbast, then Chand;
/// * crypto: Tetherland, then Nobitex, then Chand, then Bonbast's
///   USD-derived bitcoin quote;
/// * silver: derived after the merge from the COMEX spot price (Yahoo
///   Finance) and the USD/Toman rate, because no Iranian source publishes it.
class MarketPriceService {
  /// Creates a service over the default live sources.
  ///
  /// [providers] overrides the source list; it exists so tests can run without
  /// network access and so a caller can intentionally limit the sources.
  MarketPriceService(
    Dio dio, {
    this.cacheTtl = const Duration(minutes: 5),
    this.providerTimeout = const Duration(seconds: 20),
    List<PriceProvider>? providers,
  }) : _dio = dio,
       _providers = List<PriceProvider>.unmodifiable(
         providers ?? _defaultProviders,
       );

  /// Persian message shown when no source produced any price and nothing is
  /// cached yet.
  static const String noSourceMessage =
      'دریافت نرخ از منابع بازار ممکن نشد. اتصال اینترنت را بررسی کن.';

  /// Fiat currency codes this service can quote.
  static const List<String> supportedFiatSymbols = fiatSymbols;

  /// Crypto symbols this service can quote.
  static const List<String> supportedCryptoSymbols = cryptoSymbols;

  static final List<PriceProvider> _defaultProviders = <PriceProvider>[
    const BonbastPriceProvider(),
    const TetherlandPriceProvider(),
    const NobitexPriceProvider(),
    const ChandPriceProvider(),
    const SilverSpotProvider(),
  ];

  static const List<String> _bullionPriority = <String>[
    BonbastPriceProvider.sourceName,
    ChandPriceProvider.sourceName,
  ];

  static const List<String> _cryptoPriority = <String>[
    TetherlandPriceProvider.sourceName,
    NobitexPriceProvider.sourceName,
    ChandPriceProvider.sourceName,
    BonbastPriceProvider.sourceName,
  ];

  final Dio _dio;
  final List<PriceProvider> _providers;

  /// How long a snapshot is served from memory before it is fetched again.
  final Duration cacheTtl;

  /// Upper bound for one provider fetch inside a snapshot build.
  final Duration providerTimeout;

  MarketSnapshot? _cached;
  Future<MarketSnapshot>? _inFlight;
  int _epoch = 0;

  /// Returns the merged market snapshot.
  ///
  /// Serves the cached snapshot while it is younger than [cacheTtl]. Concurrent
  /// callers share one in-flight fetch. [forceRefresh] bypasses both the cache
  /// and an in-flight fetch.
  ///
  /// Throws a [ValidationException] with [noSourceMessage] only when every
  /// source failed and no cached snapshot exists.
  Future<MarketSnapshot> snapshot({bool forceRefresh = false}) {
    final cached = _cached;
    if (!forceRefresh && cached != null && _isFresh(cached)) {
      return Future<MarketSnapshot>.value(cached);
    }
    final inFlight = _inFlight;
    if (!forceRefresh && inFlight != null) return inFlight;

    final epoch = _epoch;
    late final Future<MarketSnapshot> fetch;
    fetch = _fetch(epoch).whenComplete(() {
      if (identical(_inFlight, fetch)) _inFlight = null;
    });
    _inFlight = fetch;
    return fetch;
  }

  /// Returns the current Rial price of one unit of an asset holding.
  ///
  /// [AssetKind.gold] is valued per gram of 18-karat gold, [AssetKind.silver]
  /// per gram of silver, and currencies/crypto by their [code]. Fiat and bullion
  /// prices use the source's sell side (falling back to its primary price);
  /// crypto uses the primary latest price.
  ///
  /// Throws a [ValidationException] when [kind] cannot be quoted at all, when
  /// [code] is missing or unsupported, or when the supported symbol is missing
  /// from two consecutive snapshots.
  Future<({Rial rate, DateTime updatedAt, String source})> quoteForAsset(
    AssetKind kind, {
    String? code,
  }) async {
    final target = _targetFor(kind, code);
    var snapshot = await this.snapshot();
    var quote = snapshot.quoteOf(target.kind, target.symbol);
    if (quote == null) {
      // A fresh snapshot may have skipped this symbol because its usual source
      // failed; one forced refresh usually fills the gap.
      snapshot = await this.snapshot(forceRefresh: true);
      quote = snapshot.quoteOf(target.kind, target.symbol);
    }
    if (quote == null) {
      throw ValidationException(
        'نرخ «${target.symbol}» از منابع بازار دریافت نشد. دوباره تلاش کن.',
        code: 'market_quote_unavailable',
        debugDetail: 'symbol ${target.symbol} absent from market snapshot',
      );
    }
    final rate = quote.kind == MarketAssetKind.crypto
        ? quote.priceRial
        : quote.sellRial ?? quote.priceRial;
    if (rate.value <= 0) {
      throw ValidationException(
        'نرخ «${target.symbol}» معتبر نیست. دوباره تلاش کن.',
        code: 'market_quote_invalid',
        debugDetail: 'non-positive rate for ${target.symbol}',
      );
    }
    return (rate: rate, updatedAt: quote.updatedAt, source: quote.source);
  }

  /// True when [kind] (with [code] for currency/crypto holdings) is expected to
  /// be quotable by this subsystem.
  bool supports(AssetKind kind, String? code) {
    switch (kind) {
      case AssetKind.gold:
      case AssetKind.silver:
        return true;
      case AssetKind.currency:
        final symbol = _normalizeCode(code);
        return symbol != null && supportedFiatSymbols.contains(symbol);
      case AssetKind.crypto:
        final symbol = _normalizeCode(code);
        return symbol != null && supportedCryptoSymbols.contains(symbol);
    }
  }

  /// Drops the cached snapshot and makes the next call fetch again.
  ///
  /// A fetch that is already running is allowed to finish for its callers but
  /// will no longer be cached.
  void invalidate() {
    _cached = null;
    _inFlight = null;
    _epoch++;
  }

  bool _isFresh(MarketSnapshot snapshot) {
    if (cacheTtl <= Duration.zero) return false;
    final age = DateTime.now().toUtc().difference(snapshot.fetchedAt);
    return age < cacheTtl;
  }

  Future<MarketSnapshot> _fetch(int epoch) async {
    final fetchedAt = DateTime.now().toUtc();
    final direct = _providers
        .where((provider) => provider is! DerivedPriceProvider)
        .toList(growable: false);
    final derived = _providers.whereType<DerivedPriceProvider>().toList(
      growable: false,
    );

    final outcomes = await Future.wait(direct.map(_fetchOne));
    var merged = _merge(outcomes);
    if (merged.isEmpty) {
      final cached = _cached;
      if (cached != null) return cached;
      throw const ValidationException(
        noSourceMessage,
        code: 'market_sources_unavailable',
        debugDetail: 'every market source failed and no cached snapshot exists',
      );
    }
    final statuses = outcomes
        .map((outcome) => outcome.status)
        .toList(growable: true);

    if (derived.isNotEmpty) {
      final interim = MarketSnapshot(
        quotes: merged,
        fetchedAt: fetchedAt,
        sources: List<MarketSourceStatus>.of(statuses),
      );
      final derivedOutcomes = await Future.wait(
        derived.map((provider) => _deriveOne(provider, interim)),
      );
      final byKey = <String, MarketQuote>{
        for (final quote in merged) _keyOf(quote): quote,
      };
      for (final outcome in derivedOutcomes) {
        for (final quote in outcome.quotes) {
          if (quote.priceRial.value > 0) {
            byKey[_keyOf(quote)] = quote;
          }
        }
        statuses.add(outcome.status);
      }
      merged = _sortQuotes(byKey.values);
    }

    final snapshot = MarketSnapshot(
      quotes: merged,
      fetchedAt: fetchedAt,
      sources: List<MarketSourceStatus>.unmodifiable(statuses),
    );
    if (epoch == _epoch) _cached = snapshot;
    return snapshot;
  }

  Future<_SourceOutcome> _deriveOne(
    DerivedPriceProvider provider,
    MarketSnapshot merged,
  ) async {
    try {
      final quotes = await provider
          .derive(_dio, merged)
          .timeout(providerTimeout);
      return _SourceOutcome(
        quotes,
        MarketSourceStatus(
          source: provider.name,
          ok: quotes.isNotEmpty,
          quoteCount: quotes.length,
          error: quotes.isEmpty ? 'نرخی از ${provider.name} دریافت نشد.' : null,
        ),
      );
    } on TimeoutException {
      return _SourceOutcome(
        const <MarketQuote>[],
        MarketSourceStatus(
          source: provider.name,
          ok: false,
          quoteCount: 0,
          error: 'مهلت دریافت نرخ از ${provider.name} تمام شد.',
        ),
      );
    } on AppException catch (error) {
      return _SourceOutcome(
        const <MarketQuote>[],
        MarketSourceStatus(
          source: provider.name,
          ok: false,
          quoteCount: 0,
          error: error.message,
        ),
      );
    } on Object {
      return _SourceOutcome(
        const <MarketQuote>[],
        MarketSourceStatus(
          source: provider.name,
          ok: false,
          quoteCount: 0,
          error: 'دریافت نرخ از ${provider.name} انجام نشد.',
        ),
      );
    }
  }

  Future<_SourceOutcome> _fetchOne(PriceProvider provider) async {
    try {
      final quotes = await provider.fetch(_dio).timeout(providerTimeout);
      return _SourceOutcome(
        quotes,
        MarketSourceStatus(
          source: provider.name,
          ok: true,
          quoteCount: quotes.length,
        ),
      );
    } on TimeoutException {
      return _SourceOutcome(
        const <MarketQuote>[],
        MarketSourceStatus(
          source: provider.name,
          ok: false,
          quoteCount: 0,
          error: 'مهلت دریافت نرخ از ${provider.name} تمام شد.',
        ),
      );
    } on AppException catch (error) {
      return _SourceOutcome(
        const <MarketQuote>[],
        MarketSourceStatus(
          source: provider.name,
          ok: false,
          quoteCount: 0,
          error: error.message,
        ),
      );
    } on Object {
      return _SourceOutcome(
        const <MarketQuote>[],
        MarketSourceStatus(
          source: provider.name,
          ok: false,
          quoteCount: 0,
          error: 'دریافت نرخ از ${provider.name} انجام نشد.',
        ),
      );
    }
  }

  /// Merges provider outcomes by the fixed per-kind source priority.
  static List<MarketQuote> _merge(List<_SourceOutcome> outcomes) {
    final selected = <String, ({MarketQuote quote, int rank})>{};
    for (var index = 0; index < outcomes.length; index++) {
      for (final quote in outcomes[index].quotes) {
        if (quote.priceRial.value <= 0) continue;
        final key = '${quote.kind.name}:${quote.symbol.toUpperCase()}';
        final rank = _rankFor(quote.kind, quote.source, index);
        final current = selected[key];
        if (current == null || rank < current.rank) {
          selected[key] = (quote: quote, rank: rank);
        }
      }
    }
    return _sortQuotes(selected.values.map((entry) => entry.quote));
  }

  static String _keyOf(MarketQuote quote) =>
      '${quote.kind.name}:${quote.symbol.toUpperCase()}';

  static List<MarketQuote> _sortQuotes(Iterable<MarketQuote> quotes) {
    final sorted = List<MarketQuote>.of(quotes)
      ..sort((a, b) {
        final byKind = a.kind.index.compareTo(b.kind.index);
        if (byKind != 0) return byKind;
        return a.symbol.compareTo(b.symbol);
      });
    return sorted;
  }

  static int _rankFor(MarketAssetKind kind, String source, int providerIndex) {
    final priority = switch (kind) {
      MarketAssetKind.crypto => _cryptoPriority,
      _ => _bullionPriority,
    };
    final rank = priority.indexOf(source);
    if (rank >= 0) return rank;
    // Unknown sources (custom provider lists in tests or future feeds) rank
    // after the known ones, in provider declaration order.
    return priority.length + providerIndex;
  }

  static ({MarketAssetKind kind, String symbol}) _targetFor(
    AssetKind kind,
    String? code,
  ) {
    switch (kind) {
      case AssetKind.gold:
        return (kind: MarketAssetKind.goldGram, symbol: goldGramSymbol);
      case AssetKind.silver:
        return (kind: MarketAssetKind.silver, symbol: silverSymbol);
      case AssetKind.currency:
        final symbol = _normalizeCode(code);
        if (symbol == null) {
          throw const ValidationException(
            'اول ارز را انتخاب کن تا نرخش را بگیرم.',
            code: 'market_currency_required',
            debugDetail: 'currency code is missing',
          );
        }
        if (!supportedFiatSymbols.contains(symbol)) {
          throw ValidationException(
            'ارز «$symbol» پشتیبانی نمی‌شود. '
            'کدهای پشتیبانی‌شده: ${supportedFiatSymbols.join('، ')}',
            code: 'market_currency_unsupported',
            debugDetail: 'unsupported currency $symbol',
          );
        }
        return (kind: MarketAssetKind.fiat, symbol: symbol);
      case AssetKind.crypto:
        final symbol = _normalizeCode(code);
        if (symbol == null) {
          throw const ValidationException(
            'اول رمزارز را انتخاب کن تا نرخش را بگیرم.',
            code: 'market_crypto_required',
            debugDetail: 'crypto symbol is missing',
          );
        }
        if (!supportedCryptoSymbols.contains(symbol)) {
          throw ValidationException(
            'رمز ارز «$symbol» پشتیبانی نمی‌شود. '
            'نمادهای پشتیبانی‌شده: ${supportedCryptoSymbols.join('، ')}',
            code: 'market_crypto_unsupported',
            debugDetail: 'unsupported crypto $symbol',
          );
        }
        return (kind: MarketAssetKind.crypto, symbol: symbol);
    }
  }

  static String? _normalizeCode(String? code) {
    final normalized = code?.trim().toUpperCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

/// One provider's contribution to a snapshot build.
final class _SourceOutcome {
  const _SourceOutcome(this.quotes, this.status);

  final List<MarketQuote> quotes;
  final MarketSourceStatus status;
}
