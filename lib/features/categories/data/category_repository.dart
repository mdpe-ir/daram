import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/default_categories.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/mappers.dart';
import '../domain/category.dart';

/// Reads and writes categories, seeding the defaults on first launch.
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// Seeds the default categories when the table is empty.
  Future<void> ensureDefaults() async {
    final existing = await _db.select(_db.categories).get();
    if (existing.isNotEmpty) return;
    final now = DateTime.now().toUtc();
    await _db.batch((batch) {
      batch.insertAll(_db.categories, [
        for (var i = 0; i < defaultCategories.length; i++)
          CategoriesCompanion.insert(
            id: defaultCategories[i].id,
            name: defaultCategories[i].name,
            type: defaultCategories[i].type,
            icon: defaultCategories[i].icon,
            colorHex: defaultCategories[i].colorHex,
            isDefault: Value(true),
            sortOrder: Value(i),
            createdAt: now,
          ),
      ]);
    });
  }

  Future<List<Category>> list({CategoryType? type}) async {
    final query = _db.select(_db.categories)
      ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]);
    if (type != null) {
      query.where((table) => table.type.equalsValue(type));
    }
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Stream<List<Category>> watch({CategoryType? type}) {
    final query = _db.select(_db.categories)
      ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]);
    if (type != null) {
      query.where((table) => table.type.equalsValue(type));
    }
    return query.watch().map(
      (rows) => rows.map((row) => row.toDomain()).toList(),
    );
  }

  Future<Category?> findById(String? id) async {
    if (id == null) return null;
    final row = await (_db.select(
      _db.categories,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  /// Resolves a category by id, exact name or a fuzzy name in the given type.
  Future<Category?> resolve(String reference, CategoryType type) async {
    final byId = await findById(reference);
    if (byId != null && byId.type == type) return byId;
    final normalized = _normalize(reference);
    final candidates = await list(type: type);
    for (final category in candidates) {
      if (_normalize(category.name) == normalized) return category;
    }
    for (final category in candidates) {
      final name = _normalize(category.name);
      if (name.contains(normalized) || normalized.contains(name)) {
        return category;
      }
    }
    return null;
  }

  Future<Category> create({
    required String name,
    required CategoryType type,
    required String icon,
    required String colorHex,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('نام دسته‌بندی را وارد کنید.');
    }
    final existing = await list(type: type);
    if (existing.any(
      (category) => _normalize(category.name) == _normalize(trimmed),
    )) {
      throw ValidationException('دسته‌بندی «$trimmed» از قبل وجود دارد.');
    }
    final now = DateTime.now().toUtc();
    final category = Category(
      id: 'cat_${_uuid.v4()}',
      name: trimmed,
      type: type,
      icon: icon,
      colorHex: colorHex,
      isDefault: false,
      sortOrder: existing.length,
      createdAt: now,
    );
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: category.id,
            name: category.name,
            type: category.type,
            icon: category.icon,
            colorHex: category.colorHex,
            sortOrder: Value(category.sortOrder),
            createdAt: now,
          ),
        );
    return category;
  }

  Future<void> update(Category category) async {
    final trimmed = category.name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('نام دسته‌بندی را وارد کنید.');
    }
    final current = await findById(category.id);
    if (current == null) {
      throw const NotFoundException('دسته‌بندی پیدا نشد.');
    }
    final siblings = await list(type: current.type);
    if (siblings.any(
      (item) =>
          item.id != category.id &&
          _normalize(item.name) == _normalize(trimmed),
    )) {
      throw ValidationException('دسته‌بندی «$trimmed» از قبل وجود دارد.');
    }
    await (_db.update(
      _db.categories,
    )..where((table) => table.id.equals(category.id))).write(
      CategoriesCompanion(
        name: Value(trimmed),
        icon: Value(category.icon),
        colorHex: Value(category.colorHex),
      ),
    );
  }

  /// Deletes a category after moving its transactions to the fallback one.
  Future<void> delete(String id) async {
    final category = await findById(id);
    if (category == null) throw const NotFoundException('دسته‌بندی پیدا نشد.');

    final siblings = await list(type: category.type);
    if (siblings.length <= 1) {
      throw const ValidationException(
        'حداقل یک دسته‌بندی برای هر نوع لازم است.',
      );
    }

    final fallback = siblings.firstWhere(
      (item) =>
          item.id != id &&
          item.id ==
              (category.type == CategoryType.expense
                  ? 'cat_other_expense'
                  : 'cat_other_income'),
      orElse: () => siblings.firstWhere((item) => item.id != id),
    );

    await _db.transaction(() async {
      await (_db.update(_db.transactions)
            ..where((table) => table.categoryId.equals(id)))
          .write(TransactionsCompanion(categoryId: Value(fallback.id)));
      await (_db.delete(
        _db.categories,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  String _normalize(String value) => value
      .replaceAll('‌', '')
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(' ', '')
      .trim();
}
