import 'dart:convert';

import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/currency.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/ai/data/ai_chat_service.dart';
import 'package:daram/features/ai/data/ai_provider_registry.dart';
import 'package:daram/features/ai/data/tool_executor.dart';
import 'package:daram/features/ai/data/tool_registry.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/ai/domain/ai_provider.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/chat/data/chat_repository.dart';
import 'package:daram/features/chat/domain/chat_models.dart';
import 'package:daram/features/dashboard/data/analytics_repository.dart';
import 'package:daram/features/loans/data/loan_repository.dart';
import 'package:daram/features/sms/data/sms_review_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:daram/features/assets/data/asset_repository.dart';
import 'package:daram/features/obligations/data/obligation_repository.dart';
import 'package:daram/features/transactions/data/transfer_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScriptedProvider implements AIProvider {
  _ScriptedProvider(this.scripts);

  final List<List<AIStreamEvent>> scripts;
  int calls = 0;
  List<AIMessage>? lastMessages;

  @override
  Stream<AIStreamEvent> streamChat({
    required AIConfig config,
    required List<AIMessage> messages,
    required List<ToolDefinition> tools,
    String? sessionId,
  }) async* {
    lastMessages = List<AIMessage>.of(messages);
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ToolExecutor executor;
  late ToolRegistry tools;

  setUp(() async {
    db = AppDatabase.memory();
    final operations = OperationRepository(db);
    final categories = CategoryRepository(db);
    await categories.ensureDefaults();
    final accounts = AccountRepository(db, operations);
    await accounts.create(
      bankId: 'mellat',
      bankName: 'بانک ملت',
      accountName: 'حساب ملت',
      accountType: AccountType.bank,
      initialBalance: Rial.fromToman(1000000),
      operationId: 'op-account',
    );
    final transactions = TransactionRepository(db, operations);
    final loans = LoanRepository(db, operations);
    tools = await ToolRegistry.load(rootBundle);
    executor = ToolExecutor(
      registry: tools,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      loans: loans,
      analytics: AnalyticsRepository(db, accounts, transactions, loans),
      sms: SmsReviewRepository(db, transactions),
      chat: ChatRepository(db),
      assets: AssetRepository(db),
      obligations: ObligationRepository(db),
      transfers: TransferRepository(db, operations),
    );
  });

  tearDown(() async => db.close());

  AIConfig config(AIToolMode mode) => AIConfig(
    provider: AIProviderKind.openAICompatible,
    baseUrl: 'https://example.com/v1',
    model: 'test',
    apiKey: 'sk-test',
    toolMode: mode,
  );

  test(
    'native tool loop executes the draft and continues the conversation',
    () async {
      final provider = _ScriptedProvider([
        [
          const AIStreamText('ثبت می‌کنم. '),
          AIStreamToolCalls([
            const ToolCall(
              id: 'call-1',
              name: 'add_transaction',
              arguments: {
                'type': 'expense',
                'amount': 250000,
                'amount_unit': 'toman',
                'date': '1405/08/15',
                'category': 'خوراک و رستوران',
                'account': 'ملت',
                'description': 'ناهار',
              },
            ),
          ]),
          const AIStreamDone(finishReason: 'tool_calls'),
        ],
        [
          const AIStreamText('پیش‌نویس ناهار آماده است؛ تأیید می‌کنی؟'),
          const AIStreamDone(finishReason: 'stop'),
        ],
      ]);
      final service = AIChatService(
        providers: _FakeRegistry(provider),
        tools: tools,
        executor: executor,
      );

      final events = await service
          .run(
            config: config(AIToolMode.native),
            systemPrompt: 'system',
            history: const [],
            userMessage: 'امروز ۲۵۰ هزار تومان ناهار خوردم',
            sessionId: 'session-1',
            defaultCurrency: CurrencyUnit.toman,
          )
          .toList();

      final completed = events.whereType<ChatRunCompleted>().single;
      expect(completed.actions, hasLength(1));
      expect(completed.actions.single.actionType, 'add_transaction');
      expect(completed.text, contains('پیش‌نویس ناهار'));
      expect(provider.calls, 2);
      // Still only a draft: no financial rows exist yet.
      expect(await db.select(db.transactions).get(), isEmpty);
    },
  );

  test('quoted replies stay visible in the model history', () async {
    final provider = _ScriptedProvider([
      [const AIStreamText('باشه.'), const AIStreamDone()],
    ]);
    final service = AIChatService(
      providers: _FakeRegistry(provider),
      tools: tools,
      executor: executor,
    );
    final history = [
      ChatMessage(
        id: 'm1',
        sessionId: 'session-1',
        role: ChatRole.user,
        content: 'ناهار ۲۵۰ هزار تومان بود',
        type: ChatMessageType.text,
        metadata: const {'replyToPreview': 'پیش‌نویس ناهار'},
        createdAt: DateTime.utc(2026, 11, 6, 10),
      ),
      ChatMessage(
        id: 'm2',
        sessionId: 'session-1',
        role: ChatRole.user,
        content: 'تأییدش کن',
        type: ChatMessageType.text,
        metadata: const {
          'smsFocusLabel': 'پاسخ به پیشنهاد · پارکینگ',
          'smsReplyTo': 'sms-1',
        },
        createdAt: DateTime.utc(2026, 11, 6, 11),
      ),
    ];

    await service
        .run(
          config: config(AIToolMode.native),
          systemPrompt: 'system',
          history: history,
          userMessage: 'خب؟',
          sessionId: 'session-1',
          defaultCurrency: CurrencyUnit.toman,
        )
        .toList();

    final sent = provider.lastMessages!;
    expect(
      sent.any(
        (message) =>
            message.role == AIRole.user &&
            message.content.contains('«پاسخ به پیام: پیش‌نویس ناهار»'),
      ),
      isTrue,
    );
    expect(
      sent.any(
        (message) => message.content.contains(
          '«پاسخ به کارت پیامکی: پاسخ به پیشنهاد · پارکینگ»',
        ),
      ),
      isTrue,
    );
  });

  test('JSON fallback parses the envelope and creates a draft', () async {
    final envelope = {
      'message': 'هزینه ناهار آماده شد؛ تأیید می‌کنی؟',
      'actions': [
        {
          'tool': 'add_transaction',
          'arguments': {
            'type': 'expense',
            'amount': 250000,
            'amount_unit': 'toman',
            'date': '2026-11-06',
            'category': 'خوراک و رستوران',
            'account': 'حساب ملت',
          },
        },
      ],
    };
    final provider = _ScriptedProvider([
      [
        AIStreamText('```json\n${jsonEncode(envelope)}\n```'),
        const AIStreamDone(),
      ],
    ]);
    final service = AIChatService(
      providers: _FakeRegistry(provider),
      tools: tools,
      executor: executor,
    );

    final events = await service
        .run(
          config: config(AIToolMode.json),
          systemPrompt: 'system',
          history: const [],
          userMessage: 'ناهار',
          sessionId: 'session-1',
          defaultCurrency: CurrencyUnit.toman,
        )
        .toList();
    final completed = events.whereType<ChatRunCompleted>().single;
    expect(completed.text, contains('هزینه ناهار'));
    expect(completed.actions, hasLength(1));
    expect(completed.actions.single.payload['amountRial'], 2500000);
  });

  test('JSON fallback retries once after malformed output', () async {
    final valid = jsonEncode({'message': 'آماده است.', 'actions': const []});
    final provider = _ScriptedProvider([
      [const AIStreamText('this is not json'), const AIStreamDone()],
      [AIStreamText(valid), const AIStreamDone()],
    ]);
    final service = AIChatService(
      providers: _FakeRegistry(provider),
      tools: tools,
      executor: executor,
    );
    final events = await service
        .run(
          config: config(AIToolMode.json),
          systemPrompt: 'system',
          history: const [],
          userMessage: 'سلام',
          sessionId: 'session-1',
          defaultCurrency: CurrencyUnit.toman,
        )
        .toList();
    expect(provider.calls, 2);
    expect(events.whereType<ChatRunCompleted>().single.text, 'آماده است.');
  });

  test('a missing API key fails before any network call', () async {
    final provider = _ScriptedProvider([
      [const AIStreamDone()],
    ]);
    final service = AIChatService(
      providers: _FakeRegistry(provider),
      tools: tools,
      executor: executor,
    );
    final events = await service
        .run(
          config: const AIConfig(
            provider: AIProviderKind.openAICompatible,
            baseUrl: 'https://example.com/v1',
            model: 'test',
            apiKey: '',
          ),
          systemPrompt: 'system',
          history: const [],
          userMessage: 'سلام',
          sessionId: 'session-1',
          defaultCurrency: CurrencyUnit.toman,
        )
        .toList();
    expect(events.single, isA<ChatRunFailed>());
    expect(provider.calls, 0);
  });

  test('native loop forwards SMS suggestion ids for chat cards', () async {
    final account = (await db.select(db.accounts).get()).single;
    await db
        .into(db.smsSuggestions)
        .insert(
          SmsSuggestionsCompanion.insert(
            id: 'sms-ai-1',
            sender: '1001',
            receivedAt: DateTime.utc(2026, 11, 6, 10),
            template: 'برداشت: [n0] ریال',
            payload: jsonEncode({
              'type': 'expense',
              'amountRial': 2000000,
              'accountId': account.id,
              'accountName': account.accountName,
              'categoryId': 'cat_food',
              'categoryName': 'خوراک و رستوران',
              'date': '2026-11-06',
              'description': 'پارکینگ',
            }),
            status: const Value('pending'),
          ),
        );
    final provider = _ScriptedProvider([
      [
        AIStreamToolCalls([
          const ToolCall(
            id: 'sms-call',
            name: 'review_sms_suggestions',
            arguments: {},
          ),
        ]),
        const AIStreamDone(finishReason: 'tool_calls'),
      ],
      [
        const AIStreamText('این پیشنهاد را ببین و بگو تأیید می‌کنی یا نه.'),
        const AIStreamDone(finishReason: 'stop'),
      ],
    ]);
    final service = AIChatService(
      providers: _FakeRegistry(provider),
      tools: tools,
      executor: executor,
    );

    final events = await service
        .run(
          config: config(AIToolMode.native),
          systemPrompt: 'system',
          history: const [],
          userMessage: 'پیامک‌ها را نشانم بده',
          sessionId: 'session-1',
          defaultCurrency: CurrencyUnit.toman,
        )
        .toList();
    final completed = events.whereType<ChatRunCompleted>().single;
    expect(completed.smsSuggestionIds, ['sms-ai-1']);
    expect(completed.text, contains('تأیید'));
    expect(completed.actions, isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
  });
}
