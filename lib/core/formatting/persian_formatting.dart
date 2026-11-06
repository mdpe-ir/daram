import '../money/currency.dart';
import '../money/rial.dart';

/// Centralised Persian/English digit and money formatting helpers.
///
/// All monetary display goes through this class so that the rial/toman rule
/// (never mutate stored values when the display unit changes) is enforced in
/// one place.
class PersianDigits {
  const PersianDigits._();

  static const String persian = '۰۱۲۳۴۵۶۷۸۹';
  static const String arabic = '٠١٢٣٤٥٦٧٨٩';
  static const String latin = '0123456789';

  /// Converts every Persian and Arabic-Indic digit in [input] to ASCII.
  ///
  /// Also normalises the Arabic thousands separator and the Persian decimal
  /// separator so that numeric parsing has a single path.
  static String toLatin(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final faIndex = persian.indexOf(char);
      final arIndex = arabic.indexOf(char);
      if (faIndex != -1) {
        buffer.write(faIndex);
      } else if (arIndex != -1) {
        buffer.write(arIndex);
      } else if (char == '٬' || char == '،') {
        buffer.write(',');
      } else if (char == '٫') {
        buffer.write('.');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  /// Converts ASCII digits in [input] to Persian digits.
  static String toPersian(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final index = latin.indexOf(char);
      buffer.write(index == -1 ? char : persian[index]);
    }
    return buffer.toString();
  }

  /// Whether [input] contains at least one Persian or Arabic digit.
  static bool containsNonLatinDigits(String input) => input.runes.any((rune) {
    final char = String.fromCharCode(rune);
    return persian.contains(char) || arabic.contains(char);
  });
}

/// Formats [Rial] values for display in the selected unit.
class MoneyFormatter {
  const MoneyFormatter({
    this.unit = CurrencyUnit.toman,
    this.usePersianDigits = true,
    this.showSymbol = true,
  });

  final CurrencyUnit unit;
  final bool usePersianDigits;
  final bool showSymbol;

  /// Formats an amount with thousands separators and an optional unit symbol.
  ///
  /// In Toman mode an exact half-toman (5 rial) is shown as `٫۵`, and amounts
  /// that are not whole toman keep their rial precision rather than being
  /// rounded away.
  String format(Rial amount, {bool withSymbol = true, String? symbol}) {
    final unitSymbol = symbol ?? (showSymbol ? unit.label : '');
    final negative = amount.isNegative;
    final absolute = amount.abs.value;

    final String number;
    switch (unit) {
      case CurrencyUnit.rial:
        number = _group(absolute.toString());
      case CurrencyUnit.toman:
        final whole = absolute ~/ 10;
        final fraction = absolute % 10;
        final base = _group(whole.toString());
        // 1 rial = 0.1 toman; keep the exact value instead of rounding.
        number = fraction == 0 ? base : '$base٫${_toDigit(fraction)}';
    }

    final sign = negative ? '−' : '';
    final text = '$sign$number';
    final rendered = usePersianDigits ? PersianDigits.toPersian(text) : text;
    return unitSymbol.isEmpty ? rendered : '$rendered $unitSymbol';
  }

  /// Formats an amount without the unit symbol.
  String formatPlain(Rial amount) => format(amount, withSymbol: false);

  /// Formats a signed amount, always showing `+` for positive values.
  String formatSigned(Rial amount) {
    final prefix = amount.isNegative ? '' : '+';
    return '$prefix${format(amount)}';
  }

  String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _toDigit(int value) =>
      usePersianDigits ? PersianDigits.persian[value] : '$value';
}
