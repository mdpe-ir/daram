import 'package:meta/meta.dart';

import '../formatting/persian_formatting.dart';
import '../money/currency.dart';
import '../money/rial.dart';

/// Outcome of parsing a colloquial Persian money expression.
@immutable
final class ParsedAmount {
  const ParsedAmount({
    required this.rial,
    required this.currencyExplicit,
    required this.matchedText,
    this.ambiguous = false,
    this.note,
  });

  const ParsedAmount.failed(this.note)
    : rial = null,
      currencyExplicit = false,
      matchedText = '',
      ambiguous = true;

  final Rial? rial;

  /// Whether the user explicitly said «تومن» or «ریال».
  final bool currencyExplicit;

  /// The substring that carried the amount.
  final String matchedText;

  final bool ambiguous;
  final String? note;

  bool get isSuccess => rial != null;
}

/// Deterministic parser for Persian amounts.
///
/// Handles Persian/Arabic/Latin digits, word numbers, the «هزار/میلیون/
/// میلیارد» scales, fractions such as «یک و نیم» and both currency units.
/// The parser never guesses a unit: if the user did not say «تومن» or «ریال»
/// the caller's [fallbackUnit] is used and [ParsedAmount.currencyExplicit] is
/// false so that the AI can ask a clarifying question when it matters.
class AmountParser {
  const AmountParser();

  static const Map<String, int> _scales = <String, int>{
    'هزار': 1000,
    'هزارتومانی': 1000,
    'میلیون': 1000000,
    'ملیون': 1000000,
    'میلیونی': 1000000,
    'میلیارد': 1000000000,
    'میلیاردی': 1000000000,
    'تریلیون': 1000000000000,
  };

  static const Map<String, int> _wordValues = <String, int>{
    'صفر': 0,
    'یک': 1,
    'دو': 2,
    'سه': 3,
    'چهار': 4,
    'پنج': 5,
    'شش': 6,
    'ششت': 6,
    'هفت': 7,
    'هشت': 8,
    'نه': 9,
    'ده': 10,
    'یازده': 11,
    'دوازده': 12,
    'سیزده': 13,
    'چهارده': 14,
    'پانزده': 15,
    'شانزده': 16,
    'هفده': 17,
    'هجده': 18,
    'نوزده': 19,
    'بیست': 20,
    'سی': 30,
    'چهل': 40,
    'پنجاه': 50,
    'شصت': 60,
    'هفتاد': 70,
    'هشتاد': 80,
    'نود': 90,
    'صد': 100,
    'یکصد': 100,
    'دویست': 200,
    'سیصد': 300,
    'چهارصد': 400,
    'پانصد': 500,
    'ششصد': 600,
    'هفتصد': 700,
    'هشتصد': 800,
    'نهصد': 900,
  };

  static const Set<String> _currencyWords = <String>{
    'ریال',
    'ریالی',
    'ریالش',
    'ریالها',
    'تومان',
    'تومن',
    'تومنی',
    'تومانش',
    'تومنش',
  };

  /// Parses the most likely amount expression found in [input].
  ///
  /// [fallbackUnit] decides the unit when the text is silent about it.
  ParsedAmount parse(
    String input, {
    CurrencyUnit fallbackUnit = CurrencyUnit.toman,
  }) {
    final text = _normalize(input);
    if (text.isEmpty) {
      return const ParsedAmount.failed('متنی برای خواندن مبلغ وجود ندارد.');
    }

    CurrencyUnit? explicitUnit;
    if (RegExp(r'(^|\s)(ریال|ریالی|ریالش|ریالها)(\s|$)').hasMatch(text)) {
      explicitUnit = CurrencyUnit.rial;
    } else if (RegExp(r'(^|\s)(تومان|تومن|تومنی|تومانش|تومنش)(\s|$)')
        .hasMatch(text)) {
      explicitUnit = CurrencyUnit.toman;
    }
    final unit = explicitUnit ?? fallbackUnit;

    final tokens = text
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();
    final candidates = _candidateRuns(tokens);
    if (candidates.isEmpty) {
      return const ParsedAmount.failed('مبلغ در متن پیدا نشد.');
    }

    // Prefer runs immediately followed by a currency word, then runs with a
    // scale word, then the longest run.
    candidates.sort((a, b) {
      final currency =
          (b.followedByCurrency ? 1 : 0) - (a.followedByCurrency ? 1 : 0);
      if (currency != 0) return currency;
      final scale = (b.hasScale ? 1 : 0) - (a.hasScale ? 1 : 0);
      if (scale != 0) return scale;
      return b.tokens.length - a.tokens.length;
    });

    for (final candidate in candidates) {
      final expression = candidate.tokens.join(' ').trim();
      try {
        final tenths = _evaluate(candidate.tokens);
        if (tenths == null || tenths < 0) continue;

        final rialNumerator = tenths * unit.rialFactor;
        if (rialNumerator % 10 != 0) continue;
        final rial = Rial(rialNumerator ~/ 10);
        final unitValue = tenths ~/ 10;
        final smallWithoutUnit =
            !candidate.hasScale && unitValue < 1000 && explicitUnit == null;
        return ParsedAmount(
          rial: rial,
          currencyExplicit: explicitUnit != null,
          matchedText: expression,
          ambiguous: smallWithoutUnit,
          note: smallWithoutUnit
              ? 'مبلغ کوچک است و واحد آن مشخص نیست؛ لطفاً واحد را روشن کنید.'
              : null,
        );
      } on MoneyException {
        continue;
      }
    }
    return const ParsedAmount.failed('عبارت مبلغ معتبر نیست.');
  }

