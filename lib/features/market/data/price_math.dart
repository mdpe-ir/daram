import 'dart:convert';

import '../../../core/money/rial.dart';

/// An exact decimal parsed from a market payload.
///
/// Feeds publish prices as JSON strings, integers or floating point numbers.
/// Money must never be stored or manipulated as a `double`, so every number is
/// converted here into an integer numerator over a power-of-ten denominator and
/// only rounded once, at the very end, into integer Rial.
final class MarketDecimal {
  const MarketDecimal._(this.units, this.denominator);

  /// The decimal digits with the point removed (e.g. `8145` for `814.5`).
  final BigInt units;

  /// The power of ten those digits are divided by (e.g. `10` for `814.5`).
  final BigInt denominator;

  /// Parses [value] exactly, or returns `null` when it is not a positive
  /// finite decimal number.
  ///
  /// Accepted inputs are JSON integers, JSON doubles (through their shortest
  /// decimal representation), and strings, with optional thousands separators
  /// such as `1,234.5`.
  static MarketDecimal? tryParse(Object? value) {
    final String? text = switch (value) {
      int number => number.toString(),
      double number when number.isFinite => number.toString(),
      String string => string,
      _ => null,
    };
    if (text == null) return null;
    final normalized = text.replaceAll(',', '').replaceAll(' ', '').trim();
    final match = RegExp(r'^\+?(\d+)(?:\.(\d+))?$').firstMatch(normalized);
    if (match == null) return null;
    final whole = match.group(1)!;
    final fraction = match.group(2) ?? '';
    final units = BigInt.tryParse('$whole$fraction');
    if (units == null) return null;
    return MarketDecimal._(units, BigInt.from(10).pow(fraction.length));
  }

  /// True when the parsed value is strictly positive.
  bool get isPositive => units > BigInt.zero;

  /// Rounds `this * multiplier / divisor` half up to a positive integer.
  ///
  /// Returns `null` for non-positive values and for results that do not fit the
  /// integer [Rial] range, so one malformed number drops one quote instead of
  /// corrupting a whole snapshot.
  int? toIntHalfUp(BigInt multiplier, BigInt divisor) {
    if (!isPositive || multiplier <= BigInt.zero || divisor <= BigInt.zero) {
      return null;
    }
    final numerator = units * multiplier;
    final denominator = this.denominator * divisor;
    // round_half_up(n / d) = floor((2n + d) / 2d) for positive values.
    final rounded =
        (numerator * BigInt.two + denominator) ~/ (denominator * BigInt.two);
    if (rounded <= BigInt.zero ||
        rounded > BigInt.from(Rial.maxAbsoluteValue)) {
      return null;
    }
    return rounded.toInt();
  }
}

/// A [Rial] that is positive and inside the safe range, or `null`.
Rial? _rialOrNull(int? value) => value == null ? null : Rial(value);

/// Converts a Toman-denominated value to a [Rial] price for one unit.
///
/// [unitsPerQuote] is the number of units the source's Toman figure covers:
/// most currencies are quoted per one unit, while Bonbast quotes AMD and JPY per
/// ten units and IQD per one hundred units. The result is rounded half up once.
Rial? tomanToRial(Object? value, {int unitsPerQuote = 1}) {
  if (unitsPerQuote <= 0) return null;
  final decimal = MarketDecimal.tryParse(value);
  return _rialOrNull(
    decimal?.toIntHalfUp(BigInt.from(10), BigInt.from(unitsPerQuote)),
  );
}

/// Converts a value that is already denominated in Rial (Nobitex's `-rls`
/// markets) to a positive [Rial], rounding half up.
Rial? rialFromDecimal(Object? value) {
  final decimal = MarketDecimal.tryParse(value);
  return _rialOrNull(decimal?.toIntHalfUp(BigInt.one, BigInt.one));
}

/// Multiplies an exact decimal by a positive integer factor and rounds half up.
///
/// Used for derivations such as "USD price of one bitcoin times the Rial price
/// of one dollar".
Rial? multiplyDecimal(Object? value, int factor) {
  if (factor <= 0) return null;
  final decimal = MarketDecimal.tryParse(value);
  return _rialOrNull(decimal?.toIntHalfUp(BigInt.from(factor), BigInt.one));
}

/// Decodes a JSON object from [body], or returns `null` when the body is not a
/// JSON object.
Map<String, Object?>? decodeJsonObject(String body) {
  final decoded = _decode(body);
  if (decoded is! Map) return null;
  final map = <String, Object?>{};
  for (final entry in decoded.entries) {
    final key = entry.key;
    if (key is String) map[key] = entry.value;
  }
  return map;
}

/// Decodes a JSON array from [body], or returns `null` when the body is not a
/// JSON array.
List<Object?>? decodeJsonList(String body) {
  final decoded = _decode(body);
  if (decoded is! List) return null;
  return decoded;
}

Object? _decode(String body) {
  try {
    return jsonDecode(body);
  } on FormatException {
    return null;
  }
}
