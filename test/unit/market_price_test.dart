// Tests for the market price subsystem.
//
// Fixtures under test/fixtures/market/:
//   * bonbast_page.html, bonbast.json, chand.json are real payloads captured
//     on 2026-11-27 with curl from https://bonbast.com/ and
//     https://hansha.online/latest. The page is trimmed to the script block
//     that carries the rate token; the Chand array is trimmed to its first two
//     price snapshots per item. Both endpoints are reachable from this machine.
//   * nobitex.json, tetherland_usdt.json and tetherland_currencies.json are
//     hand-crafted from the Go structs in FC_Scraper
//     internal/providers/{nobitex,tetherland}.go, because api.nobitex.ir,
//     api.tetherland.com and service.tetherland.com do not resolve from this
//     machine (`curl: (6) Could not resolve host`).
//
// No test performs network I/O: parsing is exercised through the pure static
// parse functions, provider HTTP flow through a Dio interceptor that resolves
// fixture bodies, and the service through injected fake providers.

import 'dart:io';

import 'package:daram/core/errors/app_exception.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/features/assets/domain/asset_quantity.dart';
import 'package:daram/features/market/data/bonbast_price_provider.dart';
import 'package:daram/features/market/data/chand_price_provider.dart';
import 'package:daram/features/market/data/market_price_service.dart';
import 'package:daram/features/market/data/nobitex_price_provider.dart';
import 'package:daram/features/market/data/price_provider.dart';
import 'package:daram/features/market/data/silver_spot_provider.dart';
import 'package:daram/features/market/data/tetherland_price_provider.dart';
import 'package:daram/features/market/domain/market_quote.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BonbastPriceProvider', () {
    test('extracts the rate token and the session cookie from the page', () {
      final token = BonbastPriceProvider.extractToken(
        _fixture('bonbast_page.html'),
      );
      expect(token.split(','), hasLength(3));
      expect(token, contains('2026-11-27'));

      expect(
        BonbastPriceProvider.extractSessionCookie(<String>[
          'st_bb=0; Domain=bonbast.com; Path=/',
        ]),
        'st_bb=0',
      );
      expect(
        BonbastPriceProvider.extractSessionCookie(<String>['st_bb=1; Path=/']),
        'st_bb=1',
      );
      expect(BonbastPriceProvider.extractSessionCookie(null), 'st_bb=0');
      expect(
        BonbastPriceProvider.extractSessionCookie(const <String>['foo=bar']),
        'st_bb=0',
      );
    });

    test('parses the captured payload into Toman-to-Rial quotes', () {
      final quotes = BonbastPriceProvider.parseBody(_fixture('bonbast.json'));

      // 28 fiat + 5 coins + 2 gold weights + derived bitcoin.
      expect(quotes, hasLength(36));
      expect(quotes.every((quote) => quote.source == 'Bonbast'), isTrue);

      final usd = _quoteOf(quotes, MarketAssetKind.fiat, 'USD');
      expect(usd.priceRial, Rial(2932000)); // 293,200 Toman sell
      expect(usd.sellRial, Rial(2932000));
      expect(usd.buyRial, Rial(2930000)); // 293,000 Toman buy

      // Bonbast quotes AMD and JPY per ten units and IQD per one hundred.
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'AMD').priceRial,
        Rial(8145),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'JPY').priceRial,
        Rial(18400),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'IQD').priceRial,
        Rial(1935),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'EUR').priceRial,
        Rial(3217000),
      );

      final gram = _quoteOf(quotes, MarketAssetKind.goldGram, 'GOL18');
      expect(gram.priceRial, Rial(260284400)); // 26,028,440 Toman/gram
      expect(
        _quoteOf(quotes, MarketAssetKind.goldGram, 'MITHQAL').priceRial,
        Rial(1127500000),
      );

      final azadi = _quoteOf(quotes, MarketAssetKind.goldCoin, 'AZADI');
      expect(azadi.priceRial, Rial(2550000000));
      expect(azadi.sellRial, Rial(2550000000));
      expect(azadi.buyRial, Rial(2500000000));
      expect(
        _quoteOf(quotes, MarketAssetKind.goldCoin, 'EMAMI').priceRial,
        Rial(2650000000),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.goldCoin, 'AZADI_HALF').priceRial,
        Rial(1430000000),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.goldCoin, 'AZADI_QUARTER').priceRial,
        Rial(790000000),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.goldCoin, 'GERAMI').priceRial,
        Rial(380000000),
      );

      // bitcoin = 61,658.41 USD * 293,200 Toman/USD, in Rial.
      final bitcoin = _quoteOf(quotes, MarketAssetKind.crypto, 'BTC');
      expect(bitcoin.priceRial, Rial(180782458120));

      // last_modified is UTC wall-clock time (no zone in the payload).
      final expected = DateTime.utc(2026, 11, 27, 8, 51);
      expect(usd.updatedAt, expected);
      expect(gram.updatedAt, expected);
      expect(bitcoin.updatedAt, expected);
    });

    test('rounds sub-unit quotes half up and falls back to the fetch time', () {
      final fetchedAt = DateTime.utc(2026, 11, 27, 10);
      final quotes = BonbastPriceProvider.parseBody(
        '{"usd1":"293200","usd2":"293000","iqd1":"19355",'
        '"amd1":"8145","jpy1":"18400"}',
        fetchedAt: fetchedAt,
      );
      // 19,355 Toman per 100 IQD = 1,935.5 Rial per IQD -> 1,936.
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'IQD').sellRial,
        Rial(1936),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'USD').updatedAt,
        fetchedAt,
      );
    });

    test('throws when the payload has no usable quote', () {
      expect(
        () => BonbastPriceProvider.parseBody('{}'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => BonbastPriceProvider.parseBody('<html>challenge</html>'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fetch posts the extracted token with browser-like headers', () async {
      final page = _fixture('bonbast_page.html');
      final body = _fixture('bonbast.json');
      RequestOptions? pageRequest;
      RequestOptions? jsonRequest;
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'GET') {
              pageRequest = options;
              handler.resolve(
                Response<String>(
                  requestOptions: options,
                  statusCode: 200,
                  data: page,
                  headers: Headers.fromMap(<String, List<String>>{
                    'set-cookie': <String>[
                      'st_bb=0; Domain=bonbast.com; Path=/',
                    ],
                  }),
                ),
              );
              return;
            }
            jsonRequest = options;
            handler.resolve(
              Response<String>(
                requestOptions: options,
                statusCode: 200,
                data: body,
              ),
            );
          },
        ),
      );

      final quotes = await const BonbastPriceProvider().fetch(dio);

      expect(quotes, hasLength(36));
      expect(pageRequest, isNotNull);
      expect(_header(pageRequest!.headers, 'User-Agent'), contains('Android'));
      expect(jsonRequest, isNotNull);
      expect(jsonRequest!.uri.toString(), BonbastPriceProvider.jsonUrl);
      final form = jsonRequest!.data;
      expect(form, isA<Map<Object?, Object?>>());
      expect(
        (form as Map<Object?, Object?>)['param'],
        BonbastPriceProvider.extractToken(page),
      );
      expect(_header(jsonRequest!.headers, 'Cookie'), 'st_bb=0');
      expect(
        _header(jsonRequest!.headers, 'X-Requested-With'),
        'XMLHttpRequest',
      );
      expect(_header(jsonRequest!.headers, 'Origin'), 'https://bonbast.com');
      expect(_header(jsonRequest!.headers, 'Referer'), 'https://bonbast.com/');
    });

    test('fetch reports network failures and token-less pages', () async {
      final offline = Dio();
      addTearDown(offline.close);
      offline.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'offline',
              ),
            );
          },
        ),
      );
      await expectLater(
        const BonbastPriceProvider().fetch(offline),
        throwsA(isA<ValidationException>()),
      );

      final challenged = Dio();
      addTearDown(challenged.close);
      challenged.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<String>(
                requestOptions: options,
                statusCode: 200,
                data: '<html>no token here</html>',
              ),
            );
          },
        ),
      );
      await expectLater(
        const BonbastPriceProvider().fetch(challenged),
        throwsA(isA<ValidationException>()),
      );
    });

    test('parses last_modified values and rejects malformed ones', () {
      expect(
        BonbastPriceProvider.parseLastModified('November 27, 2026 08:51'),
        DateTime.utc(2026, 11, 27, 8, 51),
      );
      expect(
        BonbastPriceProvider.parseLastModified('November 27, 2026 00:05'),
        DateTime.utc(2026, 11, 27, 0, 5),
      );
      expect(
        BonbastPriceProvider.parseLastModified('November 27, 2026 24:00'),
        isNull,
      );
      expect(BonbastPriceProvider.parseLastModified('not a timestamp'), isNull);
      expect(BonbastPriceProvider.parseLastModified(null), isNull);
    });
  });

  group('ChandPriceProvider', () {
    test('parses the captured feed into canonical quotes', () {
      final quotes = ChandPriceProvider.parseBody(_fixture('chand.json'));

      // 28 fiat + 6 supported crypto (BCH/EOS are outside the catalog) +
      // 5 coins + gram/mithqal.
      expect(quotes, hasLength(41));
      expect(quotes.every((quote) => quote.source == 'Chand'), isTrue);

      final usd = _quoteOf(quotes, MarketAssetKind.fiat, 'USD');
      expect(usd.priceRial, Rial(2932000));
      expect(usd.sellRial, Rial(2932000));
      expect(usd.buyRial, Rial(2930000));
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'AMD').priceRial,
        Rial(8145),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'JPY').priceRial,
        Rial(18400),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.fiat, 'IQD').priceRial,
        Rial(1935),
      );

      final gram = _quoteOf(quotes, MarketAssetKind.goldGram, 'GOL18');
      expect(gram.priceRial, Rial(260099700));
      expect(
        _quoteOf(quotes, MarketAssetKind.goldGram, 'MITHQAL').priceRial,
        Rial(1126700000),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.goldCoin, 'AZADI').priceRial,
        Rial(2550000000),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.goldCoin, 'AZADI_HALF').priceRial,
        Rial(1430000000),
      );

      final bitcoin = _quoteOf(quotes, MarketAssetKind.crypto, 'BTC');
      expect(bitcoin.priceRial, Rial(183849910000));
      expect(
        quotes.any((quote) => quote.symbol == 'BCH' || quote.symbol == 'EOS'),
        isFalse,
      );

      final expected = DateTime.utc(2026, 11, 27, 8, 47, 53);
      expect(usd.updatedAt, expected);
      expect(bitcoin.updatedAt, expected);
    });

    test('throws a descriptive exception for malformed or empty payloads', () {
      expect(
        () => ChandPriceProvider.parseBody('{"ab":"usd"}'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ChandPriceProvider.parseBody('[]'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ChandPriceProvider.parseBody('[{"ab":"usd","ps":[]}]'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ChandPriceProvider.parseBody('<html>maintenance</html>'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fetch reads the latest endpoint and parses it', () async {
      RequestOptions? request;
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            request = options;
            handler.resolve(
              Response<String>(
                requestOptions: options,
                statusCode: 200,
                data: _fixture('chand.json'),
              ),
            );
          },
        ),
      );
      final quotes = await const ChandPriceProvider().fetch(dio);
      expect(quotes, hasLength(41));
      expect(request!.uri.toString(), ChandPriceProvider.latestUrl);
      expect(_header(request!.headers, 'Accept'), contains('json'));
    });
  });

  group('NobitexPriceProvider', () {
    test('parses rls market stats into Rial quotes', () {
      final fetchedAt = DateTime.utc(2026, 11, 27, 9);
      final quotes = NobitexPriceProvider.parseBody(
        _fixture('nobitex.json'),
        fetchedAt: fetchedAt,
      );

      // DOGE has zero prices and SOL has non-numeric prices: both are skipped.
      expect(quotes, hasLength(4));
      expect(quotes.every((quote) => quote.source == 'Nobitex'), isTrue);

      final bitcoin = _quoteOf(quotes, MarketAssetKind.crypto, 'BTC');
      expect(bitcoin.priceRial, Rial(183950000000));
      expect(bitcoin.sellRial, Rial(184040000000));
      expect(bitcoin.buyRial, Rial(183860000000));
      expect(bitcoin.updatedAt, fetchedAt);

      expect(
        _quoteOf(quotes, MarketAssetKind.crypto, 'USDT').priceRial,
        Rial(2932000),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.crypto, 'ETH').priceRial,
        Rial(5150000000),
      );
      expect(
        _quoteOf(quotes, MarketAssetKind.crypto, 'XRP').priceRial,
        Rial(291000),
      );
      expect(
        quotes.any((quote) => quote.symbol == 'DOGE' || quote.symbol == 'SOL'),
        isFalse,
      );
    });

    test('throws when the API reports an error or malformed payload', () {
      expect(
        () => NobitexPriceProvider.parseBody('{"status":"error","stats":{}}'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => NobitexPriceProvider.parseBody('{"status":"ok","stats":[]}'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => NobitexPriceProvider.parseBody('{"status":"ok","stats":{}}'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => NobitexPriceProvider.parseBody('not json'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('TetherlandPriceProvider', () {
    test('parses the USDT price and derives the other coins', () {
      final fetchedAt = DateTime.utc(2026, 11, 27, 9);
      final usdt = TetherlandPriceProvider.parseUsdtBody(
        _fixture('tetherland_usdt.json'),
        fetchedAt: fetchedAt,
      );
      expect(usdt.symbol, 'USDT');
      expect(usdt.priceRial, Rial(2930500)); // 293,050 Toman
      expect(usdt.source, 'Tetherland');
      expect(usdt.updatedAt, fetchedAt);

      final quotes = TetherlandPriceProvider.parseCurrenciesBody(
        _fixture('tetherland_currencies.json'),
        usdtRial: usdt.priceRial.value,
        fetchedAt: fetchedAt,
      );
      // USDT is fetched from the legacy endpoint and BCH/XYZ are outside the
      // supported crypto catalog.
      expect(quotes, hasLength(3));

      final bitcoin = _quoteOf(quotes, MarketAssetKind.crypto, 'BTC');
      expect(bitcoin.priceRial, Rial(180710000000)); // toman_amount * 10
      // ETH has no toman_amount: 1,985.30 USD * 2,930,500 Rial/USDT.
      expect(
        _quoteOf(quotes, MarketAssetKind.crypto, 'ETH').priceRial,
        Rial(5817921650),
      );
      // DOGE has no toman_amount: 0.15 USD * 2,930,500 Rial/USDT.
      expect(
        _quoteOf(quotes, MarketAssetKind.crypto, 'DOGE').priceRial,
        Rial(439575),
      );
      expect(quotes.any((quote) => quote.symbol == 'USDT'), isFalse);
      expect(quotes.any((quote) => quote.symbol == 'BCH'), isFalse);
    });

    test('skips price fallback when the USDT factor is unknown', () {
      final quotes = TetherlandPriceProvider.parseCurrenciesBody(
        _fixture('tetherland_currencies.json'),
      );
      expect(quotes, hasLength(1));
      expect(quotes.single.symbol, 'BTC');
    });

    test('throws a descriptive exception for malformed payloads', () {
      expect(
        () => TetherlandPriceProvider.parseUsdtBody('{"data":{}}'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => TetherlandPriceProvider.parseCurrenciesBody('not json'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => TetherlandPriceProvider.parseCurrenciesBody('{"data":[]}'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('MarketPriceService', () {
    test('merges sources by priority and records per-source status', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final bonbast = _FakeProvider('Bonbast', <MarketQuote>[
        _quote(symbol: 'USD', rial: 2900000, sell: 2900000),
        _quote(
          symbol: 'GOL18',
          kind: MarketAssetKind.goldGram,
          rial: 260000000,
        ),
        _quote(symbol: 'BTC', kind: MarketAssetKind.crypto, rial: 100),
      ]);
      final chand = _FakeProvider('Chand', <MarketQuote>[
        _quote(symbol: 'USD', rial: 2950000, sell: 2950000),
        _quote(
          symbol: 'GOL18',
          kind: MarketAssetKind.goldGram,
          rial: 270000000,
        ),
        _quote(symbol: 'BTC', kind: MarketAssetKind.crypto, rial: 200),
      ]);
      final nobitex = _FakeProvider('Nobitex', <MarketQuote>[
        _quote(symbol: 'BTC', kind: MarketAssetKind.crypto, rial: 300),
      ]);
      final tetherland = _FakeProvider('Tetherland', <MarketQuote>[
        _quote(symbol: 'BTC', kind: MarketAssetKind.crypto, rial: 400),
      ]);
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[bonbast, chand, nobitex, tetherland],
      );

      final snapshot = await service.snapshot();

      // Fiat and gold prefer Bonbast; crypto prefers Tetherland.
      expect(
        snapshot.quoteOf(MarketAssetKind.fiat, 'USD')!.priceRial,
        Rial(2900000),
      );
      expect(
        snapshot.quoteOf(MarketAssetKind.goldGram, 'GOL18')!.priceRial,
        Rial(260000000),
      );
      expect(snapshot.quote('BTC')!.priceRial, Rial(400));
      expect(snapshot.quote('btc'), isNotNull);

      expect(snapshot.sources, hasLength(4));
      expect(snapshot.sources.every((source) => source.ok), isTrue);
      expect(snapshot.sources.map((source) => source.source), <String>[
        'Bonbast',
        'Chand',
        'Nobitex',
        'Tetherland',
      ]);
      expect(snapshot.fetchedAt.isUtc, isTrue);

      // Quotes are ordered by kind, then symbol.
      final kinds = snapshot.quotes.map((quote) => quote.kind.index).toList();
      final sorted = List<int>.of(kinds)..sort();
      expect(kinds, sorted);
    });

    test('falls back to the next source when higher ones fail', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final brokenTetherland = _FakeProvider(
        'Tetherland',
        <MarketQuote>[],
        failure: const ValidationException('tetherland down'),
      );
      final brokenNobitex = _FakeProvider(
        'Nobitex',
        <MarketQuote>[],
        failure: const ValidationException('nobitex down'),
      );
      final chand = _FakeProvider('Chand', <MarketQuote>[
        _quote(symbol: 'BTC', kind: MarketAssetKind.crypto, rial: 200),
      ]);
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[brokenTetherland, brokenNobitex, chand],
      );

      final snapshot = await service.snapshot();
      expect(snapshot.quote('BTC')!.priceRial, Rial(200));
      expect(snapshot.quote('BTC')!.source, 'Chand');
      final failed = snapshot.sources.where((source) => !source.ok).toList();
      expect(failed, hasLength(2));
      expect(failed.every((source) => source.error != null), isTrue);
      expect(failed.every((source) => source.quoteCount == 0), isTrue);
    });

    test(
      'caches the snapshot and honours forceRefresh and invalidate',
      () async {
        final dio = Dio();
        addTearDown(dio.close);
        final provider = _FakeProvider('Bonbast', <MarketQuote>[
          _quote(symbol: 'USD', rial: 2900000),
        ]);
        final service = MarketPriceService(
          dio,
          providers: <PriceProvider>[provider],
        );

        await service.snapshot();
        expect(provider.calls, 1);
        await service.snapshot();
        expect(provider.calls, 1);

        await service.snapshot(forceRefresh: true);
        expect(provider.calls, 2);

        service.invalidate();
        await service.snapshot();
        expect(provider.calls, 3);

        final expired = MarketPriceService(
          dio,
          cacheTtl: Duration.zero,
          providers: <PriceProvider>[provider],
        );
        await expired.snapshot();
        await expired.snapshot();
        expect(provider.calls, 5);
      },
    );

    test('shares one in-flight fetch between concurrent callers', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final provider = _FakeProvider('Bonbast', <MarketQuote>[
        _quote(symbol: 'USD', rial: 2900000),
      ], delay: const Duration(milliseconds: 20));
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[provider],
      );

      final results = await Future.wait(<Future<MarketSnapshot>>[
        service.snapshot(),
        service.snapshot(),
      ]);
      expect(provider.calls, 1);
      expect(identical(results[0], results[1]), isTrue);
    });

    test('serves the stale snapshot when every source fails', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final provider = _FakeProvider('Bonbast', <MarketQuote>[
        _quote(symbol: 'USD', rial: 2900000),
      ]);
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[provider],
      );
      final first = await service.snapshot();

      provider.failure = const ValidationException('offline');
      provider.quotes = const <MarketQuote>[];
      final stale = await service.snapshot(forceRefresh: true);

      expect(identical(stale, first), isTrue);
      expect(provider.calls, 2);
    });

    test('throws the documented exception when nothing is available', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final provider = _FakeProvider(
        'Bonbast',
        <MarketQuote>[],
        failure: const ValidationException('offline'),
      );
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[provider],
      );

      await expectLater(
        service.snapshot(),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            'دریافت نرخ از منابع بازار ممکن نشد. اتصال اینترنت را بررسی کن.',
          ),
        ),
      );
    });

    test('times out a slow source without failing the snapshot', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final slow = _FakeProvider(
        'Chand',
        <MarketQuote>[],
        delay: const Duration(milliseconds: 150),
      );
      final fast = _FakeProvider('Bonbast', <MarketQuote>[
        _quote(symbol: 'USD', rial: 2900000),
      ]);
      final service = MarketPriceService(
        dio,
        providerTimeout: const Duration(milliseconds: 20),
        providers: <PriceProvider>[fast, slow],
      );

      final snapshot = await service.snapshot();
      expect(snapshot.quote('USD'), isNotNull);
      final timedOut = snapshot.sources
          .where((source) => source.source == 'Chand')
          .single;
      expect(timedOut.ok, isFalse);
      expect(timedOut.error, contains('مهلت'));
      // Let the abandoned delayed future finish before the test ends.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });

    test('quoteForAsset maps assets and picks the right price side', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final provider = _FakeProvider('Bonbast', <MarketQuote>[
        _quote(symbol: 'USD', rial: 2930000, sell: 2932000, buy: 2928000),
        _quote(
          symbol: 'GOL18',
          kind: MarketAssetKind.goldGram,
          rial: 260284400,
          sell: 260284400,
          buy: 260000000,
        ),
        _quote(symbol: 'XAG', kind: MarketAssetKind.silver, rial: 346863018),
        _quote(
          symbol: 'BTC',
          kind: MarketAssetKind.crypto,
          rial: 180782458120,
          sell: 181000000000,
        ),
      ]);
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[provider],
      );

      final gold = await service.quoteForAsset(AssetKind.gold);
      expect(gold.rate, Rial(260284400));
      expect(gold.source, 'Bonbast');
      expect(gold.updatedAt.isUtc, isTrue);

      final silver = await service.quoteForAsset(AssetKind.silver);
      expect(silver.rate, Rial(346863018));

      final usd = await service.quoteForAsset(AssetKind.currency, code: 'usd');
      expect(usd.rate, Rial(2932000)); // sell side for fiat

      final bitcoin = await service.quoteForAsset(
        AssetKind.crypto,
        code: 'btc',
      );
      expect(bitcoin.rate, Rial(180782458120)); // latest price for crypto

      // The cached snapshot is reused for further lookups.
      await service.quoteForAsset(AssetKind.currency, code: 'USD');
      expect(provider.calls, 1);
    });

    test('supports reports the quotable symbols', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[
          _FakeProvider('Bonbast', <MarketQuote>[
            _quote(symbol: 'USD', rial: 2900000),
          ]),
        ],
      );

      expect(service.supports(AssetKind.gold, null), isTrue);
      expect(service.supports(AssetKind.silver, null), isTrue);
      expect(service.supports(AssetKind.currency, 'USD'), isTrue);
      expect(service.supports(AssetKind.currency, 'usd'), isTrue);
      expect(service.supports(AssetKind.currency, 'ZZZ'), isFalse);
      expect(service.supports(AssetKind.currency, null), isFalse);
      expect(service.supports(AssetKind.crypto, 'BTC'), isTrue);
      expect(service.supports(AssetKind.crypto, 'BCH'), isFalse);
      expect(MarketPriceService.supportedFiatSymbols, contains('USD'));
      expect(MarketPriceService.supportedCryptoSymbols, contains('BTC'));
    });

    test(
      'quoteForAsset rejects unsupported symbols with a Persian message',
      () async {
        final dio = Dio();
        addTearDown(dio.close);
        final service = MarketPriceService(
          dio,
          providers: <PriceProvider>[
            _FakeProvider('Bonbast', <MarketQuote>[
              _quote(symbol: 'USD', rial: 2900000),
            ]),
          ],
        );

        await expectLater(
          service.quoteForAsset(AssetKind.currency, code: 'ZZZ'),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              allOf(contains('ZZZ'), contains('USD'), contains('پشتیبانی')),
            ),
          ),
        );
        await expectLater(
          service.quoteForAsset(AssetKind.crypto, code: 'BCH'),
          throwsA(
            isA<ValidationException>().having(
              (error) => error.message,
              'message',
              allOf(contains('BCH'), contains('BTC')),
            ),
          ),
        );
        await expectLater(
          service.quoteForAsset(AssetKind.currency),
          throwsA(isA<ValidationException>()),
        );
      },
    );

    test('quoteForAsset retries once when the symbol is missing', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final provider = _FakeProvider('Bonbast', <MarketQuote>[
        _quote(symbol: 'USD', rial: 2900000),
      ]);
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[provider],
      );

      await expectLater(
        service.quoteForAsset(AssetKind.currency, code: 'EUR'),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('EUR'),
          ),
        ),
      );
      expect(provider.calls, 2); // snapshot + one forced refresh
    });
  });

  group('MarketSnapshot', () {
    test('looks quotes up by symbol and by kind', () {
      final snapshot = MarketSnapshot(
        quotes: <MarketQuote>[
          _quote(symbol: 'USD', rial: 2900000),
          _quote(symbol: 'GOL18', kind: MarketAssetKind.goldGram, rial: 1),
        ],
        fetchedAt: DateTime.utc(2026, 11, 27),
        sources: const <MarketSourceStatus>[],
      );
      expect(snapshot.quote('usd')!.priceRial, Rial(2900000));
      expect(snapshot.quote('  USD '), isNotNull);
      expect(snapshot.quote('EUR'), isNull);
      expect(snapshot.quote(''), isNull);
      expect(snapshot.quoteOf(MarketAssetKind.goldGram, 'GOL18'), isNotNull);
      expect(snapshot.quoteOf(MarketAssetKind.fiat, 'GOL18'), isNull);
    });
  });
  group('SilverSpotProvider', () {
    test('parses the COMEX spot payload and converts it exactly', () {
      final spot = SilverSpotProvider.parseSpotBody(
        _fixture('yahoo_silver.json'),
      );
      expect(spot, isNotNull);
      expect(spot!.microUsd, 53420000); // 53.42 USD per troy ounce
      expect(spot.updatedAt, DateTime.utc(2026, 11, 27, 9, 15));

      // 53.42 USD/oz * 293,200 Toman/USD * 10 / 31.1034768 g/oz
      final rate = SilverSpotProvider.convertToRialPerGram(
        microUsdPerOunce: spot.microUsd,
        rialPerUsd: 2932000,
      );
      expect(rate, Rial(5035689));
    });

    test('returns no quote when the USD rate is missing', () async {
      final dio = Dio();
      addTearDown(dio.close);
      final merged = MarketSnapshot(
        quotes: const <MarketQuote>[],
        fetchedAt: DateTime.now().toUtc(),
        sources: const <MarketSourceStatus>[],
      );
      expect(await const SilverSpotProvider().derive(dio, merged), isEmpty);
    });

    test('the service merges the derived silver quote', () async {
      final dio = Dio();
      addTearDown(dio.close);
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response<String>(
                requestOptions: options,
                statusCode: 200,
                data: _fixture('yahoo_silver.json'),
              ),
            );
          },
        ),
      );
      final service = MarketPriceService(
        dio,
        providers: <PriceProvider>[
          _FakeProvider('Bonbast', <MarketQuote>[
            _quote(symbol: 'USD', rial: 2932000, sell: 2932000),
          ]),
          const SilverSpotProvider(),
        ],
      );
      final snapshot = await service.snapshot();
      final silver = snapshot.quoteOf(MarketAssetKind.silver, 'XAG');
      expect(silver, isNotNull);
      expect(silver!.source, 'Yahoo Finance');
      expect(silver.priceRial, Rial(5035689));
      final source = snapshot.sources
          .where((item) => item.source == 'Yahoo Finance')
          .single;
      expect(source.ok, isTrue);
      expect(source.quoteCount, 1);
    });
  });
}