  /// Finds runs of consecutive amount tokens.
  List<_Candidate> _candidateRuns(List<String> tokens) {
    final candidates = <_Candidate>[];
    var current = <String>[];

    void flush(int endIndex) {
      if (current.isEmpty) return;
      // A run that only contains «و» is not a number.
      if (!current.any(
        (token) =>
            _isNumeric(token) ||
            _wordValues.containsKey(token) ||
            token == 'نیم',
      )) {
        current = <String>[];
        return;
      }
      final next = endIndex + 1 < tokens.length ? tokens[endIndex + 1] : null;
      candidates.add(
        _Candidate(
          tokens: List<String>.of(current),
          followedByCurrency: next != null && _currencyWords.contains(next),
          hasScale: current.any(_scales.containsKey),
        ),
      );
      current = <String>[];
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final isAmountToken =
          _isNumeric(token) ||
          _wordValues.containsKey(token) ||
          _scales.containsKey(token) ||
          token == 'نیم' ||
          token == 'و';
      if (isAmountToken) {
        if (current.isEmpty) {
          // Marker: first token of the current run (kept for readability).
        }
        current.add(token);
      } else {
        flush(i - 1);
      }
    }
    flush(tokens.length - 1);
    return candidates;
  }

  int? _evaluate(List<String> tokens) {
    var total = 0; // tenths of a display unit
    var current = 0; // whole units accumulated
    var currentTenths = 0; // fractional tenths
    var hasAny = false;

    for (final token in tokens) {
      if (token == 'و') continue;

      if (token == 'نیم') {
        currentTenths += 5;
        hasAny = true;
        continue;
      }

      final numeric = _parseNumericToken(token);
      if (numeric != null) {
        current += numeric.$1;
        currentTenths += numeric.$2;
        hasAny = true;
        continue;
      }

      final scale = _scales[token];
      if (scale != null) {
        final baseTenths = current * 10 + currentTenths;
        total += baseTenths * scale;
        current = 0;
        currentTenths = 0;
        hasAny = true;
        continue;
      }

      final word = _wordValues[token];
      if (word != null) {
        current += word;
        hasAny = true;
        continue;
      }

      return null;
    }

    if (!hasAny) return null;
    total += current * 10 + currentTenths;
    return total;
  }

  (int, int)? _parseNumericToken(String token) {
    final cleaned = token.replaceAll(',', '').replaceAll('٫', '.');
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final whole = int.tryParse(match.group(1)!);
    if (whole == null) return null;
    final fraction = match.group(2) ?? '';
    if (fraction.isEmpty) return (whole, 0);
    if (fraction.length == 1) return (whole, int.parse(fraction) * 10);
    return (whole, int.parse(fraction));
  }

  bool _isNumeric(String token) =>
      RegExp(r'^\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?$|^\d+(?:\.\d{1,2})?$')
          .hasMatch(token);

  String _normalize(String input) {
    return PersianDigits.toLatin(input)
        .replaceAll('\u200c', ' ')
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('٫', '.')
        .replaceAll('٬', ',')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

@immutable
class _Candidate {
  const _Candidate({
    required this.tokens,
    required this.followedByCurrency,
    required this.hasScale,
  });

  final List<String> tokens;
  final bool followedByCurrency;
  final bool hasScale;
}
