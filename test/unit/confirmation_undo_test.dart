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
import 'package:daram/features/sms/data/sms_review_repository.dart';
import 'package:daram/features/chat/data/confirmation_service.dart';
import 'package:daram/features/chat/data/undo_service.dart';
import 'package:daram/features/dashboard/data/analytics_repository.dart';
import 'package:daram/features/loans/data/loan_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:daram/features/transactions/domain/transaction_record.dart';
import 'package:daram/features/transactions/data/transfer_repository.dart';
import 'package:daram/features/assets/data/asset_repository.dart';
import 'package:daram/features/assets/domain/asset_quantity.dart';
import 'package:daram/features/obligations/data/obligation_repository.dart';
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
      sms: SmsReviewRepository(db, transactions),
      chat: chat,
      assets: AssetRepository(db),
      obligations: ObligationRepository(db),
      transfers: transfers,
      parser: ArgumentParser(today: CalendarDate(2026, 11, 6)),
    );
    confirmations = ConfirmationService(
      db: db,
      chat: chat,
      accounts: accounts,
      transactions: transactions,
      transfers: transfers,
      loans: loans,
      assets: AssetRepository(db),
      obligations: ObligationRepository(db),
      operations: operations,
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

  Future<String> proposeTool(
    String name,
    Map<String, Object?> arguments,
  ) async {
    final result = await executor.execute(
      ToolCall(id: 'call-manage', name: name, arguments: arguments),
      sessionId: sessionId,
      defaultCurrency: CurrencyUnit.toman,
    );
    expect(result.ok, isTrue, reason: result.content);
    final action = result.pendingAction!;
    await chat.addPendingActions([action]);
    return action.id;
  }

  test('confirming a manage_transaction update rewrites the record', () async {
    final transaction = await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(200000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: CalendarDate(2026, 11, 6),
      description: 'ناهار',
      operationId: 'op-manage-update',
    );
    final actionId = await proposeTool('manage_transaction', {
      'action': 'update',
      'transaction_id': transaction.id,
      'amount': 350000,
      'amount_unit': 'toman',
      'category': 'سفر',
      'description': 'بلیت',
    });
    await confirmations.confirm(actionId);

    final updated = await transactions.findById(transaction.id);
    expect(updated!.amountRial, Rial.fromToman(350000));
    expect(updated.categoryId, 'cat_travel');
    expect(updated.description, 'بلیت');
    final balance = await accounts.balanceOf(account.id);
    expect(balance!.balance.value, 10000000 - 3500000);
  });

  test('confirming a manage_transaction delete restores the balance', () async {
    final transaction = await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(200000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: CalendarDate(2026, 11, 6),
      operationId: 'op-manage-delete',
    );
    final actionId = await proposeTool('manage_transaction', {
      'action': 'delete',
      'transaction_id': transaction.id,
    });
    await confirmations.confirm(actionId);

    expect(await transactions.findById(transaction.id), isNull);
    final balance = await accounts.balanceOf(account.id);
    expect(balance!.balance.value, 10000000);
  });

  test('confirming a manage_account archive hides the account', () async {
    final actionId = await proposeTool('manage_account', {
      'action': 'archive',
      'account_id': account.id,
    });
    await confirmations.confirm(actionId);
    final stored = await accounts.findById(account.id);
    expect(stored!.archivedAt, isNotNull);
    final listed = await accounts.list();
    expect(listed, isEmpty);
  });

  test('confirming a manage_asset create stores the holding', () async {
    final actionId = await proposeTool('manage_asset', {
      'action': 'create',
      'name': 'طلای من',
      'kind': 'gold',
      'quantity': 2.5,
      'rate': 30000000,
      'amount_unit': 'rial',
      'rate_date': '2026-11-06',
    });
    await confirmations.confirm(actionId);
    final assets = await AssetRepository(db).list();
    expect(assets, hasLength(1));
    expect(assets.single.name, 'طلای من');
    expect(
      assets.single.quantity.micros,
      AssetQuantity.tryParse('2.5')!.micros,
    );
    expect(assets.single.rateRial, Rial(30000000));
  });

  test(
    'confirming a manage_obligation payment reduces the remainder',
    () async {
      final obligationRepository = ObligationRepository(db);
      await obligationRepository.save(
        counterparty: 'رضا',
        isReceivable: true,
        amount: Rial.fromToman(1000000),
      );
      final obligation = (await obligationRepository.list()).single;
      final actionId = await proposeTool('manage_obligation', {
        'action': 'add_payment',
        'obligation_id': obligation.id,
        'payment_amount': 400000,
        'amount_unit': 'toman',
        'payment_date': '2026-11-06',
      });
      await confirmations.confirm(actionId);
      final updated = await obligationRepository.findById(obligation.id);
      expect(updated!.paid, Rial.fromToman(400000));
      expect(updated.remaining, Rial.fromToman(600000));
    },
  );

  test('confirming a manage_loan delete removes schedule and ledger', () async {
    final loans = LoanRepository(db, OperationRepository(db));
    final loan = await loans.create(
      title: 'وام تست',
      principal: Rial.fromToman(1000000),
      installmentCount: 2,
      startDate: CalendarDate(2026, 11, 1),
      dueDates: [CalendarDate(2026, 12, 1), CalendarDate(2027, 1, 1)],
      accountId: account.id,
      operationId: 'op-loan-delete',
    );
    final actionId = await proposeTool('manage_loan', {
      'action': 'delete',
      'loan_id': loan.id,
    });
    await confirmations.confirm(actionId);

    expect(await loans.findById(loan.id), isNull);
    expect(
      await (db.select(
        db.installments,
      )..where((row) => row.loanId.equals(loan.id))).get(),
      isEmpty,
    );
    final balance = await accounts.balanceOf(account.id);
    expect(balance!.balance.value, 10000000);
  });

  test(
    'confirming a manage_transfer update rewrites both ledger legs',
    () async {
      final blue = await accounts.create(
        bankId: 'blue',
        bankName: 'بلو بانک',
        accountName: 'بلو',
        accountType: AccountType.bank,
        initialBalance: Rial.zero,
        operationId: 'op-blue-transfer',
      );
      final transfer = await TransferRepository(db, OperationRepository(db))
          .create(
            sourceAccountId: account.id,
            destinationAccountId: blue.id,
            amount: Rial.fromToman(500000),
            fee: Rial.fromToman(5000),
            date: CalendarDate(2026, 11, 6),
            operationId: 'op-transfer-manage',
          );
      final actionId = await proposeTool('manage_transfer', {
        'action': 'update',
        'transfer_id': transfer.id,
        'amount': 700000,
        'amount_unit': 'toman',
        'fee_amount': 0,
      });
      expect(actionId, isNotEmpty);
      await confirmations.confirm(actionId);

      final source = await accounts.balanceOf(account.id);
      final destination = await accounts.balanceOf(blue.id);
      expect(source!.balance, Rial.fromToman(1000000 - 700000));
      expect(destination!.balance, Rial.fromToman(700000));
      final feeRows = await (db.select(
        db.transactions,
      )..where((row) => row.id.equals('${transfer.id}_fee'))).get();
      expect(feeRows, isEmpty);
    },
  );
}
