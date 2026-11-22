import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';

enum AssetKind {
  gold('طلا'),
  silver('نقره'),
  currency('ارز'),
  crypto('رمز ارز');

  const AssetKind(this.label);

  final String label;

  /// Kinds that store an ISO/crypto code in `currencyCode`.
  bool get hasCode => this == AssetKind.currency || this == AssetKind.crypto;
}

/// Six decimal places of a gram, a currency unit or a coin, stored as an
/// integer.
final class AssetQuantity {
  const AssetQuantity._(this.micros);

  static const scale = 1000000;
  static const maxMicros = 9000000000000000;

  final int micros;

  factory AssetQuantity.fromMicros(int value) {
    if (value <= 0 || value > maxMicros) {
      throw const ValidationException('مقدار دارایی خارج از محدوده است.');
    }
    return AssetQuantity._(value);
  }

  static AssetQuantity? tryParse(String input) {
    final normalized = PersianDigits.toLatin(input.trim()).replaceAll(',', '');
    final match = RegExp(r'^(\d+)(?:\.(\d{1,6}))?$').firstMatch(normalized);
    if (match == null) return null;
    final whole = int.tryParse(match[1]!);
    if (whole == null || whole > maxMicros ~/ scale) return null;
    final fraction = int.parse((match[2] ?? '').padRight(6, '0'));
    final micros = whole * scale + fraction;
    if (micros <= 0 || micros > maxMicros) return null;
    return AssetQuantity._(micros);
  }

  String get decimal {
    final whole = micros ~/ scale;
    final fraction = (micros % scale)
        .toString()
        .padLeft(6, '0')
        .replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? '$whole' : '$whole.$fraction';
  }

  /// Rounds the estimated value to the nearest rial.
  Rial valueAt(Rial rate) {
    final rounded =
        (BigInt.from(micros) * BigInt.from(rate.value) +
            BigInt.from(scale ~/ 2)) ~/
        BigInt.from(scale);
    if (rounded > BigInt.from(Rial.maxAbsoluteValue)) {
      throw const ValidationException('ارزش دارایی بیش از حد بزرگ است.');
    }
    return Rial(rounded.toInt());
  }
}
