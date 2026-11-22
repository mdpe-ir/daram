import 'package:daram/core/errors/app_exception.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/features/assets/data/navasan_rates.dart';
import 'package:daram/features/assets/domain/asset_quantity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses plain-text JSON and converts toman and ounces to rial per unit',
    () async {
      final dio = Dio();
      addTearDown(dio.close);
      final requests = <String>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            final file = request.uri.pathSegments.last;
            requests.add(file);
            handler.resolve(
              Response<String>(
                requestOptions: request,
                data: file == 'gold.json'
                    ? '{"18ayar":{"value":24000000,"date":1760000000}}'
                    : '{"usd":{"value":"245000.05","date":"1760000000"},'
                          '"xag":{"value":9331043.04,"date":1760000000}}',
              ),
            );
          },
        ),
      );
      final service = NavasanRates(dio);
      final gold = await service.fetch(AssetKind.gold);
      final silver = await service.fetch(AssetKind.silver);
      final currency = await service.fetch(
        AssetKind.currency,
        currencyCode: 'USD',
      );
      expect(gold.rate, Rial(240000000));
      expect(silver.rate, Rial(3000000));
      expect(currency.rate, Rial(2450001));
      expect(
        gold.updatedAt,
        DateTime.fromMillisecondsSinceEpoch(1760000000000, isUtc: true),
      );
      expect(requests, ['gold.json', 'fiat.json', 'fiat.json']);
      await expectLater(
        service.fetch(AssetKind.currency, currencyCode: 'ZZZ'),
        throwsA(isA<ValidationException>()),
      );
    },
  );
}
