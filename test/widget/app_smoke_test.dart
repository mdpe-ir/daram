import 'package:daram/app/app.dart';
import 'package:daram/app/app_providers.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/currency.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/ai/data/ai_chat_service.dart';
import 'package:daram/features/ai/data/prompt_builder.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/chat/domain/chat_models.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

class _FakeChatService extends AIChatService {
  _FakeChatService({
    required super.providers,
    required super.tools,
    required super.executor,
  });

  final List<ChatRunEvent> scripted = [];

  @override
  Stream<ChatRunEvent> run({
    required AIConfig config,
    required String systemPrompt,
    required List<ChatMessage> history,
    required String userMessage,
    required String sessionId,
    required CurrencyUnit defaultCurrency,
  }) async* {
    for (final event in scripted) {
      yield event;
    }
  }
}

void main() {
  testWidgets('app boots, shows onboarding and reaches the chat', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await CategoryRepository(db).ensureDefaults();
    final settings = SettingsRepository(prefs, TestKeyStore());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(settings),
        ],
        child: const DaramApp(),
      ),
    );
    await tester.pump();
    expect(find.text('دارام'), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('رد کردن'), findsOneWidget);

    await tester.tap(find.text('رد کردن'));
    await tester.pumpAndSettle();

    expect(find.text('سلام، من دارام هستم'), findsOneWidget);
    expect(find.text('ثبت هزینه'), findsOneWidget);
    expect(find.text('دستیار'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('سلام، من دارام هستم'))),
      TextDirection.rtl,
    );
  });

  testWidgets('chat expense draft is confirmed and stored', (tester) async {
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
      operationId: 'test-account',
    );
    final settings = SettingsRepository(prefs, TestKeyStore('sk-test'));

    late _FakeChatService fake;
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(settings),
        promptBuilderProvider.overrideWith(
          (ref) => PromptBuilder(template: 'test prompt', examples: const []),
        ),
        aiChatServiceProvider.overrideWith((ref) async => fake),
      ],
    );
    addTearDown(container.dispose);

    fake = _FakeChatService(
      providers: container.read(aiProviderRegistryProvider),
      tools: await container.read(toolRegistryProvider.future),
      executor: await container.read(toolExecutorProvider.future),
    );
    final action = PendingAction(
      id: 'action-1',
      sessionId: 'pending-session',
      actionType: 'add_transaction',
      payload: {
        'type': 'expense',
        'amountRial': 2500000,
        'accountId': account.id,
        'accountName': 'حساب ملت',
        'categoryId': 'cat_food',
        'categoryName': 'خوراک و رستوران',
        'date': '2026-11-06',
        'description': 'ناهار',
        'assumedCategory': false,
        'assumedDate': false,
      },
      status: PendingActionStatus.pending,
      operationId: 'operation-1',
      createdAt: DateTime.now().toUtc(),
    );
    fake.scripted.addAll([
      const ChatRunText('پیش‌نویس هزینه ناهار آماده شد.'),
      ChatRunCompleted(
        text: 'پیش‌نویس هزینه ناهار آماده شد.',
        actions: [action],
        reports: const [],
      ),
    ]);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DaramApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).last,
      'امروز ۲۵۰ هزار تومان ناهار خوردم',
    );
    await tester.pump();
    await tester.tap(find.byIcon(LucideIcons.arrowUp));
    await tester.pumpAndSettle();

    expect(find.text('پیش‌نویس مالی'), findsOneWidget);
    expect(find.text('تأیید و ثبت'), findsOneWidget);

    await tester.tap(find.text('تأیید و ثبت'));
    await tester.pumpAndSettle();

    final rows = await db.select(db.transactions).get();
    expect(rows, hasLength(1));
    expect(rows.single.amountRial, 2500000);
    expect(await db.select(db.ledgerEntries).get(), hasLength(1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
