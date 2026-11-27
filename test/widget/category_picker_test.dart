import 'package:daram/app/design_system/category_picker.dart';
import 'package:daram/app/theme/daram_theme.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/features/categories/domain/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Category _category({required String id, required String name}) => Category(
  id: id,
  name: name,
  type: CategoryType.expense,
  icon: 'tag',
  colorHex: '#7C79FF',
  isDefault: false,
  sortOrder: 0,
  createdAt: DateTime.utc(2024),
);

final _categories = [
  _category(id: 'coffee', name: 'قهوه و کافه'),
  _category(id: 'groceries', name: 'خرید روزانه'),
];

Widget _app({required Widget child}) => MaterialApp(
  theme: DaramTheme.dark(),
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('CategoryPickerField opens the sheet and reports the choice', (
    tester,
  ) async {
    Category? picked;
    await tester.pumpWidget(
      _app(
        child: SizedBox(
          width: 320,
          child: CategoryPickerField(
            selected: null,
            categories: _categories,
            type: TransactionType.expense,
            onChanged: (category) => picked = category,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CategoryPickerField));
    await tester.pumpAndSettle();
    expect(find.text('انتخاب دسته‌بندی'), findsOneWidget);

    await tester.tap(find.text('خرید روزانه'));
    await tester.pumpAndSettle();

    expect(picked?.id, 'groceries');
    expect(find.text('انتخاب دسته‌بندی'), findsNothing);
  });

  testWidgets('the sheet search filters categories and shows an empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        child: SizedBox(
          width: 320,
          child: CategoryPickerField(
            selected: null,
            categories: _categories,
            type: TransactionType.expense,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.tap(find.byType(CategoryPickerField));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'قهوه');
    await tester.pumpAndSettle();
    expect(find.text('قهوه و کافه'), findsOneWidget);
    expect(find.text('خرید روزانه'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ناموجود');
    await tester.pumpAndSettle();
    expect(find.text('دسته‌ای با این نام پیدا نشد.'), findsOneWidget);
  });

  testWidgets('choosing بدون دسته‌بندی yields CategoryPick(null)', (
    tester,
  ) async {
    late Future<CategoryPick?> result;
    await tester.pumpWidget(
      _app(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              result = showCategoryPicker(
                context,
                categories: _categories,
                selectedId: 'coffee',
                type: TransactionType.expense,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بدون دسته‌بندی'));
    await tester.pumpAndSettle();

    final pick = await result;
    expect(pick, isNotNull);
    expect(pick!.category, isNull);
  });

  testWidgets('dismissing the sheet yields null', (tester) async {
    late Future<CategoryPick?> result;
    await tester.pumpWidget(
      _app(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              result = showCategoryPicker(
                context,
                categories: _categories,
                selectedId: 'coffee',
                type: TransactionType.expense,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  testWidgets('CategoryPickerField reports a cleared category as null', (
    tester,
  ) async {
    var called = false;
    Category? chosen = _categories.first;
    await tester.pumpWidget(
      _app(
        child: SizedBox(
          width: 320,
          child: CategoryPickerField(
            selected: _categories.first,
            categories: _categories,
            type: TransactionType.expense,
            onChanged: (category) {
              called = true;
              chosen = category;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CategoryPickerField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('بدون دسته‌بندی'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(chosen, isNull);
  });
}
