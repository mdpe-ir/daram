import 'package:daram/core/money/currency.dart';
import 'package:daram/features/ai/data/prompt_builder.dart';
import 'package:daram/features/ai/data/tool_registry.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'system prompt lists every tool, including category management',
    () async {
      final builder = await PromptBuilder.load(rootBundle);
      final registry = await ToolRegistry.load(rootBundle);
      final prompt = builder.build(
        PromptContext(
          now: DateTime(2026, 11, 8, 10, 30),
          currency: CurrencyUnit.toman,
          accounts: const [],
          categories: const [],
          loans: const [],
          tools: registry.definitions,
        ),
      );

      for (final definition in registry.definitions) {
        expect(prompt, contains(definition.name), reason: definition.name);
      }
      expect(prompt, contains('manage_category'));
      expect(prompt, contains('coffee'));
      // Every placeholder must be resolved before the prompt is sent.
      expect(prompt, isNot(contains('{{')));
    },
  );

  test('JSON mode tells the model where to find tool names', () async {
    final builder = await PromptBuilder.load(rootBundle);
    final prompt = builder.build(
      PromptContext(
        now: DateTime(2026, 11, 8),
        currency: CurrencyUnit.toman,
        accounts: const [],
        categories: const [],
        loans: const [],
        tools: const [
          ToolDefinition(
            name: 'manage_category',
            description: 'مدیریت دسته‌بندی',
            parameters: {
              'type': 'object',
              'properties': {
                'action': {'type': 'string'},
              },
            },
          ),
        ],
        toolMode: AIToolMode.json,
      ),
    );

    expect(prompt, contains('فهرست «ابزارهای در دسترس»'));
    expect(prompt, contains('manage_category'));
  });
}
