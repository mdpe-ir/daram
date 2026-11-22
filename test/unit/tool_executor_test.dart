import 'dart:convert';

import 'package:daram/core/domain/enums.dart';
import 'package:drift/drift.dart' show Value;
import 'package:daram/core/money/currency.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/ai/data/argument_parser.dart';
import 'package:daram/features/ai/data/tool_executor.dart';
import 'package:daram/features/ai/data/tool_registry.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/chat/data/chat_repository.dart';
import 'package:daram/features/chat/domain/drafts.dart';
import 'package:daram/features/dashboard/data/analytics_repository.dart';
import 'package:daram/features/loans/data/loan_repository.dart';
import 'package:daram/features/sms/data/sms_review_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ToolExecutor executor;
  late AccountRepository accounts;
  late SmsReviewRepository sms;
  late ChatRepository chat;

  setUp(() async {
    db = AppDatabase.memory();
    final operations = OperationRepository(db);
    final categories = CategoryRepository(db);
    await categories.ensureDefaults();
    accounts = AccountRepository(db, operations);
    final transactions = TransactionRepository(db, operations);
    final loans = LoanRepository(db, operations);
    await accounts.create(
      bankId: 'mellat',
      bankName: 'بانک ملت',
      accountName: 'حساب ملت',
      accountType: AccountType.bank,
      initialBalance: Rial.fromToman(1000000),
      operationId: 'op-account',
    );
    final analytics = AnalyticsRepository(db, accounts, transactions, loans);
    final registry = await ToolRegistry.load(rootBundle);
    sms = SmsReviewRepository(db, transactions);
    chat = ChatRepository(db);
    executor = ToolExecutor(
      registry: registry,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      loans: loans,
      analytics: analytics,
      sms: sms,
      chat: chat,
      parser: ArgumentParser(today: CalendarDate(2026, 11, 6)),
    );
  });

  tearDown(() async => db.close());

  Future<ToolExecution> run(String name, Map<String, Object?> args) =>
      executor.execute(
        ToolCall(id: 'call-1', name: name, arguments: args),
        sessionId: 'session-1',
        defaultCurrency: CurrencyUnit.toman,
      );

  Future<String> seedSms({
    String id = 'sms-1',
    String status = 'pending',
    int amountRial = 2000000,
    String description = 'پارکینگ',
    String template = 'برداشت: [n0] ریال',
  }) async {
    final account = (await accounts.list()).first;
    final hasAmount = amountRial > 0;
    final draft = TransactionDraft(
      type: TransactionType.expense,
      amountRial: Rial(amountRial),
      accountId: hasAmount ? account.id : '',
      accountName: hasAmount ? account.accountName : '',
      categoryId: hasAmount ? 'cat_food' : null,
      categoryName: hasAmount ? 'خوراک و رستوران' : null,
      date: CalendarDate(2026, 11, 6),
      description: description,
    );
    await db
        .into(db.smsSuggestions)
        .insert(
          SmsSuggestionsCompanion.insert(
            id: id,
            sender: '1001',
            receivedAt: DateTime.utc(2026, 11, 6, 10),
            template: template,
            payload: jsonEncode(draft.toPayload()),
            status: Value(status),
          ),
        );
    return id;
  }

  Future<String> presentSms(String suggestionId) async {
    final session = await chat.createSession(title: 'sms');
    await chat.addMessage(
      sessionId: session.id,
      role: ChatRole.assistant,
      content: 'این پیشنهاد پیامکی را ببین.',
      type: ChatMessageType.text,
      metadata: {
        'smsSuggestionIds': [suggestionId],
      },
    );
    return session.id;
  }

  Future<ToolExecution> runSms(
    String sessionId,
    String name,
    Map<String, Object?> args,
  ) => executor.execute(
    ToolCall(id: 'sms-call', name: name, arguments: args),
    sessionId: sessionId,
    defaultCurrency: CurrencyUnit.toman,
  );

  test(
    'agent manages categories immediately and rejects duplicate rename',
    () async {
      final created = await run('manage_category', {
        'action': 'create',
        'type': 'expense',
        'name': 'تست دسته',
        'icon': 'coffee',
        'color_hex': '#22c55e',
      });
      expect(created.ok, isTrue);
      expect(created.pendingAction, isNull);
      final content = jsonDecode(created.content) as Map;
      expect(content['icon'], 'coffee');
      expect(content['color_hex'], '#22C55E');
      final id = content['category_id'];
      final renamed = await run('manage_category', {
        'action': 'rename',
        'type': 'expense',
        'category_id': id,
        'name': 'نام تازه',
        'icon': 'pizza',
      });
      expect(renamed.ok, isTrue);
      final stored = (await CategoryRepository(db).findById(id as String))!;
      expect(stored.name, 'نام تازه');
      expect(stored.icon, 'pizza');
      expect(stored.colorHex, '#22C55E');
      final duplicate = await run('manage_category', {
        'action': 'rename',
        'type': 'expense',
        'category_id': id,
        'name': 'خوراک و رستوران',
      });
      expect(duplicate.ok, isFalse);
      final wrongType = await run('manage_category', {
        'action': 'delete',
        'type': 'income',
        'category_id': id,
      });
      expect(wrongType.ok, isFalse);
      final deleted = await run('manage_category', {
        'action': 'delete',
        'type': 'expense',
        'category_id': id,
      });
      expect(deleted.ok, isTrue);
      expect(await CategoryRepository(db).findById(id), isNull);
    },
  );

  test('category creation picks a fitting style when omitted', () async {
    final coffee = await run('manage_category', {
      'action': 'create',
      'type': 'expense',
      'name': 'قهوه',
    });
    final coffeeContent = jsonDecode(coffee.content) as Map;
    expect(coffeeContent['icon'], 'coffee');
    expect(coffeeContent['color_hex'], '#F97316');

    final gym = await run('manage_category', {
      'action': 'create',
      'type': 'expense',
      'name': 'باشگاه ورزشی',
    });
    final gymContent = jsonDecode(gym.content) as Map;
    expect(gymContent['icon'], 'dumbbell');
    expect(gymContent['color_hex'], '#14B8A6');

    final travel = await run('manage_category', {
      'action': 'create',
      'type': 'expense',
      'name': 'سفر خارجی',
      'icon': 'tag',
      'color_hex': '#8B5CF6',
    });
    final travelContent = jsonDecode(travel.content) as Map;
    expect(travelContent['icon'], 'plane');
    expect(travelContent['color_hex'], '#06B6D4');
    expect(
      await CategoryRepository(db)
          .findById(coffeeContent['category_id'] as String),
      isNotNull,
    );
  });

  test(
    'renaming can replace generic tag/purple with a fitting style',
    () async {
      final created = await run('manage_category', {
        'action': 'create',
        'type': 'expense',
        'name': 'دسته من',
        'icon': 'tag',
        'color_hex': '#8B5CF6',
      });
      final createdContent = jsonDecode(created.content) as Map;
      final id = createdContent['category_id'] as String;

      final renamed = await run('manage_category', {
        'action': 'rename',
        'type': 'expense',
        'category_id': id,
        'name': 'قهوه',
        'icon': 'tag',
        'color_hex': '#8B5CF6',
      });
      final renamedContent = jsonDecode(renamed.content) as Map;
      expect(renamedContent['icon'], 'coffee');
      expect(renamedContent['color_hex'], '#F97316');
    },
  );

  test('category management rejects missing fields and unknown ids', () async {
    for (final args in <Map<String, Object?>>[
      {'action': 'create', 'type': 'expense'},
      {
        'action': 'rename',
        'type': 'expense',
        'category_id': 'missing',
        'name': 'نام',
      },
      {'action': 'delete', 'type': 'expense'},
    ]) {
      expect((await run('manage_category', args)).ok, isFalse);
    }
  });

  test(
    'category management rejects an unknown icon and a bad colour',
    () async {
      final unknownIcon = await run('manage_category', {
        'action': 'create',
        'type': 'expense',
        'name': 'آیکون ناموجود',
        'icon': 'rocket-ship',
      });
      expect(unknownIcon.ok, isFalse);
      expect(unknownIcon.content, contains('آیکون'));

      final badColor = await run('manage_category', {
        'action': 'create',
        'type': 'expense',
        'name': 'رنگ ناموجود',
        'color_hex': 'green',
      });
      expect(badColor.ok, isFalse);
      expect(
        (await CategoryRepository(db).list(type: CategoryType.expense))
            .any((item) => item.name == 'آیکون ناموجود'),
        isFalse,
      );
    },
  );

  test('add_transaction creates a validated pending draft only', () async {
    final result = await run('add_transaction', {
      'type': 'expense',
      'amount': 250000,
      'amount_unit': 'toman',
      'date': 'امروز',
      'category': 'خوراک و رستوران',
      'account': 'ملت',
      'description': 'ناهار',
    });

    expect(result.ok, isTrue);
    expect(result.pendingAction, isNotNull);
    expect(result.pendingAction!.payload['amountRial'], 2500000);
    expect(result.pendingAction!.payload['categoryId'], 'cat_food');
    expect(result.pendingAction!.payload['description'], 'ناهار');
    // Nothing is written before confirmation.
    expect(await db.select(db.transactions).get(), isEmpty);
    expect(await db.select(db.ledgerEntries).get(), isEmpty);
  });

  test('unknown accounts produce a helpful tool error and no draft', () async {
    final result = await run('add_transaction', {
      'type': 'expense',
      'amount': 10000,
      'amount_unit': 'toman',
      'date': 'امروز',
      'category': 'خرید',
      'account': 'حساب ناموجود',
    });
    expect(result.ok, isFalse);
    expect(result.pendingAction, isNull);
    final content = jsonDecode(result.content) as Map<String, Object?>;
    expect('${content['error']}', contains('حساب'));
  });

  test('transfer drafts record an explicit fee', () async {
    await accounts.create(
      bankId: 'blue',
      bankName: 'بلو بانک',
      accountName: 'بلو',
      accountType: AccountType.bank,
      initialBalance: Rial.zero,
      operationId: 'op-blue',
    );
    final result = await run('add_transfer', {
      'source_account': 'ملت',
      'destination_account': 'بلو',
      'amount': 500000,
      'amount_unit': 'toman',
      'fee_amount': 5000,
      'date': 'دیروز',
    });
    expect(result.ok, isTrue);
    expect(result.pendingAction!.payload['amountRial'], 5000000);
    expect(result.pendingAction!.payload['feeRial'], 50000);
    expect(result.pendingAction!.payload['sourceAccountName'], 'حساب ملت');
  });

  test('loans without due dates are rejected before drafting', () async {
    final result = await run('add_loan', {
      'title': 'وام',
      'principal_amount': 30000000,
      'amount_unit': 'toman',
      'installment_count': 3,
      'start_date': 'امروز',
    });
    expect(result.ok, isFalse);
    expect(result.pendingAction, isNull);
  });

  test('query_transactions computes totals from the database', () async {
    final transactions = TransactionRepository(db, OperationRepository(db));
    final account = (await accounts.list()).first;
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(200000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: CalendarDate(2026, 11, 6),
      operationId: 'op-seed-expense',
    );
    final result = await run('query_transactions', {
      'date_range': {'start': '2026-11-01', 'end': '2026-11-30'},
      'transaction_type': 'all',
    });
    expect(result.ok, isTrue);
    final content = jsonDecode(result.content) as Map<String, Object?>;
    final totals = content['totals']! as Map<String, Object?>;
    expect(totals['expense_rial'], 2000000);
    expect(totals['count'], 1);
    final range = content['date_range'] as Map;
    expect(range['label_numeric_fa'], '۱۴۰۵/۰۸/۱۰ تا ۱۴۰۵/۰۹/۰۹');
    final item = (content['items'] as List).single as Map;
    expect(item['date_jalali'], '1405/08/15');
    expect(item['date_label_fa'], '۱۵ آبان ۱۴۰۵');
  });

  test(
    'query returns exact display amounts for 20500 toman in either unit',
    () async {
      final transactions = TransactionRepository(db, OperationRepository(db));
      await transactions.create(
        type: TransactionType.expense,
        amount: Rial.fromToman(20500),
        accountId: (await accounts.list()).first.id,
        categoryId: 'cat_food',
        date: CalendarDate(2026, 11, 6),
        operationId: 'op-20500',
      );
      for (final unit in CurrencyUnit.values) {
        final result = await executor.execute(
          ToolCall(
            id: 'last-transaction',
            name: 'query_transactions',
            arguments: {
              'date_range': {'start': '2026-11-01', 'end': '2026-11-30'},
              'limit': 1,
            },
          ),
          sessionId: 'session-1',
          defaultCurrency: unit,
        );
        expect(result.ok, isTrue);
        final content = jsonDecode(result.content) as Map;
        final item = (content['items'] as List).single as Map;
        final display = unit == CurrencyUnit.toman
            ? '۲۰,۵۰۰ تومان'
            : '۲۰۵,۰۰۰ ریال';
        expect(content['display_currency'], unit.name);
        expect(item['amount_rial'], 205000);
        expect(item['amount_display'], display);
        expect((content['totals'] as Map)['expense_display'], display);
      }
    },
  );

  test('generate_report attaches a serialised report', () async {
    final transactions = TransactionRepository(db, OperationRepository(db));
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(250000),
      accountId: (await accounts.list()).first.id,
      categoryId: 'cat_food',
      date: CalendarDate(2026, 11, 6),
      operationId: 'op-report-seed',
    );
    final result = await run('generate_report', {
      'start_date': '2026-11-01',
      'end_date': '2026-11-30',
      'grouping': 'category',
    });
    expect(result.ok, isTrue);
    expect(result.report, isNotNull);
    expect(result.report!['summary'], isA<Map>());

    final content = jsonDecode(result.content) as Map;
    final report = content['report'] as Map;
    final range = report['date_range'] as Map;
    expect(range['label_numeric_fa'], '۱۴۰۵/۰۸/۱۰ تا ۱۴۰۵/۰۹/۰۹');
    expect(range['label_fa'], '۱۰ آبان ۱۴۰۵ تا ۹ آذر ۱۴۰۵');
    expect(report['income_display'], '۰ تومان');
    expect(report['expense_display'], '۲۵۰,۰۰۰ تومان');
    expect('${report['net_display']}', contains('۲۵۰,۰۰۰'));
    final category = (report['categories'] as List).single as Map;
    expect(category['amount_display'], '۲۵۰,۰۰۰ تومان');
    expect(category['share_display'], '۱۰۰٪');
  });

  test('review_sms_suggestions returns cards and exact ids', () async {
    final id = await seedSms();
    final result = await run('review_sms_suggestions', {});
    expect(result.ok, isTrue);
    expect(result.smsSuggestionIds, [id]);
    final content = jsonDecode(result.content) as Map;
    expect(content['count'], 1);
    final item = (content['suggestions'] as List).single as Map;
    expect(item['suggestion_id'], id);
    expect(item['amount_rial'], 2000000);
    expect(item['amount_display'], '۲۰۰,۰۰۰ تومان');
    expect(item['ready_to_confirm'], isTrue);
    expect(item['date_jalali'], '15 آبان 1405');
  });

  test('SMS decisions are rejected until the suggestion was shown', () async {
    final id = await seedSms();
    final session = await chat.createSession(title: 'no history');
    final result = await runSms(session.id, 'confirm_sms_suggestion', {
      'suggestion_id': id,
    });
    expect(result.ok, isFalse);
    expect(result.content, contains('نمایش داده نشده'));
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test(
    'edit_sms_suggestion can update before the suggestion is shown',
    () async {
      final id = await seedSms(status: 'needsReview', amountRial: 0);
      final session = await chat.createSession(title: 'edit first');
      final edited = await runSms(session.id, 'edit_sms_suggestion', {
        'suggestion_id': id,
        'amount': 250000,
        'amount_unit': 'toman',
        'account': 'ملت',
        'category': 'حمل‌ونقل',
        'description': 'تاکسی',
      });
      expect(edited.ok, isTrue);
      final row = (await sms.find(id))!;
      expect(row.status, 'pending');
      expect(row.editedAt, isNotNull);

      // Editing is not a financial write, but confirming still requires the
      // suggestion to have been shown in the conversation.
      final confirm = await runSms(session.id, 'confirm_sms_suggestion', {
        'suggestion_id': id,
      });
      expect(confirm.ok, isFalse);
      expect(confirm.content, contains('نمایش داده نشده'));
      expect(await db.select(db.transactions).get(), isEmpty);
    },
  );

  test('confirm_sms_suggestion records the shown suggestion', () async {
    final id = await seedSms();
    final session = await presentSms(id);
    final result = await runSms(session, 'confirm_sms_suggestion', {
      'suggestion_id': id,
    });
    expect(result.ok, isTrue);
    final rows = await db.select(db.transactions).get();
    expect(rows.single.amountRial, 2000000);
    expect(rows.single.operationId, 'sms:$id');
    expect((await sms.find(id))!.status, 'confirmed');
  });

  test('edit_sms_suggestion makes a needsReview row confirmable', () async {
    final id = await seedSms(status: 'needsReview', amountRial: 0);
    final session = await presentSms(id);
    final edited = await runSms(session, 'edit_sms_suggestion', {
      'suggestion_id': id,
      'amount': 250000,
      'amount_unit': 'toman',
      'account': 'ملت',
      'category': 'حمل‌ونقل',
      'date': '2026-11-05',
      'description': 'تاکسی',
    });
    expect(edited.ok, isTrue);
    final row = (await sms.find(id))!;
    expect(row.status, 'pending');
    expect(row.editedAt, isNotNull);
    final draft = SmsReviewRepository.draftOf(row);
    expect(draft.amountRial, Rial.fromToman(250000));
    expect(draft.accountId, isNotEmpty);
    expect(draft.categoryId, 'cat_transport');
    expect(draft.description, 'تاکسی');
    expect(draft.date, CalendarDate(2026, 11, 5));

    final confirmed = await runSms(session, 'confirm_sms_suggestion', {
      'suggestion_id': id,
    });
    expect(confirmed.ok, isTrue);
    expect((await sms.find(id))!.status, 'confirmed');
  });

  test('dismiss_sms_suggestion can ignore the whole template', () async {
    final first = await seedSms();
    final second = await seedSms(id: 'sms-2');
    final session = await presentSms(first);
    final result = await runSms(session, 'dismiss_sms_suggestion', {
      'suggestion_id': first,
      'ignore_pattern': true,
    });
    expect(result.ok, isTrue);
    expect((await sms.find(first))!.status, 'dismissed');
    expect((await sms.find(second))!.status, 'dismissed');
  });

  test('confirm_sms_suggestion refuses an incomplete draft', () async {
    final id = await seedSms(status: 'needsReview', amountRial: 0);
    final session = await presentSms(id);
    final result = await runSms(session, 'confirm_sms_suggestion', {
      'suggestion_id': id,
    });
    expect(result.ok, isFalse);
    expect(result.content, contains('مبلغ'));
    expect(await db.select(db.transactions).get(), isEmpty);
  });
}
