import 'dart:convert';

import 'package:daram/app/app.dart';
import 'package:daram/app/app_providers.dart';
import 'package:daram/app/theme/daram_theme.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/chat/data/chat_repository.dart';
import 'package:daram/features/chat/presentation/sms_chat_focus_controller.dart';
import 'package:daram/features/chat/presentation/sms_suggestion_cards.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:daram/features/sms/presentation/sms_controller.dart';
import 'package:daram/features/transactions/domain/transaction_record.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

void main() {
  testWidgets(
    'reviews and confirms a matched SMS from chat on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now().millisecondsSinceEpoch;
      final calls = <String>[];
      const channel = MethodChannel('ir.daram.daram/sms');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return switch (call.method) {
          'hasPermission' => true,
          'observe' => null,
          'messages' => [
            {
              'id': 1,
              'sender': '1001',
              'date': now,
              'body': 'برداشت: ۲۰۰٬۰۰۰ ریال',
            },
            {
              'id': 2,
              'sender': '1002',
              'date': now,
              'body': 'صورتحساب پارکینگ: ۲۰٬۰۰۰ تومان',
            },
            {
              'id': 4,
              'sender': '1004',
              'date': now,
              'body': 'بانک ملت\nواریز: ۳۰۰٬۰۰۰ ریال',
            },
            {
              'id': 3,
              'sender': '1001',
              'date': now,
              'body': 'رمز دوم: ۹۹۹۹۹ مبلغ: ۲۰۰٬۰۰۰ ریال',
            },
          ],
          _ => throw MissingPluginException(call.method),
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      SharedPreferences.setMockInitialValues({
        'settings.onboarding_complete': true,
        'sms.enabled': true,
      });
      final settings = SettingsRepository(
        await SharedPreferences.getInstance(),
        TestKeyStore(''),
      );
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(settings),
        ],
      );
      addTearDown(container.dispose);
      await container.read(categoryRepositoryProvider).ensureDefaults();
      final account = await container
          .read(accountRepositoryProvider)
          .create(
            bankId: 'mellat',
            bankName: 'بانک ملت',
            accountName: 'ملت',
            accountType: AccountType.bank,
            initialBalance: Rial.zero,
            operationId: 'seed-account',
          );
      await container.read(smsReviewRepositoryProvider).setSenders(account.id, {
        '1001',
      }, includeHistory: true);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DaramApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(calls, containsAll(['observe', 'messages']));

      await tester.tap(find.byTooltip('بازبینی پیامک‌ها'));
      await tester.pumpAndSettle();
      expect(find.text('پارکینگ'), findsOneWidget);
      expect(find.text('با پیامک مرتبط تطبیق داده شد.'), findsOneWidget);
      expect(find.text('تأیید'), findsOneWidget);
      await tester.ensureVisible(find.text('تأیید'));
      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();
      expect(find.text('پیشنهاد تازه‌ای برای بازبینی نداری.'), findsOneWidget);
      final records = await container
          .read(transactionRepositoryProvider)
          .list(const TransactionFilter());
      expect(records.single.amountRial, Rial(200000));
      expect(records.single.description, 'پارکینگ');
      final conversation = find.text('گفتگو دربارهٔ سرشماره‌ها');
      await tester.ensureVisible(conversation);
      await tester.tap(conversation);
      await tester.pumpAndSettle();
      final sample = find.text('بانک ملت\nواریز: ۳۰۰٬۰۰۰ ریال');
      expect(sample, findsOneWidget);
      await tester.tap(find.byTooltip('حذف پیشنهاد'));
      await tester.pumpAndSettle();
      expect(sample, findsNothing);

      final previousReads = calls.where((name) => name == 'messages').length;
      await tester.tap(find.text('بررسی دوباره'));
      await tester.pumpAndSettle();
      expect(
        calls.where((name) => name == 'messages'),
        hasLength(previousReads + 1),
      );
      expect(sample, findsNothing);
      expect(
        find.text('فعلاً سرشمارهٔ بانکی تازه‌ای پیدا نکردم.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'SMS panel keeps several rows compact and confirms from details',
    (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.memory();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
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
      Future<void> seed(String id, String description, int amountRial) => db
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
      await seed('sms-chat-1', 'پارکینگ', 2000000);
      await seed('sms-chat-2', 'تاکسی', 600000);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: DaramTheme.dark(),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: SmsSuggestionCards(ids: ['sms-chat-1', 'sms-chat-2']),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('پیشنهادهای پیامکی'), findsOneWidget);
      expect(find.text('۲ مورد'), findsOneWidget);
      expect(find.text('پارکینگ'), findsOneWidget);
      expect(find.text('تاکسی'), findsOneWidget);
      expect(find.byTooltip('پاسخ در چت'), findsNWidgets(2));
      // One compact panel instead of a tall card per suggestion.
      expect(find.text('تأیید'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('پارکینگ'));
      await tester.pumpAndSettle();
      expect(find.text('تأیید'), findsOneWidget);
      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();

      final rows = await db.select(db.transactions).get();
      expect(rows.single.amountRial, 2000000);
      expect(rows.single.description, 'پارکینگ');
      expect(find.text('ثبت شد'), findsWidgets);
      expect(find.text('تأیید'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('chat composer shows SMS selection context', (tester) async {
    tester.view.physicalSize = const Size(393, 851);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.onboarding_complete': true,
      'settings.currency_unit': 'toman',
      'ai.model': 'test-model',
    });
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final settings = SettingsRepository(prefs, TestKeyStore('sk-test'));
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);
    await container.read(categoryRepositoryProvider).ensureDefaults();
    final account = await container
        .read(accountRepositoryProvider)
        .create(
          bankId: 'mellat',
          bankName: 'بانک ملت',
          accountName: 'حساب ملت',
          accountType: AccountType.bank,
          initialBalance: Rial.zero,
          operationId: 'seed-sms-account-3',
        );
    final chat = ChatRepository(db);
    final session = await chat.createSession(title: 'sms focus');
    await db
        .into(db.smsSuggestions)
        .insert(
          SmsSuggestionsCompanion.insert(
            id: 'sms-chat-1',
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
    await chat.addMessage(
      sessionId: session.id,
      role: ChatRole.assistant,
      content: 'این پیشنهاد را ببین.',
      type: ChatMessageType.text,
      metadata: {
        'smsSuggestionIds': ['sms-chat-1'],
      },
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DaramApp()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('انتخاب'));
    await tester.tap(find.text('انتخاب'));
    await tester.pump();
    await tester.ensureVisible(find.text('پارکینگ'));
    await tester.tap(find.text('پارکینگ'));
    await tester.pumpAndSettle();

    expect(find.text('۱ پیشنهاد انتخاب‌شده'), findsOneWidget);
    expect(find.text('دستور برای موارد انتخاب‌شده…'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('SMS panel supports reply and group selection', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.memory();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(categoryRepositoryProvider).ensureDefaults();
    final account = await container
        .read(accountRepositoryProvider)
        .create(
          bankId: 'mellat',
          bankName: 'بانک ملت',
          accountName: 'حساب ملت',
          accountType: AccountType.bank,
          initialBalance: Rial.zero,
          operationId: 'seed-sms-account-2',
        );
    Future<void> seed(String id, String description, int amountRial) => db
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
    await seed('sms-chat-1', 'پارکینگ', 2000000);
    await seed('sms-chat-2', 'تاکسی', 600000);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: DaramTheme.dark(),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: SmsSuggestionCards(ids: ['sms-chat-1', 'sms-chat-2']),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('پاسخ در چت').first);
    await tester.pump();
    expect(container.read(smsChatFocusProvider).replyToId, 'sms-chat-1');
    expect(container.read(smsChatFocusProvider).selectedIds, isEmpty);

    container.read(smsChatFocusProvider.notifier).clear();
    await tester.pump();
    await tester.tap(find.text('انتخاب'));
    await tester.pump();
    expect(find.text('لغو'), findsOneWidget);

    await tester.tap(find.text('پارکینگ'));
    await tester.pump();
    expect(container.read(smsChatFocusProvider).selectedIds, {'sms-chat-1'});
    expect(
      find.text('برای ۱ مورد انتخاب‌شده در چت دستور بده.'),
      findsOneWidget,
    );

    await tester.tap(find.text('همه'));
    await tester.pump();
    expect(container.read(smsChatFocusProvider).selectedIds, {
      'sms-chat-1',
      'sms-chat-2',
    });
    expect(
      find.text('برای ۲ مورد انتخاب‌شده در چت دستور بده.'),
      findsOneWidget,
    );

    await tester.tap(find.text('تاکسی'));
    await tester.pump();
    expect(container.read(smsChatFocusProvider).selectedIds, {'sms-chat-1'});
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
