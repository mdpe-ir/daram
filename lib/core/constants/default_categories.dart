import '../../core/domain/enums.dart';

/// A default category definition.
class DefaultCategory {
  const DefaultCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.colorHex,
  });

  final String id;
  final String name;
  final CategoryType type;
  final String icon;
  final String colorHex;
}

/// Categories seeded on first launch. They are fully editable afterwards and
/// their ids are stable so that existing records keep pointing at them.
const List<DefaultCategory> defaultCategories = <DefaultCategory>[
  // Expenses
  DefaultCategory(
    id: 'cat_food',
    name: 'خوراک و رستوران',
    type: CategoryType.expense,
    icon: 'utensils',
    colorHex: '#F97316',
  ),
  DefaultCategory(
    id: 'cat_transport',
    name: 'حمل‌ونقل',
    type: CategoryType.expense,
    icon: 'bus',
    colorHex: '#3B82F6',
  ),
  DefaultCategory(
    id: 'cat_shopping',
    name: 'خرید',
    type: CategoryType.expense,
    icon: 'shopping-bag',
    colorHex: '#EC4899',
  ),
  DefaultCategory(
    id: 'cat_clothing',
    name: 'پوشاک',
    type: CategoryType.expense,
    icon: 'shirt',
    colorHex: '#8B5CF6',
  ),
  DefaultCategory(
    id: 'cat_housing',
    name: 'مسکن',
    type: CategoryType.expense,
    icon: 'house',
    colorHex: '#0EA5E9',
  ),
  DefaultCategory(
    id: 'cat_bills',
    name: 'قبوض',
    type: CategoryType.expense,
    icon: 'receipt-text',
    colorHex: '#F59E0B',
  ),
  DefaultCategory(
    id: 'cat_health',
    name: 'درمان',
    type: CategoryType.expense,
    icon: 'heart-pulse',
    colorHex: '#EF4444',
  ),
  DefaultCategory(
    id: 'cat_fun',
    name: 'تفریح',
    type: CategoryType.expense,
    icon: 'gamepad-2',
    colorHex: '#22C55E',
  ),
  DefaultCategory(
    id: 'cat_education',
    name: 'آموزش',
    type: CategoryType.expense,
    icon: 'graduation-cap',
    colorHex: '#6366F1',
  ),
  DefaultCategory(
    id: 'cat_subscriptions',
    name: 'اشتراک‌ها',
    type: CategoryType.expense,
    icon: 'repeat-2',
    colorHex: '#14B8A6',
  ),
  DefaultCategory(
    id: 'cat_travel',
    name: 'سفر',
    type: CategoryType.expense,
    icon: 'plane',
    colorHex: '#06B6D4',
  ),
  DefaultCategory(
    id: 'cat_other_expense',
    name: 'سایر هزینه‌ها',
    type: CategoryType.expense,
    icon: 'circle-ellipsis',
    colorHex: '#94A3B8',
  ),
  // Income
  DefaultCategory(
    id: 'cat_salary',
    name: 'حقوق',
    type: CategoryType.income,
    icon: 'briefcase',
    colorHex: '#10B981',
  ),
  DefaultCategory(
    id: 'cat_freelance',
    name: 'فریلنسری',
    type: CategoryType.income,
    icon: 'laptop',
    colorHex: '#0EA5E9',
  ),
  DefaultCategory(
    id: 'cat_investment',
    name: 'سرمایه‌گذاری',
    type: CategoryType.income,
    icon: 'trending-up',
    colorHex: '#8B5CF6',
  ),
  DefaultCategory(
    id: 'cat_gift',
    name: 'هدیه',
    type: CategoryType.income,
    icon: 'gift',
    colorHex: '#F43F5E',
  ),
  DefaultCategory(
    id: 'cat_sale',
    name: 'فروش',
    type: CategoryType.income,
    icon: 'tag',
    colorHex: '#F59E0B',
  ),
  DefaultCategory(
    id: 'cat_other_income',
    name: 'سایر درآمدها',
    type: CategoryType.income,
    icon: 'circle-plus',
    colorHex: '#94A3B8',
  ),
];
