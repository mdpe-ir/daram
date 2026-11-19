import 'package:daram/app/app_providers.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/settings/presentation/categories_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('user can add and edit a category from visible controls', (
    tester,
  ) async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repository = CategoryRepository(db);
    await repository.ensureDefaults();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CategoriesScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('دسته جدید'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'آزمایش رابط');
    await tester.tap(find.text('افزودن'));
    await tester.pumpAndSettle();
    final created = (await repository.list(type: CategoryType.expense))
        .singleWhere((item) => item.name == 'آزمایش رابط');
    // Open the existing category editor through the explicit edit control.
    await tester.tap(find.byTooltip('ویرایش').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'نام ویرایش‌شده');
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();
    expect(
      (await repository.list()).any((item) => item.name == 'نام ویرایش‌شده'),
      isTrue,
    );
    expect(await repository.findById(created.id), isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
