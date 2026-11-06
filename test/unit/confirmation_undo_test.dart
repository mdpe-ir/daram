import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/errors/app_exception.dart';
import 'package:daram/core/money/currency.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/accounts/domain/account.dart';
import 'package:daram/features/ai/data/argument_parser.dart';
import 'package:daram/features/ai/data/tool_executor.dart';
import 'package:daram/features/ai/data/tool_registry.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/chat/data/chat_repository.dart';
import 'package:daram/features/chat/data/confirmation_service.dart';
import 'package:daram/features/chat/data/undo_service.dart';
import 'package:daram/features/dashboard/data/analytics_repository.dart';
import 'package:daram/features/loans/data/loan_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:daram/features/transactions/domain/transaction_record.dart';
import 'package:daram/features/transactions/data/transfer_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AccountRepository accounts;
  late TransactionRepository transactions;
  late ConfirmationService confirmations;
  late UndoService undo;
  late ChatRepository chat;
  late String sessionId;
  late Account account;
  late ToolExecutor executor;

  setUp(() async {
    db = AppDatabase.memory();
    final operations = OperationRepository(db);
    final categories = CategoryRepository(db);
    await categories.ensureDefaults();
    accounts = AccountRepository(db, operations);
    transactions = TransactionRepository(db, operations);
    final transfers = TransferRepository(db, operations);
    final loans = LoanRepository(db, operations);
    chat = ChatRepository(db);
    sessionId = (await chat.createSession(title: 'test')).id;
    account = await accounts.create(
      bankId: 'mellat',
      bankName: 'بانک ملت',
      accountName: 'حساب ملت',
      accountType: AccountType.bank,
      initialBalance: Rial.fromToman(1000000),
      operationId: 'op-account',
    );
    final analytics = AnalyticsRepository(db, accounts, transactions, loans);
    executor = ToolExecutor(
      registry: await ToolRegistry.load(rootBundle),
      accounts: accounts,
      categories: categories,
      transactions: transactions,
      loans: loans,
      analytics: analytics,
      parser: ArgumentParser(today: CalendarDate(2026, 11, 6)),
    );
    confirmations = ConfirmationService(
      db: db,
      chat: chat,
      accounts: accounts,
      transactions: transactions,
      transfers: transfers,
      loans: loans,
    );
    undo = UndoService(db, operations);
  });

  tearDown(() async => db.close());

  Future<String> proposeTransaction({String operationId = 'op-tx'}) async {
    final result = await executor.execute(
      ToolCall(
        id: 'call-1',
        name: 'add_transaction',
        arguments: {
          'type': 'expense',
          'amount': 250000,
          'amount_unit': 'toman',
          'date': 'امروز',
          'category': 'خوراک و رستوران',
          'account': 'ملت',
          'description': 'ناهار',
        },
      ),
      sessionId: sessionId,
      defaultCurrency: CurrencyUnit.toman,
    );
    final action = result.pendingAction!;
    await chat.addPendingActions([action.copyWith(sessionId: sessionId)]);
    return action.id;
  }

  test('confirming a draft persists it exactly once', () async {
    final actionId = await proposeTransaction();
    final operationId = await confirmations.confirm(actionId);

    final rows = await transactions.list(const TransactionFilter());
    expect(rows, hasLength(1));
    expect(rows.single.amountRial.value, 2500000);

    final balance = await accounts.balanceOf(account.id);
    expect(balance!.balance.value, 10000000 - 2500000);

    final pending = await chat.findPendingAction(actionId);
    expect(pending!.status, PendingActionStatus.confirmed);
    expect(operationId, isNotEmpty);

    // A second confirmation must not duplicate the record.
    expect(
      () => confirmations.confirm(actionId),
      throwsA(isA<ValidationException>()),
    );
    expect(await transactions.list(const TransactionFilter()), hasLength(1));
  });

  test('edited drafts are re-validated on confirmation', () async {
    final actionId = await proposeTransaction();
    final pending = await chat.findPendingAction(actionId);
    final payload = Map<String, Object?>.from(pending!.payload)
      ..['amountRial'] = 9000000
      ..['description'] = 'شام';
    await confirmations.confirm(actionId, payload: payload);
    final rows = await transactions.list(const TransactionFilter());
    expect(rows.single.amountRial.value, 9000000);
    expect(rows.single.description, 'شام');
  });

  test('undo removes the transaction and restores the balance', () async {
    final actionId = await proposeTransaction();
    final operationId = await confirmations.confirm(actionId);

    expect(await undo.canUndo(operationId), isTrue);
    await undo.undo(operationId);

    expect(await transactions.list(const TransactionFilter()), isEmpty);
    final balance = await accounts.balanceOf(account.id);
    expect(balance!.balance.value, 10000000);
    expect(await db.select(db.ledgerEntries).get(), isEmpty);
    expect(await undo.canUndo(operationId), isFalse);
  });

  test('rejecting a draft writes nothing', () async {
    final actionId = await proposeTransaction();
    await confirmations.reject(actionId);
    final action = await chat.findPendingAction(actionId);
    expect(action!.status, PendingActionStatus.rejected);
    expect(await transactions.list(const TransactionFilter()), isEmpty);
    expect(
      () => confirmations.confirm(actionId),
      throwsA(isA<ValidationException>()),
    );
  });

  test('account undo is refused when transactions depend on it', () async {
    final operations = OperationRepository(db);
    final rolledBack = await AccountRepository(db, operations).create(
      bankId: 'blue',
      bankName: 'بلو بانک',
      accountName: 'بلو',
      accountType: AccountType.bank,
      initialBalance: Rial.fromToman(500000),
      operationId: 'op-blue',
    );
    await transactions.create(
      type: TransactionType.income,
      amount: Rial.fromToman(100000),
      accountId: rolledBack.id,
      categoryId: 'cat_salary',
      date: CalendarDate(2026, 11, 6),
      operationId: 'op-blue-income',
    );
    expect(() => undo.undo('op-blue'), throwsA(isA<ValidationException>()));
    expect(await accounts.findById(rolledBack.id), isNotNull);
  });
}
