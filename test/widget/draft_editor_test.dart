import 'dart:async';

import 'package:daram/app/app_providers.dart';
import 'package:daram/app/theme/daram_theme.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/currency.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/chat/domain/drafts.dart';
import 'package:daram/features/chat/presentation/draft_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('draft editor keeps the save action visible on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 700);
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
          operationId: 'draft-editor-account',
        );
    final draft = TransactionDraft(
      type: TransactionType.expense,
      amountRial: Rial.fromToman(280000),
      accountId: account.id,
      accountName: account.accountName,
      categoryId: 'cat_other_expense',
      categoryName: 'سایر هزینه‌ها',
      date: CalendarDate.today(),
      description: 'برداشت بانکی',
    );

    late BuildContext pageContext;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: DaramTheme.dark(),
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      ),
    );
    unawaited(
      showDraftEditor(
        pageContext,
        draft: draft,
        defaultCurrency: CurrencyUnit.toman,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ذخیره تغییرات'), findsOneWidget);
    final save = tester.getRect(find.text('ذخیره تغییرات'));
    expect(save.bottom, lessThanOrEqualTo(700));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('draft editor opens above a nested shell bottom bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 700);
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
          operationId: 'nested-sheet-account',
        );
    final draft = TransactionDraft(
      type: TransactionType.expense,
      amountRial: Rial.fromToman(280000),
      accountId: account.id,
      accountName: account.accountName,
      categoryId: 'cat_other_expense',
      categoryName: 'سایر هزینه‌ها',
      date: CalendarDate.today(),
      description: 'برداشت بانکی',
    );

    late BuildContext pageContext;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: DaramTheme.dark(),
          home: Scaffold(
            extendBody: true,
            body: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) {
                  pageContext = context;
                  return const SizedBox.expand();
                },
              ),
            ),
            bottomNavigationBar: const SizedBox(
              height: 100,
              child: ColoredBox(color: Colors.black),
            ),
          ),
        ),
      ),
    );

    final result = showDraftEditor(
      pageContext,
      draft: draft,
      defaultCurrency: CurrencyUnit.toman,
      saveLabel: 'تأیید و ثبت',
    );
    await tester.pumpAndSettle();
    expect(find.text('تأیید و ثبت'), findsOneWidget);
    await tester.tap(find.text('تأیید و ثبت'));
    await tester.pumpAndSettle();

    // The save action was reachable and the editor returned a payload instead
    // of being buried under the shell's floating bottom bar.
    expect(await result, isNotNull);
    expect(find.text('تأیید و ثبت'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('category picker searches and selects a category', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 851);
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
          operationId: 'category-picker-account',
        );
    final draft = TransactionDraft(
      type: TransactionType.expense,
      amountRial: Rial.fromToman(280000),
      accountId: account.id,
      accountName: account.accountName,
      categoryId: 'cat_other_expense',
      categoryName: 'سایر هزینه‌ها',
      date: CalendarDate.today(),
      description: 'برداشت بانکی',
    );

    late BuildContext pageContext;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: DaramTheme.dark(),
          home: Builder(
            builder: (context) {
              pageContext = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      ),
    );
    final result = showDraftEditor(
      pageContext,
      draft: draft,
      defaultCurrency: CurrencyUnit.toman,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('سایر هزینه‌ها'));
    await tester.pumpAndSettle();
    expect(find.text('انتخاب دسته‌بندی'), findsOneWidget);
    expect(find.text('جست‌وجوی دسته‌بندی…'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'حمل');
    await tester.pumpAndSettle();
    expect(find.text('حمل‌ونقل'), findsOneWidget);
    await tester.tap(find.text('حمل‌ونقل'));
    await tester.pumpAndSettle();

    expect(find.text('حمل‌ونقل'), findsOneWidget);
    await tester.tap(find.text('ذخیره تغییرات'));
    await tester.pumpAndSettle();

    final payload = await result;
    expect(payload, isNotNull);
    expect(TransactionDraft.fromPayload(payload!).categoryId, 'cat_transport');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
