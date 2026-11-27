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
import 'package:daram/features/assets/data/asset_repository.dart';
import 'package:daram/features/assets/domain/asset_quantity.dart';
import 'package:daram/features/obligations/data/obligation_repository.dart';
import 'package:daram/features/transactions/data/transfer_repository.dart';
import 'package:flutter/material.dart' show ThemeMode;
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
    await chat.createSession(id: 'session-1', title: 'test');
    executor = ToolExecutor(
      registry: registry,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      loans: loans,
      analytics: analytics,
      sms: sms,
      chat: chat,
      assets: AssetRepository(db),
      obligations: ObligationRepository(db),
      transfers: TransferRepository(db, operations),
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

  Future<String> persistDraft(ToolExecution execution) async {
    final action = execution.pendingAction!;
    await chat.addPendingActions([action]);
    return action.id;
  }

  test('query_records returns ids and totals for transactions', () async {
    final transactions = TransactionRepository(db, OperationRepository(db));
    final account = (await accounts.list()).first;
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(120000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: CalendarDate(2026, 11, 6),
      description: 'ناهار',
      operationId: 'op-records-1',
    );
    final result = await run('query_records', {
      'record_type': 'transactions',
      'date_range': {'start': '2026-11-01', 'end': '2026-11-30'},
    });
    expect(result.ok, isTrue);
    final content = jsonDecode(result.content) as Map;
    final items = content['items'] as List;
    expect(items, hasLength(1));
    final item = items.single as Map;
    expect(item['id'], isNotEmpty);
    expect(item['amount_rial'], 1200000);
    expect((content['totals'] as Map)['expense_rial'], 1200000);
  });

  test(
    'get_financial_overview computes net worth from every section',
    () async {
      final assetRepository = AssetRepository(db);
      await assetRepository.save(
        name: 'طلای من',
        kind: AssetKind.gold,
        quantity: AssetQuantity.tryParse('2')!,
        rate: Rial(30000000),
        rateDate: DateTime.utc(2026, 11, 6),
        isMarketRate: false,
      );
      final obligations = ObligationRepository(db);
      await obligations.save(
        counterparty: 'رضا',
        isReceivable: true,
        amount: Rial(5000000),
      );
      await obligations.save(
        counterparty: 'سارا',
        isReceivable: false,
        amount: Rial(3000000),
      );
      final result = await run('get_financial_overview', {'months': 6});
      expect(result.ok, isTrue, reason: result.content);
      final content = jsonDecode(result.content) as Map;
      final overview = content['overview'] as Map;
      // 10,000,000 cash + 60,000,000 gold + 5,000,000 receivable - 3,000,000.
      expect(overview['net_worth_rial'], 72000000);
      expect(overview['cash_rial'], 10000000);
      expect(overview['assets_rial'], 60000000);
      expect(overview['receivables_rial'], 5000000);
      expect(overview['payables_rial'], 3000000);
      final health = overview['health'] as Map;
      expect(health['score'], isA<int>());
      expect(overview['roadmap'] as List, isNotEmpty);
      expect(result.report, isNotNull);
      expect(result.report!['kind'], 'financial_overview');
    },
  );

  test('manage_transaction builds an update draft and keeps the id', () async {
    final transactions = TransactionRepository(db, OperationRepository(db));
    final account = (await accounts.list()).first;
    final created = await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(200000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: CalendarDate(2026, 11, 6),
      description: 'ناهار',
      operationId: 'op-manage-tx',
    );
    final result = await run('manage_transaction', {
      'action': 'update',
      'transaction_id': created.id,
      'amount': 350000,
      'amount_unit': 'toman',
      'category': 'سفر',
    });
    expect(result.ok, isTrue, reason: result.content);
    final payload = result.pendingAction!.payload;
    expect(payload['recordType'], 'transaction');
    expect(payload['action'], 'update');
    expect(payload['recordId'], created.id);
    final fields = payload['fields'] as Map;
    expect(fields['amountRial'], 3500000);
    expect(fields['categoryId'], 'cat_travel');
    expect(fields['type'], 'expense');
  });

  test('manage_transaction finds a transaction by description', () async {
    final transactions = TransactionRepository(db, OperationRepository(db));
    final account = (await accounts.list()).first;
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(90000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: CalendarDate(2026, 11, 6),
      description: 'تاکسی فرودگاه',
      operationId: 'op-match-tx',
    );
    final result = await run('manage_transaction', {
      'action': 'delete',
      'match_description': 'فرودگاه',
    });
    expect(result.ok, isTrue, reason: result.content);
    expect(result.pendingAction!.payload['action'], 'delete');
  });

  test('update_pending_draft revalidates and edits the same draft', () async {
    final created = await run('add_transaction', {
      'type': 'expense',
      'amount': 250000,
      'amount_unit': 'toman',
      'date': 'امروز',
      'category': 'خوراک و رستوران',
      'account': 'ملت',
      'description': 'ناهار',
    });
    final actionId = await persistDraft(created);
    final updated = await run('update_pending_draft', {
      'action_id': actionId,
      'changes': {
        'amount': 300000,
        'amount_unit': 'toman',
        'category': 'سفر',
        'date': 'دیروز',
      },
    });
    expect(updated.ok, isTrue, reason: updated.content);
    final stored = (await chat.findPendingAction(actionId))!;
    expect(stored.isPending, isTrue);
    expect(stored.payload['amountRial'], 3000000);
    expect(stored.payload['categoryId'], 'cat_travel');
    expect(stored.payload['description'], 'ناهار');
  });

  test('a bare amount change keeps the user display unit', () async {
    final created = await run('add_transaction', {
      'type': 'expense',
      'amount': 250000,
      'amount_unit': 'toman',
      'date': 'امروز',
      'category': 'خوراک و رستوران',
      'account': 'ملت',
    });
    final actionId = await persistDraft(created);
    final updated = await run('update_pending_draft', {
      'action_id': actionId,
      'changes': {'amount': 300000},
    });
    expect(updated.ok, isTrue, reason: updated.content);
    final stored = (await chat.findPendingAction(actionId))!;
    // Default currency is Toman in this test, so 300,000 means 3,000,000 Rial.
    expect(stored.payload['amountRial'], 3000000);
  });

  test('editing a transfer amount keeps the rial fee intact', () async {
    await accounts.create(
      bankId: 'blue',
      bankName: 'بلو بانک',
      accountName: 'بلو',
      accountType: AccountType.bank,
      initialBalance: Rial.zero,
      operationId: 'op-blue-edit',
    );
    final created = await run('add_transfer', {
      'source_account': 'ملت',
      'destination_account': 'بلو',
      'amount': 500000,
      'amount_unit': 'toman',
      'fee_amount': 5000,
      'date': 'امروز',
    });
    expect(created.ok, isTrue, reason: created.content);
    final actionId = await persistDraft(created);
    final updated = await run('update_pending_draft', {
      'action_id': actionId,
      'changes': {'amount': 700000},
    });
    expect(updated.ok, isTrue, reason: updated.content);
    final stored = (await chat.findPendingAction(actionId))!;
    expect(stored.payload['amountRial'], 7000000);
    expect(stored.payload['feeRial'], 50000);
  });

  test('an explicit toman unit also keeps the rial fee intact', () async {
    await accounts.create(
      bankId: 'blue',
      bankName: 'بلو بانک',
      accountName: 'بلو',
      accountType: AccountType.bank,
      initialBalance: Rial.zero,
      operationId: 'op-blue-edit-2',
    );
    final created = await run('add_transfer', {
      'source_account': 'ملت',
      'destination_account': 'بلو',
      'amount': 500000,
      'amount_unit': 'toman',
      'fee_amount': 5000,
      'date': 'امروز',
    });
    final actionId = await persistDraft(created);
    final updated = await run('update_pending_draft', {
      'action_id': actionId,
      'changes': {'amount': 900000, 'amount_unit': 'toman'},
    });
    expect(updated.ok, isTrue, reason: updated.content);
    final stored = (await chat.findPendingAction(actionId))!;
    expect(stored.payload['amountRial'], 9000000);
    expect(stored.payload['feeRial'], 50000);
  });

  test('cancel_pending_draft rejects the draft without writing', () async {
    final created = await run('add_transaction', {
      'type': 'expense',
      'amount': 250000,
      'amount_unit': 'toman',
      'date': 'امروز',
      'category': 'خوراک و رستوران',
      'account': 'ملت',
    });
    final actionId = await persistDraft(created);
    final cancelled = await run('cancel_pending_draft', {
      'action_id': actionId,
    });
    expect(cancelled.ok, isTrue, reason: cancelled.content);
    final stored = (await chat.findPendingAction(actionId))!;
    expect(stored.isPending, isFalse);
    expect(stored.status.labelFa, 'رد شده');
    expect(await db.select(db.transactions).get(), isEmpty);
  });

  test('manage_account archives and manage_loan deletes by id', () async {
    final account = (await accounts.list()).first;
    final archive = await run('manage_account', {
      'action': 'archive',
      'account_id': account.id,
    });
    expect(archive.ok, isTrue, reason: archive.content);
    expect(archive.pendingAction!.payload['action'], 'archive');

    final loans = LoanRepository(db, OperationRepository(db));
    final loan = await loans.create(
      title: 'وام تست',
      principal: Rial.fromToman(1000000),
      installmentCount: 2,
      startDate: CalendarDate(2026, 11, 1),
      dueDates: [CalendarDate(2026, 12, 1), CalendarDate(2027, 1, 1)],
      operationId: 'op-loan-manage',
    );
    final delete = await run('manage_loan', {
      'action': 'delete',
      'loan_id': loan.id,
    });
    expect(delete.ok, isTrue, reason: delete.content);
    expect(delete.pendingAction!.payload['action'], 'delete');
  });

  test('manage_asset and manage_obligation build canonical drafts', () async {
    final asset = await run('manage_asset', {
      'action': 'create',
      'name': 'دلار نقدی',
      'kind': 'currency',
      'currency_code': 'USD',
      'quantity': 100,
      'rate': 100000,
      'amount_unit': 'toman',
    });
    expect(asset.ok, isTrue, reason: asset.content);
    final fields = asset.pendingAction!.payload['fields'] as Map;
    expect(fields['kind'], 'currency');
    expect(fields['quantityMicros'], 100000000);
    expect(fields['rateRial'], 1000000);

    final obligation = await run('manage_obligation', {
      'action': 'create',
      'counterparty': 'علی',
      'is_receivable': false,
      'amount': 500000,
      'amount_unit': 'toman',
    });
    expect(obligation.ok, isTrue, reason: obligation.content);
    final obligationFields = obligation.pendingAction!.payload['fields'] as Map;
    expect(obligationFields['isReceivable'], isFalse);
    expect(obligationFields['amountRial'], 5000000);
  });

  test('update_settings reports an immediate settings change', () async {
    final result = await run('update_settings', {
      'theme_mode': 'dark',
      'currency_unit': 'rial',
      'persian_digits': false,
    });
    expect(result.ok, isTrue, reason: result.content);
    expect(result.pendingAction, isNull);
    final change = result.settingsChange!;
    expect(change.themeMode, ThemeMode.dark);
    expect(change.currencyUnit, CurrencyUnit.rial);
    expect(change.persianDigits, isFalse);
    expect(change.summaryFa, contains('تاریک'));
  });
}
