import 'package:daram/core/money/currency.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/features/ai/data/argument_parser.dart';
import 'package:daram/features/ai/data/json_schema_validator.dart';
import 'package:daram/features/ai/data/tool_registry.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/ai/domain/tool.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ToolRegistry', () {
    test('loads all bundled schemas from assets', () async {
      final registry = await ToolRegistry.load(rootBundle);
      expect(registry.definitions, hasLength(7));
      for (final tool in DaramTool.values) {
        expect(
          registry.byName(tool.toolName),
          isNotNull,
          reason: tool.toolName,
        );
      }
    });

    test('rejects arguments that violate the strict schema', () async {
      final registry = await ToolRegistry.load(rootBundle);
      expect(
        registry.validateArguments('add_transaction', {
          'type': 'expense',
          'amount': -1,
          'amount_unit': 'toman',
          'date': 'امروز',
          'category': 'خوراک',
          'account': 'ملت',
        }),
        isNotNull,
      );
      expect(
        registry.validateArguments('add_transaction', {
          'type': 'expense',
          'amount': 250000,
          'amount_unit': 'toman',
          'date': 'امروز',
          'category': 'خوراک',
          'account': 'ملت',
          'extra': true,
        }),
        contains('unexpected property'),
      );
    });

    test('accepts a valid transaction call', () async {
      final registry = await ToolRegistry.load(rootBundle);
      expect(
        registry.validateArguments('add_transaction', {
          'type': 'expense',
          'amount': 250000,
          'amount_unit': 'toman',
          'date': 'امروز',
          'category': 'خوراک و رستوران',
          'account': 'حساب ملت',
        }),
        isNull,
      );
    });
  });

  group('JsonSchemaValidator', () {
    const validator = JsonSchemaValidator();
    final schema = <String, Object?>{
      'type': 'object',
      'properties': {
        'name': {'type': 'string', 'minLength': 2},
        'count': {'type': 'integer', 'minimum': 1, 'maximum': 5},
        'kind': {
          'type': 'string',
          'enum': ['a', 'b'],
        },
        'items': {
          'type': 'array',
          'items': {'type': 'number'},
        },
      },
      'required': ['name', 'count'],
      'additionalProperties': false,
    };

    test('accepts a valid object', () {
      expect(
        validator.validate(schema, {
          'name': 'ok',
          'count': 3,
          'kind': 'a',
          'items': [1, 2.5],
        }),
        isEmpty,
      );
    });

    test('reports every kind of violation', () {
      final errors = validator.validate(schema, {
        'count': 9,
        'kind': 'c',
        'items': ['x'],
        'extra': 1,
      });
      expect(
        errors.any((e) => e.contains('name') && e.contains('required')),
        isTrue,
      );
      expect(
        errors.any((e) => e.contains('count') && e.contains('<=')),
        isTrue,
      );
      expect(
        errors.any((e) => e.contains('kind') && e.contains('one of')),
        isTrue,
      );
      expect(errors.any((e) => e.contains('items[0]')), isTrue);
      expect(errors.any((e) => e.contains('extra')), isTrue);
    });
  });

  group('ArgumentParser money', () {
    const parser = ArgumentParser();

    test('converts toman numbers to rial without floating point', () {
      expect(
        parser
            .parseMoney(250000, 'toman', fallbackUnit: CurrencyUnit.rial)
            .value,
        2500000,
      );
      expect(
        parser.parseMoney(1.5, 'toman', fallbackUnit: CurrencyUnit.rial).value,
        15,
      );
      expect(
        parser
            .parseMoney('۲۵۰,۰۰۰', 'تومان', fallbackUnit: CurrencyUnit.rial)
            .value,
        2500000,
      );
      expect(
        parser
            .parseMoney(500000, 'rial', fallbackUnit: CurrencyUnit.toman)
            .value,
        500000,
      );
    });

    test('rejects zero and negative amounts unless allowed', () {
      expect(
        () => parser.parseMoney(0, 'toman', fallbackUnit: CurrencyUnit.toman),
        throwsA(isA<Exception>()),
      );
      expect(
        parser
            .parseMoney(
              0,
              'toman',
              fallbackUnit: CurrencyUnit.toman,
              allowZero: true,
            )
            .value,
        0,
      );
    });
  });

  group('ArgumentParser dates', () {
    final parser = ArgumentParser(
      today: CalendarDate(2026, 11, 6),
    ); // 1405/08/15

    test('parses relative Persian dates against the injected clock', () {
      expect(parser.parseDate('امروز').date, CalendarDate(2026, 11, 6));
      expect(parser.parseDate('دیروز').date, CalendarDate(2026, 11, 5));
    });

    test('parses ISO and Jalali dates', () {
      expect(parser.parseDate('2026-11-06').date, CalendarDate(2026, 11, 6));
      expect(parser.parseDate('1405/08/15').date, CalendarDate(2026, 11, 6));
    });

    test('fails clearly on an impossible date', () {
      expect(() => parser.parseDate('سلام'), throwsA(isA<Exception>()));
      expect(() => parser.parseDate(null), throwsA(isA<Exception>()));
    });
  });

  test('AIConfig never duplicates a version path segment', () {
    const openAi = AIConfig(
      provider: AIProviderKind.openAICompatible,
      baseUrl: 'https://proxy.example.com/v1/',
      model: 'gpt-4o-mini',
      apiKey: 'x',
    );
    expect(
      openAi.chatEndpoint(),
      'https://proxy.example.com/v1/chat/completions',
    );

    const anthropic = AIConfig(
      provider: AIProviderKind.anthropic,
      baseUrl: 'https://api.anthropic.com/v1',
      model: 'claude',
      apiKey: 'x',
    );
    expect(anthropic.chatEndpoint(), 'https://api.anthropic.com/v1/messages');

    const gemini = AIConfig(
      provider: AIProviderKind.gemini,
      baseUrl: 'https://generativelanguage.googleapis.com',
      model: 'gemini-2.5-flash',
      apiKey: 'x',
    );
    expect(
      gemini.chatEndpoint(),
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent',
    );
  });

  test('Rial amounts round-trip through tool payloads', () {
    final amount = Rial.fromToman(1234567);
    expect(amount.value, 12345670);
    expect(amount.toTomanTruncated(), 1234567);
  });
}
