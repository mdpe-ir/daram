import 'package:daram/app/app.dart';
import 'package:daram/app/app_providers.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/loans/data/loan_repository.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

void main() {
  testWidgets('dashboard, records and settings render with real data', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.onboarding_complete': true,
      'settings.currency_unit': 'toman',
    });
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await CategoryRepository(db).ensureDefaults();
    final operations = OperationRepository(db);
    final accounts = AccountRepository(db, operations);
    final transactions = TransactionRepository(db, operations);
    final loans = LoanRepository(db, operations);

    final account = await accounts.create(
      bankId: 'mellat',
      bankName: 'بانک ملت',
      accountName: 'حساب ملت',
      accountType: AccountType.bank,
      initialBalance: Rial.fromToman(1000000),
      operationId: 'seed-account',
    );
    final today = CalendarDate.today();
    await transactions.create(
      type: TransactionType.income,
      amount: Rial.fromToman(3000000),
      accountId: account.id,
      categoryId: 'cat_salary',
      date: today,
      description: 'حقوق',
      operationId: 'seed-income',
    );
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(250000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: today,
      description: 'ناهار',
      operationId: 'seed-expense',
    );
    await loans.create(
      title: 'وام خرید',
      principal: Rial.fromToman(30000000),
      installmentCount: 3,
      startDate: today,
      accountId: account.id,
      dueDates: [
        today.addJalaliMonths(1),
        today.addJalaliMonths(2),
        today.addJalaliMonths(3),
      ],
      operationId: 'seed-loan',
    );

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
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Dashboard
    await tester.tap(find.text('آمار').last);
    await tester.pumpAndSettle();
    expect(find.text('موجودی کل'), findsOneWidget);
    expect(find.text('روند ماهانه'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Records → accounts, transactions, loans
    await tester.tap(find.text('اطلاعات').last);
    await tester.pumpAndSettle();
    expect(find.text('حساب ملت'), findsWidgets);

    await tester.tap(find.text('تراکنش‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('ناهار'), findsWidgets);

    await tester.tap(find.text('وام‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('وام خرید'), findsWidgets);
    expect(find.text('بدهی باقی‌مانده'), findsWidgets);

    // Settings
    await tester.tap(find.text('تنظیمات').last);
    await tester.pumpAndSettle();
    expect(find.text('ظاهر'), findsWidgets);

    Future<void> openSetting(String label, {double delta = 240}) async {
      final finder = find.text(label);
      await tester.scrollUntilVisible(
        finder,
        delta,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 30,
      );
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await openSetting('درباره دارام');
    expect(find.text('حریم خصوصی'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await openSetting('دسته‌بندی‌ها', delta: -260);
    expect(find.text('خوراک و رستوران'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await openSetting('دستیار هوشمند', delta: -260);
    expect(find.text('کلید متعلق به خودت (BYOK)'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Theme switch
    await openSetting('تیره', delta: -300);
    expect(
      Theme.of(tester.element(find.text('تیره').first)).brightness,
      Brightness.dark,
    );
    expect(tester.takeException(), isNull);

    // Dispose the provider scope and let drift's stream-close timers flush.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
