import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/currency.dart';
import 'package:daram/features/ai/data/prompt_builder.dart';
import 'package:daram/features/ai/data/tool_registry.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/chat/domain/chat_models.dart';
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
      expect(prompt, contains('#F97316'));
      expect(prompt, contains('نارنجی'));
      expect(prompt, contains('پالت رنگ'));
      expect(prompt, contains('label_fa'));
      expect(prompt, contains('شمسی'));
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

  test(
    'prompt carries open drafts, recent activity and the quoted reply',
    () async {
      final builder = await PromptBuilder.load(rootBundle);
      final pending = PendingAction(
        id: 'action-open-1',
        sessionId: 'session-1',
        actionType: 'add_transaction',
        payload: const {
          'type': 'expense',
          'amountRial': 2500000,
          'accountId': 'acc-1',
          'accountName': 'حساب ملت',
          'categoryId': 'cat_food',
          'categoryName': 'خوراک و رستوران',
          'date': '2026-11-06',
          'description': 'ناهار',
        },
        status: PendingActionStatus.pending,
        operationId: 'op-1',
        createdAt: DateTime.utc(2026, 11, 6, 10),
      );
      final reply = ChatMessage(
        id: 'message-1',
        sessionId: 'session-1',
        role: ChatRole.user,
        content: 'ناهار ۲۵۰ هزار تومان بود',
        type: ChatMessageType.text,
        metadata: const {},
        createdAt: DateTime.utc(2026, 11, 6, 10),
      );
      final prompt = builder.build(
        PromptContext(
          now: DateTime(2026, 11, 8, 10, 30),
          currency: CurrencyUnit.toman,
          accounts: const [],
          categories: const [],
          loans: const [],
          pendingActions: [pending],
          replyTo: reply,
          tools: (await ToolRegistry.load(rootBundle)).definitions,
        ),
      );

      expect(prompt, contains('action-open-1'));
      expect(prompt, contains('در انتظار تأیید'));
      expect(prompt, contains('ناهار ۲۵۰ هزار تومان بود'));
      expect(prompt, contains('پیش‌نویس‌های باز'));
      expect(prompt, contains('get_financial_overview'));
      expect(prompt, contains('manage_transaction'));
      expect(prompt, contains('update_pending_draft'));
      expect(prompt, isNot(contains('{{')));
    },
  );
}
