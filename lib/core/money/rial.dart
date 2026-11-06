import 'package:meta/meta.dart';

/// The single, canonical representation of money in DARAM.
///
/// Monetary values are always stored as **integer Rial**. Floating point is
/// never used for money, and no arithmetic silently rounds.
@immutable
final class Rial implements Comparable<Rial> {
  const Rial._(this.value);

  /// Largest amount we accept, chosen to leave head-room below `2^63 - 1`
  /// so that a few additions can never wrap around silently.
  static const int maxAbsoluteValue = 900000000000000000; // 9e17 rial

  /// Zero rial.
  static const Rial zero = Rial._(0);

  /// The amount in Rial.
  final int value;

  /// Creates a rial amount, rejecting values that are not safely representable.
  factory Rial(int rial) {
    if (rial.abs() > maxAbsoluteValue) {
      throw MoneyException('مبلغ بیش از حد بزرگ است.');
    }
    return Rial._(rial);
  }

  /// Converts an integer Toman amount to Rial exactly (1 Toman = 10 Rial).
  ///
  /// The multiplication is checked: an amount that would overflow is rejected
  /// instead of wrapping around.
  factory Rial.fromToman(int toman) {
    if (toman.abs() > maxAbsoluteValue ~/ 10) {
      throw MoneyException('مبلغ بیش از حد بزرگ است.');
    }
    return Rial._(toman * 10);
  }

  /// Converts a possibly fractional Toman amount to Rial without rounding.
  ///
  /// The caller must already have decided that the fraction is meaningful
  /// (for example `1.5` million Toman). One decimal place of Toman equals one
  /// rial, so the conversion is exact for one fractional digit. More decimals
  /// are rejected rather than rounded.
  factory Rial.fromTomanExact(String toman) {
    final normalized = toman.trim().replaceAll(',', '');
    final match = RegExp(r'^(-?)(\d+)(?:\.(\d{1,1}))?$').firstMatch(normalized);
    if (match == null) {
      throw MoneyException('مبلغ تومانی نامعتبر است.');
    }
    final negative = match.group(1) == '-';
    final whole = int.parse(match.group(2)!);
    final fraction = match.group(3) ?? '0';
    final rial = whole * 10 + int.parse(fraction);
    return Rial(negative ? -rial : rial);
  }

  /// True when the amount is exactly zero.
  bool get isZero => value == 0;

  /// True when the amount is negative.
  bool get isNegative => value < 0;

  /// The absolute amount.
  Rial get abs => Rial._(value.abs());

  /// Negates the amount.
  Rial operator -() => Rial._(-value);

  /// Adds two amounts, rejecting overflow.
  Rial operator +(Rial other) {
    final result = value + other.value;
    if (result.abs() > maxAbsoluteValue) {
      throw MoneyException('حاصل جمع مبلغ بیش از حد بزرگ است.');
    }
    return Rial._(result);
  }

  /// Subtracts another amount, rejecting overflow.
  Rial operator -(Rial other) => this + (-other);

  /// Multiplies by a positive integer count (used for installments).
  Rial multiply(int factor) {
    if (factor < 0) {
      throw MoneyException('ضریب مبلغ نمی‌تواند منفی باشد.');
    }
    if (factor != 0 && value.abs() > maxAbsoluteValue ~/ factor) {
      throw MoneyException('حاصل ضرب مبلغ بیش از حد بزرگ است.');
    }
    return Rial._(value * factor);
  }

  /// Sum of a collection of amounts.
  static Rial sum(Iterable<Rial> amounts) =>
      amounts.fold(Rial.zero, (total, amount) => total + amount);

  /// Integer Toman value, truncating any rial remainder.
  ///
  /// Truncation is only used where a whole-Toman figure is explicitly wanted;
  /// formatting keeps the exact value.
  int toTomanTruncated() => value ~/ 10;

  @override
  int compareTo(Rial other) => value.compareTo(other.value);

  bool operator <(Rial other) => value < other.value;
  bool operator <=(Rial other) => value <= other.value;
  bool operator >(Rial other) => value > other.value;
  bool operator >=(Rial other) => value >= other.value;

  @override
  bool operator ==(Object other) => other is Rial && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value rial';
}

/// Raised when a monetary operation would be unsafe or invalid.
class MoneyException implements Exception {
  const MoneyException(this.message);
  final String message;

  @override
  String toString() => 'MoneyException: $message';
}
