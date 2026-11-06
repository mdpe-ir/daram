import 'package:meta/meta.dart';

import '../../../core/domain/enums.dart';

/// An editable income/expense category.
@immutable
final class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorHex,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });

  final String id;
  final String name;
  final CategoryType type;

  /// Lucide icon key understood by the app's icon mapper.
  final String icon;

  /// `#RRGGBB` colour used in charts and chips.
  final String colorHex;

  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  Category copyWith({
    String? name,
    CategoryType? type,
    String? icon,
    String? colorHex,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      isDefault: isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
    );
  }
}
