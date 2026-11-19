import 'dart:convert';

import 'package:daram/core/domain/enums.dart';
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
import 'package:daram/features/dashboard/data/analytics_repository.dart';
import 'package:daram/features/loans/data/loan_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ToolExecutor executor;
  late AccountRepository accounts;

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
    executor = ToolExecutor(
      registry: registry,
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      loans: loans,
      analytics: analytics,
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
    final result = await run('generate_report', {
      'start_date': '2026-11-01',
      'end_date': '2026-11-30',
      'grouping': 'category',
    });
    expect(result.ok, isTrue);
    expect(result.report, isNotNull);
    expect(result.report!['summary'], isA<Map>());
  });
}
