import 'dart:convert';

import 'package:daram/app/app_providers.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/currency.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/domain/account.dart';
import 'package:daram/features/ai/data/ai_chat_service.dart';
import 'package:daram/features/ai/data/prompt_builder.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/chat/data/chat_repository.dart';
import 'package:daram/features/chat/domain/chat_models.dart';
import 'package:daram/features/chat/domain/sms_chat_focus.dart';
import 'package:daram/features/chat/presentation/chat_controller.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

class _RecordingChatService extends AIChatService {
  _RecordingChatService({
    required super.providers,
    required super.tools,
    required super.executor,
  });

  String? systemPrompt;

  @override
  Stream<ChatRunEvent> run({
    required AIConfig config,
    required String systemPrompt,
    required List<ChatMessage> history,
    required String userMessage,
    required String sessionId,
    required CurrencyUnit defaultCurrency,
  }) async* {
    this.systemPrompt = systemPrompt;
    yield const ChatRunCompleted(text: 'انجام شد.', actions: [], reports: []);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ChatRepository chat;
  late ProviderContainer container;
  late _RecordingChatService service;
  late String sessionId;
  late String firstId;
  late String secondId;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.onboarding_complete': true,
      'settings.currency_unit': 'toman',
      'ai.model': 'test-model',
    });
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.memory();
    chat = ChatRepository(db);
    final settings = SettingsRepository(prefs, TestKeyStore('sk-test'));
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(settings),
        promptBuilderProvider.overrideWith(
          (ref) => PromptBuilder(template: 'base prompt', examples: const []),
        ),
        aiChatServiceProvider.overrideWith((ref) async => service),
      ],
    );
    service = _RecordingChatService(
      providers: container.read(aiProviderRegistryProvider),
      tools: await container.read(toolRegistryProvider.future),
      executor: await container.read(toolExecutorProvider.future),
    );

    await container.read(categoryRepositoryProvider).ensureDefaults();
    final account = await container
        .read(accountRepositoryProvider)
        .create(
          bankId: 'mellat',
          bankName: 'بانک ملت',
          accountName: 'حساب ملت',
          accountType: AccountType.bank,
          initialBalance: Rial.zero,
          operationId: 'seed-sms-account',
        );
    final session = await chat.createSession(title: 'sms context');
    sessionId = session.id;
    firstId = 'sms-1';
    secondId = 'sms-2';
    await _seed(
      db,
      account: account,
      id: firstId,
      description: 'پارکینگ',
      amountRial: 2000000,
    );
    await _seed(
      db,
      account: account,
      id: secondId,
      description: 'تاکسی',
      amountRial: 600000,
    );
    await chat.addMessage(
      sessionId: sessionId,
      role: ChatRole.assistant,
      content: 'این پیشنهادها را ببین.',
      type: ChatMessageType.text,
      metadata: {
        'smsSuggestionIds': [firstId, secondId],
      },
    );
    await container.read(settingsControllerProvider.future);
    await container.read(chatControllerProvider.notifier).initialize();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('reply focus reaches the model with the exact suggestion id', () async {
    await container
        .read(chatControllerProvider.notifier)
        .send('تأییدش کن', smsFocus: const SmsChatFocus(replyToId: 'sms-1'));
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(service.systemPrompt, contains('پیشنهادهای پیامکی انتخاب‌شده'));
    expect(service.systemPrompt, contains('`sms-1`'));
    expect(service.systemPrompt, isNot(contains('`sms-2`')));
    expect(service.systemPrompt, contains('پاسخ'));
    expect(service.systemPrompt, contains('confirm_sms_suggestion'));

    final messages = await chat.messages(sessionId);
    final user = messages.lastWhere((message) => message.isUser);
    expect(user.metadata['smsReplyTo'], 'sms-1');
    expect('${user.metadata['smsFocusLabel']}', contains('پاسخ به پیشنهاد'));
    expect('${user.metadata['smsFocusLabel']}', contains('پارکینگ'));
    expect(container.read(chatControllerProvider).streaming, isFalse);
  });

  test('group focus lists every selected id for one instruction', () async {
    await container
        .read(chatControllerProvider.notifier)
        .send(
          'هر دو را تأیید کن',
          smsFocus: const SmsChatFocus(selectedIds: {'sms-1', 'sms-2'}),
        );
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(service.systemPrompt, contains('2 پیشنهاد پیامکی'));
    expect(service.systemPrompt, contains('`sms-1`'));
    expect(service.systemPrompt, contains('`sms-2`'));
    expect(service.systemPrompt, contains('confirm_sms_suggestion'));

    final messages = await chat.messages(sessionId);
    final user = messages.lastWhere((message) => message.isUser);
    expect(user.metadata['smsSelection'], ['sms-1', 'sms-2']);
    expect(
      '${user.metadata['smsFocusLabel']}',
      contains('۲ پیشنهاد انتخاب‌شده'),
    );
  });
}

Future<void> _seed(
  AppDatabase db, {
  required Account account,
  required String id,
  required String description,
  required int amountRial,
}) => db
    .into(db.smsSuggestions)
    .insert(
      SmsSuggestionsCompanion.insert(
        id: id,
        sender: '1001',
        receivedAt: DateTime.utc(2026, 11, 6, 10),
        template: 'برداشت: [n0] ریال',
        payload: jsonEncode({
          'type': 'expense',
          'amountRial': amountRial,
          'accountId': account.id,
          'accountName': account.accountName,
          'categoryId': 'cat_food',
          'categoryName': 'خوراک و رستوران',
          'date': '2026-11-06',
          'description': description,
        }),
        status: const Value('pending'),
      ),
    );
