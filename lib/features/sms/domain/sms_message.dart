import '../../../core/domain/enums.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';

final class InboxSms {
  const InboxSms({
    required this.id,
    required this.sender,
    required this.body,
    required this.date,
  });

  final String id;
  final String sender;
  final String body;
  final DateTime date;

  static String normalizeSender(String value) {
    final text = PersianDigits.toLatin(value).trim().toUpperCase();
    return RegExp(r'^\+?[0-9 ()-]+$').hasMatch(text)
        ? text
              .replaceFirst(RegExp(r'^(?:\+98|0098)(?=9\d{9}$)'), '0')
              .replaceAll(RegExp(r'[ ()-]'), '')
        : text;
  }
}

enum SmsKind { income, expense, receipt, ignore }

final class SmsRule {
  const SmsRule(
    this.kind, {
    this.slot,
    this.multiplier,
    this.categoryId,
    this.description,
  });

  factory SmsRule.fromJson(Map<String, Object?> json) => SmsRule(
    SmsKind.values.byName(json['kind'] as String),
    slot: json['slot'] as int?,
    multiplier: json['multiplier'] as int?,
    categoryId: json['categoryId'] as String?,
    description: json['description'] as String?,
  );

  final SmsKind kind;
  final int? slot;
  final int? multiplier;
  final String? categoryId;
  final String? description;

  TransactionType? get transactionType => switch (kind) {
    SmsKind.income => TransactionType.income,
    SmsKind.expense => TransactionType.expense,
    _ => null,
  };

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'slot': slot,
    'multiplier': multiplier,
    'categoryId': categoryId,
    'description': description,
  };
}

final class SmsShape {
  SmsShape(InboxSms sms) : text = _clean(sms.body) {
    final slots = <String>[];
    template = text.replaceAllMapped(_number, (match) {
      slots.add(match.group(0)!);
      return '[n${slots.length - 1}]';
    });
    numbers = slots;
  }

  final String text;
  late final String template;
  late final List<String> numbers;

  static final _number = RegExp(r'\d+(?:[,٬،]\d{3})*');
  static final _links = RegExp(
    r'(?:https?://|www\.)\S+|[\w.%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}|[\w\-]+\.(?:ir|com|net|org)(?:/\S*)?',
    caseSensitive: false,
  );
  static final _expense = RegExp(
    r'برداشت|کسر شد|خرید|بدهکار|پرداخت|debit|withdrawal',
    caseSensitive: false,
  );
  static final _income = RegExp(
    r'واریز|بستانکار|افزایش موجودی|deposit|credit',
    caseSensitive: false,
  );
  static final _receipt = RegExp(
    r'پارکینگ|پارکومتر|صورتحساب|صورت حساب|سفارش|رسید|کرایه|عوارض|اشتراک|قبض|حقوق|دستمزد|بیمه|پرداخت شد',
  );
  static final _balance = RegExp(r'موجودی|مانده|balance', caseSensitive: false);
  static final _auth = RegExp(
    r'رمز|کد\s*(?:فعال\s*سازی|تایید|تأیید|ورود|اعتبارسنجی|احراز هویت|امنیتی|یک\s*بار\s*مصرف)|'
    r'کد\s*(?::|=|شما)|(?:verification|security|login|activation)\s*code|'
    r'one[ -]time|\botp\b|password|\bcvv2?\b|\bpin\b|محرمانه',
    caseSensitive: false,
  );
  static final _failed = RegExp(r'ناموفق|انجام نشد|انجام نشده|نامعتبر|لغو شد');
  static final _requested = RegExp(
    r'درخواست (?:برداشت|واریز)|مبلغ قابل پرداخت',
  );
  static const _unit = r'(?:تومان|تومن|ریال|﷼|irr|rial|toman)';
  static final _explicitUnit = RegExp(
    '^(?:[ \\t]*هزار)?[ \\t]*$_unit',
    caseSensitive: false,
  );

  static String _clean(String input) =>
      PersianDigits.toLatin(input)
          .replaceAll(RegExp(r'[\u200e\u200f\u202a-\u202e\u2066-\u2069]'), '')
          .replaceAll('\u200c', ' ')
          .replaceAll('ي', 'ی')
          .replaceAll('ك', 'ک')
          .replaceAll('\r', '\n')
          .replaceAll(_links, '[link]')
          .trim();

