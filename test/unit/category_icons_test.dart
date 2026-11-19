import 'package:daram/core/constants/category_icons.dart';
import 'package:daram/core/constants/default_categories.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository categories;

  setUp(() async {
    db = AppDatabase.memory();
    categories = CategoryRepository(db);
    await categories.ensureDefaults();
  });

  tearDown(() async => db.close());

  test('every seeded category icon resolves through the catalog', () {
    for (final category in defaultCategories) {
      expect(
        categoryIconCatalog.containsKey(category.icon),
        isTrue,
        reason: category.icon,
      );
    }
  });

  test('the icon catalog is broad enough for everyday categories', () {
    expect(categoryIconCatalog.length, greaterThanOrEqualTo(60));
    expect(categoryIconCatalog.keys.toSet().length, categoryIconCatalog.length);
    expect(
      categoryIconSlugs,
      containsAll(<String>['coffee', 'car', 'dumbbell']),
    );
  });

  test('custom categories keep the chosen icon and colour', () async {
    final created = await categories.create(
      name: 'قهوه',
      type: CategoryType.expense,
      icon: 'coffee',
      colorHex: '#22C55E',
    );
    expect(created.icon, 'coffee');
    expect(created.colorHex, '#22C55E');
    await categories.update(
      created.copyWith(icon: 'pizza', colorHex: '#F97316'),
    );
    final stored = await categories.findById(created.id);
    expect(stored!.icon, 'pizza');
    expect(stored.colorHex, '#F97316');
  });
}
