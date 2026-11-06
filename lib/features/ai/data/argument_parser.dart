import '../../../core/errors/app_exception.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/rial.dart';
import '../../../core/persian/amount_parser.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/persian_date_parser.dart';

/// Result of interpreting a date argument.
class ParsedDateArgument {
  const ParsedDateArgument(this.date, {this.ambiguous = false, this.note});

  final CalendarDate date;
  final bool ambiguous;
  final String? note;
}

/// Deterministic parsing of tool arguments coming from the model.
///
/// The model is never trusted to do arithmetic or date normalisation: every
/// amount becomes an integer [Rial] and every date a [CalendarDate] here.
class ArgumentParser {
  const ArgumentParser({CalendarDate? today}) : _today = today;

  final CalendarDate? _today;

  CalendarDate get today => _today ?? CalendarDate.today();

  ParsedDateArgument parseDate(Object? value, {String field = 'تاریخ'}) {
    if (value == null || (value is String && value.trim().isEmpty)) {
      throw ValidationException('$field مشخص نیست؛ لطفاً تاریخ را بگویید.');
    }
    final raw = value is String ? value.trim() : '$value';
    final normalized = raw.toLowerCase();
    final relative = switch (normalized) {
      'today' => today,
      'yesterday' => today.addDays(-1),
      'tomorrow' => today.addDays(1),
      _ => null,
    };
    if (relative != null) return ParsedDateArgument(relative);

    final parsed = PersianDateParser(reference: today).parse(raw);
    if (!parsed.isSuccess || parsed.date == null) {
      throw ValidationException(
        '$field «$raw» قابل تشخیص نیست؛ لطفاً تاریخ را به شکل «امروز»، «۱۴۰۴/۰۵/۲۳» یا تاریخ میلادی بگویید.',
      );
    }
    return ParsedDateArgument(
      parsed.date!,
      ambiguous: parsed.ambiguous,
      note: parsed.note,
    );
  }

  /// Converts a tool amount (number or numeric string) plus a unit to Rial.
  Rial parseMoney(
    Object? amount,
    Object? unitValue, {
    required CurrencyUnit fallbackUnit,
    String field = 'مبلغ',
    bool allowZero = false,
  }) {
    if (amount == null) {
      throw ValidationException('$field مشخص نیست.');
    }
    final unit = CurrencyUnit.tryParse(unitValue) ?? fallbackUnit;
    late final Rial rial;

    if (amount is int) {
      rial = unit == CurrencyUnit.toman ? Rial.fromToman(amount) : Rial(amount);
    } else if (amount is double) {
      if (amount.isNaN || amount.isInfinite) {
        throw ValidationException('$field معتبر نیست.');
      }
      if (unit == CurrencyUnit.toman) {
        rial = Rial.fromTomanExact(amount.toString());
      } else {
        if (amount != amount.roundToDouble()) {
          throw ValidationException('$field باید عدد صحیح ریالی باشد.');
        }
        rial = Rial(amount.toInt());
      }
    } else if (amount is String) {
      final parsed = const AmountParser().parse(amount, fallbackUnit: unit);
      if (!parsed.isSuccess || parsed.rial == null) {
        throw ValidationException('$field «$amount» قابل خواندن نیست.');
      }
      // A string that only contains digits with an explicit unit is taken as
      // the unit value; the parser already applies the requested fallback.
      rial = parsed.rial!;
    } else {
      throw ValidationException('$field باید عدد باشد.');
    }

    if (!allowZero && rial <= Rial.zero) {
      throw ValidationException('$field باید بزرگ‌تر از صفر باشد.');
    }
    if (rial.isNegative) {
      throw ValidationException('$field نمی‌تواند منفی باشد.');
    }
    return rial;
  }

  CurrencyUnit parseUnit(Object? value, {required CurrencyUnit fallback}) =>
      CurrencyUnit.tryParse(value) ?? fallback;

  int parseInteger(Object? value, {required String field, int? min, int? max}) {
    final int? parsed;
    if (value is int) {
      parsed = value;
    } else if (value is num) {
      parsed = value == value.roundToDouble() ? value.toInt() : null;
    } else if (value is String) {
      parsed = int.tryParse(value.replaceAll(RegExp(r'[^\d\-]'), ''));
    } else {
      parsed = null;
    }
    if (parsed == null) throw ValidationException('$field باید عدد صحیح باشد.');
    if (min != null && parsed < min) {
      throw ValidationException('$field باید حداقل $min باشد.');
    }
    if (max != null && parsed > max) {
      throw ValidationException('$field باید حداکثر $max باشد.');
    }
    return parsed;
  }

  String requireString(
    Object? value, {
    required String field,
    bool allowEmpty = false,
  }) {
    if (value == null) throw ValidationException('$field مشخص نیست.');
    final text = value is String ? value.trim() : '$value';
    if (!allowEmpty && text.isEmpty) {
      throw ValidationException('$field مشخص نیست.');
    }
    return text;
  }
}