  bool get isAuthentication => _auth.hasMatch(text);
  bool get isFailed => _failed.hasMatch(text);
  bool get hasFinanceCue =>
      _expense.hasMatch(text) ||
      _income.hasMatch(text) ||
      _balance.hasMatch(text) ||
      RegExp(r'(?:^|\s)[+\-−]\s*\d|ریال|تومان|تومن').hasMatch(text);

  bool get resemblesBankNotice =>
      _balance.hasMatch(text) ||
      RegExp(r'بانک|برداشت|واریز|حساب\s*[:#]|کارت\s*[:#]').hasMatch(text);

  Set<String> get cardSuffixes => RegExp(
    r'(?:کارت|card)[ \t:#=]*[\d*×xX\- ]*(\d{4})(?!\d)',
    caseSensitive: false,
  ).allMatches(text).map((match) => match.group(1)!).toSet();

  SmsRule? localRule({bool receipt = false}) {
    if (isAuthentication ||
        isFailed ||
        (!receipt && _requested.hasMatch(text))) {
      return const SmsRule(SmsKind.ignore);
    }
    if (receipt && !_receipt.hasMatch(text)) return null;

    final choices = <SmsRule>[];
    final matches = _number.allMatches(text).toList();
    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final lineStart = match.start == 0
          ? -1
          : text.lastIndexOf('\n', match.start - 1);
      final nextLine = text.indexOf('\n', match.end);
      final before = text.substring(lineStart + 1, match.start);
      final after = text.substring(
        match.end,
        nextLine < 0 ? text.length : nextLine,
      );
      if (_balance.hasMatch(before) ||
          RegExp(
            r'(?:شناسه|مرجع|پیگیری|شماره|حساب|کارت|تاریخ|ساعت)\s*[:#=]?\s*[*x×-]*\s*$',
          ).hasMatch(before)) {
        continue;
      }
      final unit = _explicitUnit.firstMatch(after)?.group(0)?.toLowerCase();
      final incoming = _income.hasMatch(before) || _income.hasMatch(after);
      final outgoing = _expense.hasMatch(before) || _expense.hasMatch(after);
      final sign =
          RegExp(r'^\s*([+\-−])\s*$').firstMatch(before)?.group(1) ??
          RegExp(r'^\s*([+\-−])(?:\s|$)').firstMatch(after)?.group(1);
      final SmsKind kind;
      if (receipt) {
        if (unit == null) continue;
        kind = SmsKind.receipt;
      } else if (incoming && outgoing) {
        continue;
      } else if (sign != null) {
        if ((incoming && sign != '+') || (outgoing && sign == '+')) continue;
        kind = sign == '+' ? SmsKind.income : SmsKind.expense;
      } else if (incoming || outgoing) {
        kind = incoming ? SmsKind.income : SmsKind.expense;
      } else {
        continue;
      }
      // An unlabeled extra number on the same line is usually an identifier,
      // date or balance. Let the template classifier handle ambiguous lines.
      if (unit == null && RegExp(r'^\s*[/.:]\s*\d').hasMatch(after)) continue;
      if (unit == null && RegExp(r'\d\s*[/.:]\s*$').hasMatch(before)) continue;
      final toman =
          unit != null &&
          (unit.contains('توم') ||
              unit.contains('تمن') ||
              unit.contains('toman'));
      final scale = unit?.contains('هزار') == true ? 1000 : 1;
      final rule = SmsRule(kind, slot: i, multiplier: scale * (toman ? 10 : 1));
      if (amount(rule) != null) choices.add(rule);
    }
    return choices.length == 1 ? choices.single : null;
  }

  Rial? amount(SmsRule rule) {
    final slot = rule.slot;
    final multiplier = rule.multiplier;
    if (slot == null ||
        slot < 0 ||
        slot >= numbers.length ||
        !const {1, 10, 1000, 10000, 1000000, 10000000}.contains(multiplier)) {
      return null;
    }
    final value = int.tryParse(numbers[slot].replaceAll(RegExp(r'[,٬،]'), ''));
    if (value == null ||
        value <= 0 ||
        value > Rial.maxAbsoluteValue ~/ multiplier!) {
      return null;
    }
    return Rial(value * multiplier);
  }

  String get aiTemplate => template
      .split('\n')
      .where(
        (line) =>
            line.contains('[n') ||
            _expense.hasMatch(line) ||
            _income.hasMatch(line) ||
            _receipt.hasMatch(line),
      )
      .join('\n');

  String get semanticText => template
      .replaceAll(RegExp(r'\[n\d+\]|\[link\]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