/// Reads a fixture captured for the market tests.
String _fixture(String name) =>
    File('test/fixtures/market/$name').readAsStringSync();

/// Finds a quote by kind and symbol; fails the test when it is missing.
MarketQuote _quoteOf(
  List<MarketQuote> quotes,
  MarketAssetKind kind,
  String symbol,
) => quotes.firstWhere(
  (quote) => quote.kind == kind && quote.symbol == symbol,
  orElse: () => fail('missing $kind quote for $symbol'),
);

/// Builds a quote for service tests.
MarketQuote _quote({
  required String symbol,
  required int rial,
  MarketAssetKind kind = MarketAssetKind.fiat,
  int? buy,
  int? sell,
  String source = 'Bonbast',
  DateTime? updatedAt,
}) => MarketQuote(
  symbol: symbol,
  kind: kind,
  priceRial: Rial(rial),
  buyRial: buy == null ? null : Rial(buy),
  sellRial: sell == null ? null : Rial(sell),
  source: source,
  updatedAt: updatedAt ?? DateTime.utc(2026, 11, 27, 9),
);

/// Case-insensitive header lookup on a captured request.
Object? _header(Map<String, dynamic> headers, String name) {
  for (final entry in headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}

/// Fake provider used to test service orchestration without network access.
final class _FakeProvider implements PriceProvider {
  _FakeProvider(
    this.name,
    this.quotes, {
    this.failure,
    this.delay = Duration.zero,
  });

  @override
  final String name;

  List<MarketQuote> quotes;
  Object? failure;
  final Duration delay;
  int calls = 0;

  @override
  Future<List<MarketQuote>> fetch(Dio dio) async {
    calls += 1;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final error = failure;
    if (error != null) throw error;
    // Real providers stamp their own name on every quote; the fake does the
    // same so merge-priority tests exercise the source names, not the helper.
    return <MarketQuote>[
      for (final quote in quotes)
        MarketQuote(
          symbol: quote.symbol,
          kind: quote.kind,
          priceRial: quote.priceRial,
          buyRial: quote.buyRial,
          sellRial: quote.sellRial,
          source: name,
          updatedAt: quote.updatedAt,
        ),
    ];
  }
}
