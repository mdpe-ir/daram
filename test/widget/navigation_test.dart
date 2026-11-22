import 'package:daram/app/app.dart';
import 'package:daram/app/app_providers.dart';
import 'package:daram/app/design_system/crypto_picker.dart';
import 'package:daram/app/design_system/currency_picker.dart';
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

    await tester.tap(find.text('بدهی و طلب'));
    await tester.pumpAndSettle();
    await tester.binding.setSurfaceSize(const Size(340, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();
    expect(find.text('بدهی یا طلبی ثبت نشده است'), findsOneWidget);
    expect(find.text('افزودن بدهی یا طلب'), findsOneWidget);
    Future<void> enter(String label, String value) async {
      final field = find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == label,
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, value);
    }

    String? fieldText(String label) => tester
        .widget<TextField>(
          find.byWidgetPredicate(
            (widget) =>
                widget is TextField && widget.decoration?.labelText == label,
          ),
        )
        .controller
        ?.text;

    await tester.tap(find.text('بدهی یا طلب'));
    await tester.pumpAndSettle();
    expect(find.text('ثبت بدهی یا طلب'), findsOneWidget);
    await tester.tap(find.text('طلب'));
    await enter('طرف حساب', 'رضا');
    await enter('مبلغ', '25000');
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(find.text('رضا'), findsOneWidget);

    await tester.ensureVisible(find.text('پرداخت‌ها'));
    await tester.tap(find.text('پرداخت‌ها'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ثبت دریافت'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('واردکردن کل مانده'));
    await tester.tap(find.widgetWithText(TextButton, 'ثبت دریافت').last);
    await tester.pumpAndSettle();
    expect(find.text('تسویه شده'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسویه‌شده'));
    await tester.pumpAndSettle();
    expect(find.text('رضا'), findsOneWidget);

    await tester.tap(find.text('دارایی‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('دارایی‌ای ثبت نشده است'), findsOneWidget);
    expect(find.text('افزودن دارایی'), findsOneWidget);
    await tester.tap(find.text('دارایی'));
    await tester.pumpAndSettle();
    expect(find.text('ثبت دارایی'), findsOneWidget);
    expect(find.text('دریافت نرخ طلای ۱۸ عیار'), findsOneWidget);
    await enter('نام دارایی', 'طلای من');
    await enter('وزن به گرم', '۲٫۲۵');
    await enter('نرخ هر گرم (اختیاری)', '1000000');
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(find.text('طلای من'), findsOneWidget);
    expect(find.text('۲,۲۵۰,۰۰۰ تومان'), findsWidgets);

    // Currency assets pick from the catalog instead of typing an ISO code.
    await tester.tap(find.text('دارایی'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ارز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انتخاب ارز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دلار آمریکا'));
    await tester.pumpAndSettle();
    expect(fieldText('نام دارایی'), 'دلار آمریکا');
    await enter('تعداد واحد ارز', '10');
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(find.text('دلار آمریکا'), findsOneWidget);

    // Editing a row keeps the generated name in sync with the new currency.
    await tester.tap(find.byTooltip('گزینه‌های دلار آمریکا'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ویرایش و نرخ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CurrencyPickerField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('یورو'));
    await tester.pumpAndSettle();
    expect(fieldText('نام دارایی'), 'یورو');
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(find.text('یورو'), findsOneWidget);

    // Crypto holdings pick a coin and prefill the name from it.
    await tester.tap(find.text('دارایی'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('رمز ارز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('انتخاب رمزارز'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بیت‌کوین'));
    await tester.pumpAndSettle();
    expect(fieldText('نام دارایی'), 'بیت‌کوین');
    expect(find.text('دریافت نرخ بیت‌کوین از نوسان'), findsOneWidget);
    await enter('مقدار رمزارز', '0.5');
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(find.text('بیت‌کوین'), findsOneWidget);

    // Editing a crypto row swaps the suggested name with the new coin.
    await tester.tap(find.byTooltip('گزینه‌های بیت‌کوین'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ویرایش و نرخ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CryptoPickerField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('اتریوم'));
    await tester.pumpAndSettle();
    expect(fieldText('نام دارایی'), 'اتریوم');
    expect(
      find.text('نرخ زندهٔ این رمزارز در دسترس نیست؛ نرخ را دستی وارد کن.'),
      findsOneWidget,
    );
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(find.text('اتریوم'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
    await tester.pumpAndSettle();

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
