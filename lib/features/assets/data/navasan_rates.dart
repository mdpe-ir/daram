import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../domain/asset_quantity.dart';

typedef AssetQuote = ({Rial rate, DateTime updatedAt});

class NavasanRates {
  const NavasanRates(this._dio);

  final Dio _dio;

  // Published snapshots from HosseinOdd/Navasan-API. No secret or holding
  // details need to be sent.
  /// Crypto symbols published in the snapshot's fiat feed. Navasan only
  /// covers Bitcoin today; the picker hides the fetch button for the rest.
  static const _quotedCrypto = {'btc'};

  static bool quotedCryptoContains(String symbol) =>
      _quotedCrypto.contains(symbol);

  static const _base =
      'https://raw.githubusercontent.com/HosseinOdd/Navasan-API/main/data';
  static final _decimal = RegExp(r'^(\d{1,18})(?:\.(\d{1,15}))?$');

  Future<AssetQuote> fetch(AssetKind kind, {String? currencyCode}) async {
    final symbol = switch (kind) {
      AssetKind.gold => '18ayar',
      AssetKind.silver => 'xag',
      AssetKind.currency ||
      AssetKind.crypto => currencyCode?.trim().toLowerCase() ?? '',
    };
    if (kind == AssetKind.currency &&
        (!RegExp(r'^[a-z]{3}$').hasMatch(symbol) ||
            const {'irr', 'xag', 'xau'}.contains(symbol))) {
      throw const ValidationException('کد سه‌حرفی ارز خارجی را وارد کنید.');
    }
    if (kind == AssetKind.crypto && !quotedCryptoContains(symbol)) {
      throw const ValidationException('نوسان برای این رمزارز نرخی ندارد.');
    }

    final file = kind == AssetKind.gold ? 'gold' : 'fiat';
    final response = await _dio
        .get<String>(
          '$_base/$file.json',
          options: Options(responseType: ResponseType.plain),
        )
        .timeout(const Duration(seconds: 12));
    final Object? data;
    try {
      data = jsonDecode(response.data ?? '');
    } on FormatException {
      throw const ValidationException('پاسخ نوسان معتبر نیست.');
    }
    final entry = data is Map ? data[symbol] : null;
    if (entry is! Map) {
      throw const ValidationException('نوسان برای این نماد نرخی ندارد.');
    }
    final match = _decimal.firstMatch('${entry['value']}');
    final timestamp = int.tryParse('${entry['date']}');
    final latest = DateTime.now().toUtc().add(const Duration(minutes: 5));
    if (match == null ||
        timestamp == null ||
        timestamp <= 0 ||
        timestamp > latest.millisecondsSinceEpoch ~/ 1000) {
      throw const ValidationException('نرخ دریافتی از نوسان معتبر نیست.');
    }

    final fraction = match[2] ?? '';
    var numerator = BigInt.parse('${match[1]}$fraction') * BigInt.from(10);
    var denominator = BigInt.from(10).pow(fraction.length);
    if (kind == AssetKind.silver) {
      // The XAG quote is per troy ounce (31.1034768 grams).
      numerator *= BigInt.from(10000000);
      denominator *= BigInt.from(311034768);
    }
    final rate = (numerator + denominator ~/ BigInt.two) ~/ denominator;
    if (rate <= BigInt.zero || rate > BigInt.from(Rial.maxAbsoluteValue)) {
      throw const ValidationException(
        'نرخ دریافتی از نوسان خارج از محدوده است.',
      );
    }
    return (
      rate: Rial(rate.toInt()),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        timestamp * 1000,
        isUtc: true,
      ),
    );
  }
}
