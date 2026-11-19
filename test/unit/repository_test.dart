import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/errors/app_exception.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/accounts/domain/account.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/dashboard/data/analytics_repository.dart';
import 'package:daram/features/loans/data/loan_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:daram/features/transactions/data/transfer_repository.dart';
import 'package:daram/features/transactions/domain/transaction_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountRepository accounts;
  late CategoryRepository categories;
  late TransactionRepository transactions;
  late TransferRepository transfers;
  late LoanRepository loans;
  late AnalyticsRepository analytics;

  setUp(() async {
    db = AppDatabase.memory();
    final operations = OperationRepository(db);
    categories = CategoryRepository(db);
    await categories.ensureDefaults();
    accounts = AccountRepository(db, operations);
    transactions = TransactionRepository(db, operations);
    transfers = TransferRepository(db, operations);
    loans = LoanRepository(db, operations);
    analytics = AnalyticsRepository(db, accounts, transactions, loans);
  });

  tearDown(() async => db.close());

  Future<Account> seedAccount() => accounts.create(
    bankId: 'mellat',
    bankName: 'بانک ملت',
    accountName: 'حساب ملت',
    accountType: AccountType.bank,
    initialBalance: Rial.fromToman(1000000),
    operationId: 'op-account-1',
  );

  final date = CalendarDate(2024, 8, 13);

  test(
    'deleting fallback category preserves transactions and last category',
    () async {
      final account = await seedAccount();
      await transactions.create(
        type: TransactionType.expense,
        amount: Rial.fromToman(100),
        accountId: account.id,
        categoryId: 'cat_other_expense',
        date: date,
        operationId: 'op-fallback',
      );
      await categories.delete('cat_other_expense');
      final rows = await db.select(db.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.categoryId, isNot('cat_other_expense'));
      expect(await categories.findById(rows.single.categoryId), isNotNull);
      final remaining = await categories.list(type: CategoryType.expense);
      for (final item in remaining.skip(1)) {
        await categories.delete(item.id);
      }
      await expectLater(
        categories.delete(remaining.first.id),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('creates an account and derives its balance', () async {
    final account = await seedAccount();
    final balances = await accounts.listWithBalances();
    expect(balances, hasLength(1));
    expect(balances.first.account.id, account.id);
    expect(balances.first.balance.value, 10000000);
  });

  test('custom and neobank identities are preserved', () async {
    final custom = await accounts.create(
      bankId: 'other',
      bankName: 'بانک نمونه من',
      accountName: 'حساب ویژه',
      accountType: AccountType.bank,
      initialBalance: Rial.zero,
      operationId: 'op-custom-bank',
    );
    expect(custom.bankId, 'other');
    expect(custom.bankName, 'بانک نمونه من');

    await accounts.update(id: custom.id, bankId: 'blue', bankName: 'بلو بانک');
    final updated = await accounts.findById(custom.id);
    expect(updated!.bankId, 'blue');
    expect(updated.bankName, 'بلوبانک');
    expect(updated.accountName, 'حساب ویژه');
  });

  test('income and expense update the ledger and summary', () async {
    final account = await seedAccount();
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(250000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: date,
      operationId: 'op-expense-1',
    );
    await transactions.create(
      type: TransactionType.income,
      amount: Rial.fromToman(3000000),
      accountId: account.id,
      categoryId: 'cat_salary',
      date: date,
      operationId: 'op-income-1',
    );

    final balance = await accounts.balanceOf(account.id);
    expect(balance!.balance.value, 10000000 - 2500000 + 30000000);

    final summary = await analytics.summary(DateRange(date, date));
    expect(summary.income.value, 30000000);
    expect(summary.expense.value, 2500000);
    expect(summary.net.value, 27500000);
    expect(summary.transactionCount, 2);
  });

  test('writes are idempotent per operation id', () async {
    final account = await seedAccount();
    for (var i = 0; i < 2; i++) {
      await transactions.create(
        type: TransactionType.expense,
        amount: Rial.fromToman(10000),
        accountId: account.id,
        date: date,
        operationId: 'op-duplicate',
      );
    }
    final all = await transactions.list(const TransactionFilter());
    expect(all, hasLength(1));
    final balance = await accounts.balanceOf(account.id);
    expect(balance!.balance.value, 10000000 - 100000);
  });

  test('transfers move money without touching income or expense', () async {
    final source = await seedAccount();
    final destination = await accounts.create(
      bankId: 'blue',
      bankName: 'بلو بانک',
      accountName: 'بلو',
      accountType: AccountType.bank,
      initialBalance: Rial.zero,
      operationId: 'op-account-2',
    );

    await transfers.create(
      sourceAccountId: source.id,
      destinationAccountId: destination.id,
      amount: Rial.fromToman(500000),
      fee: Rial.fromToman(5000),
      date: date,
      operationId: 'op-transfer-1',
    );

    final summary = await analytics.summary(DateRange(date, date));
    expect(summary.income.value, 0);
    // Only the fee is an expense, never the transfer itself.
    expect(summary.expense.value, 50000);

    final sourceBalance = await accounts.balanceOf(source.id);
    final destinationBalance = await accounts.balanceOf(destination.id);
    expect(sourceBalance!.balance.value, 10000000 - 5000000 - 50000);
    expect(destinationBalance!.balance.value, 5000000);
  });

  test(
    'loans are disbursed without being income and track installments',
    () async {
      final account = await seedAccount();
      final loan = await loans.create(
        title: 'وام خرید',
        principal: Rial.fromToman(30000000),
        installmentCount: 3,
        startDate: date,
        dueDates: [
          date.addJalaliMonths(1),
          date.addJalaliMonths(2),
          date.addJalaliMonths(3),
        ],
        accountId: account.id,
        operationId: 'op-loan-1',
      );

      final afterDisbursement = await accounts.balanceOf(account.id);
      expect(afterDisbursement!.balance.value, 10000000 + 300000000);

      final summary = await analytics.summary(DateRange(date, date));
      expect(summary.income.value, 0);

      expect(loan.installmentCount, 3);
      expect(loan.installmentAmountRial.value, 100000000);
      expect(loan.outstandingRial.value, 300000000);

      final installments = await loans.installmentsOf(loan.id);
      expect(installments, hasLength(3));

      await loans.markInstallmentPaid(
        loanId: loan.id,
        installmentId: installments.first.id,
        paymentDate: date,
        operationId: 'op-pay-1',
      );

      final updated = await loans.findById(loan.id);
      expect(updated!.paidInstallments, 1);
      expect(updated.outstandingRial.value, 200000000);
      expect(updated.totalPaidRial.value, 100000000);

      final afterPayment = await accounts.balanceOf(account.id);
      expect(afterPayment!.balance.value, 10000000 + 300000000 - 100000000);
    },
  );

  test('partial installment payments are rejected', () async {
    final account = await seedAccount();
    final loan = await loans.create(
      title: 'وام آزمایشی',
      principal: Rial.fromToman(3000000),
      installmentCount: 3,
      startDate: date,
      accountId: account.id,
      dueDates: [
        date.addJalaliMonths(1),
        date.addJalaliMonths(2),
        date.addJalaliMonths(3),
      ],
      operationId: 'op-loan-partial',
    );
    final installments = await loans.installmentsOf(loan.id);
    expect(
      () => loans.markInstallmentPaid(
        loanId: loan.id,
        installmentId: installments.first.id,
        paymentDate: date,
        paidAmount: Rial(1000),
        operationId: 'op-partial-pay',
      ),
      throwsA(isA<ValidationException>()),
    );
    final unchanged = await loans.findById(loan.id);
    expect(unchanged!.paidInstallments, 0);
  });

  test('equal-installment remainder goes to the last installment', () async {
    final loan = await loans.create(
      title: 'وام نامساوی',
      principal: Rial(100),
      installmentCount: 3,
      startDate: date,
      dueDates: [
        date.addJalaliMonths(1),
        date.addJalaliMonths(2),
        date.addJalaliMonths(3),
      ],
      operationId: 'op-loan-2',
    );
    final installments = await loans.installmentsOf(loan.id);
    expect(installments[0].amountRial.value, 33);
    expect(installments[1].amountRial.value, 33);
    expect(installments[2].amountRial.value, 34);
    expect(Rial.sum(installments.map((item) => item.amountRial)).value, 100);
  });

  test('category breakdown is calculated from the database', () async {
    final account = await seedAccount();
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(200000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: date,
      operationId: 'op-breakdown-1',
    );
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(100000),
      accountId: account.id,
      categoryId: 'cat_transport',
      date: date,
      operationId: 'op-breakdown-2',
    );
    final breakdown = await analytics.categoryBreakdown(
      DateRange(date, date),
      type: TransactionType.expense,
    );
    expect(breakdown, hasLength(2));
    expect(breakdown.first.name, 'خوراک و رستوران');
    expect(breakdown.first.amount.value, 2000000);
    expect(breakdown.first.share, closeTo(2 / 3, 0.0001));
  });

  test('rejects a transfer to the same account', () async {
    final account = await seedAccount();
    expect(
      () => transfers.create(
        sourceAccountId: account.id,
        destinationAccountId: account.id,
        amount: Rial.fromToman(1000),
        date: date,
        operationId: 'op-invalid-transfer',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
