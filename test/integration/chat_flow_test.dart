import 'package:daram/app/app.dart';
import 'package:daram/app/app_providers.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/ai/data/ai_chat_service.dart';
import 'package:daram/features/ai/data/ai_provider_registry.dart';
import 'package:daram/features/ai/data/prompt_builder.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/ai/domain/ai_provider.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

class _ScriptedProvider implements AIProvider {
  _ScriptedProvider(this.scripts);

  final List<List<AIStreamEvent>> scripts;
  int calls = 0;

  @override
  Stream<AIStreamEvent> streamChat({
    required AIConfig config,
    required List<AIMessage> messages,
    required List<ToolDefinition> tools,
  }) async* {
    final script = scripts[calls.clamp(0, scripts.length - 1)];
    calls++;
    for (final event in script) {
      yield event;
    }
  }

  @override
  Future<AIConnectionResult> testConnection(AIConfig config) async =>
      const AIConnectionResult.success('ok');
}

class _FakeRegistry extends AIProviderRegistry {
  _FakeRegistry(this.provider) : super(Dio());

  final AIProvider provider;

  @override
  AIProvider forKind(AIProviderKind kind) => provider;
}

void main() {
  testWidgets(
    'One message keeps four activities, including two identical purchases',
    (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings.onboarding_complete': true,
        'settings.currency_unit': 'toman',
        'ai.model': 'test-model',
      });
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await CategoryRepository(db).ensureDefaults();
      final operations = OperationRepository(db);
      final account = await AccountRepository(db, operations).create(
        bankId: 'mellat',
        bankName: 'بانک ملت',
        accountName: 'حساب ملت',
        accountType: AccountType.bank,
        initialBalance: Rial.fromToman(1000000),
        operationId: 'seed-account',
      );
      final settings = SettingsRepository(prefs, TestKeyStore('sk-test'));

      late AIChatService service;
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(settings),
          promptBuilderProvider.overrideWith(
            (ref) => PromptBuilder(template: 'test prompt', examples: const []),
          ),
          aiChatServiceProvider.overrideWith((ref) async => service),
        ],
      );
      addTearDown(container.dispose);

      final provider = _ScriptedProvider([
        [
          const AIStreamText('چهار فعالیت را بررسی می‌کنم.'),
          AIStreamToolCalls([
            const ToolCall(
              id: 'call-1',
              name: 'add_transaction',
              arguments: {
                'type': 'expense',
                'amount': 500000,
                'amount_unit': 'toman',
                'date': 'امروز',
                'category': 'حمل‌ونقل',
                'account': 'ملت',
                'description': 'اسنپ',
              },
            ),
            const ToolCall(
              id: 'call-2',
              name: 'add_transaction',
              arguments: {
                'type': 'income',
                'amount': 3000000,
                'amount_unit': 'toman',
                'date': 'امروز',
                'category': 'حقوق',
                'account': 'ملت',
                'description': 'حقوق',
              },
            ),
            const ToolCall(
              id: 'call-3',
              name: 'add_transaction',
              arguments: {
                'type': 'expense',
                'amount': 200000,
                'amount_unit': 'toman',
                'date': 'امروز',
                'category': 'خرید',
                'account': 'ملت',
                'description': 'خرید',
              },
            ),
            const ToolCall(
              id: 'call-4',
              name: 'add_transaction',
              arguments: {
                'type': 'expense',
                'amount': 200000,
                'amount_unit': 'toman',
                'date': 'امروز',
                'category': 'خرید',
                'account': 'ملت',
                'description': 'خرید',
              },
            ),
          ]),
          const AIStreamDone(finishReason: 'tool_calls'),
        ],
        [
          const AIStreamText(
            'چهار پیش‌نویس آماده است؛ هر کدام را بررسی و تأیید کن.',
          ),
          const AIStreamDone(finishReason: 'stop'),
        ],
      ]);
      service = AIChatService(
        providers: _FakeRegistry(provider),
        tools: await container.read(toolRegistryProvider.future),
        executor: await container.read(toolExecutorProvider.future),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DaramApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).last,
        'امروز ۵۰۰ هزار اسنپ دادم، ۳ میلیون حقوق گرفتم و دو بار ۲۰۰ هزار خرید کردم',
      );
      await tester.pump();
      await tester.tap(find.byIcon(LucideIcons.arrowUp));
      await tester.pumpAndSettle();

      expect(find.text('پیش‌نویس مالی'), findsNWidgets(4));
      expect(find.text('تأیید همه'), findsOneWidget);
      expect(provider.calls, 2);

      await tester.ensureVisible(find.text('تأیید همه'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید همه'));
      await tester.pumpAndSettle();

      final rows = await db.select(db.transactions).get();
      expect(rows, hasLength(4));
      final income = rows
          .where((row) => row.type == TransactionType.income)
          .single;
      expect(income.amountRial, 30000000);
      final balance = await AccountRepository(
        db,
        operations,
      ).balanceOf(account.id);
      expect(balance!.balance.value, 10000000 - 5000000 + 30000000 - 4000000);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
