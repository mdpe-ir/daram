import '../domain/enums.dart';

/// A curated colour palette for category creation.
///
/// The same list is shown to the assistant and used as a safe fallback, so a
/// category never has to fall back to one fixed purple swatch.
typedef CategoryColorOption = ({String hex, String nameFa});

const List<CategoryColorOption> categoryColorPalette = [
  (hex: '#F97316', nameFa: 'نارنجی'),
  (hex: '#3B82F6', nameFa: 'آبی'),
  (hex: '#EC4899', nameFa: 'صورتی'),
  (hex: '#8B5CF6', nameFa: 'بنفش'),
  (hex: '#0EA5E9', nameFa: 'آبی روشن'),
  (hex: '#F59E0B', nameFa: 'کهربایی'),
  (hex: '#EF4444', nameFa: 'قرمز'),
  (hex: '#22C55E', nameFa: 'سبز'),
  (hex: '#6366F1', nameFa: 'نیلی'),
  (hex: '#14B8A6', nameFa: 'فیروزه‌ای'),
  (hex: '#06B6D4', nameFa: 'آبی دریایی'),
  (hex: '#94A3B8', nameFa: 'خاکستری'),
  (hex: '#10B981', nameFa: 'زمردی'),
];

/// Suggested icon and colour for a category.
final class CategoryStyle {
  const CategoryStyle(this.icon, this.colorHex, {this.semantic = false});

  final String icon;
  final String colorHex;

  /// True when a topic rule matched, rather than the generic rotation.
  final bool semantic;
}

const List<({List<String> keywords, String icon, String colorHex})>
_categoryRules = [
  (
    keywords: ['قهوه', 'کافه', 'کافی', 'اسپرسو', 'coffee', 'cafe'],
    icon: 'coffee',
    colorHex: '#F97316',
  ),
  (
    keywords: [
      'رستوران',
      'غذا',
      'ناهار',
      'شام',
      'صبحانه',
      'خوراک',
      'فست‌فود',
      'پیتزا',
      'ساندویچ',
      'نان',
      'شیرینی',
      'قنادی',
    ],
    icon: 'utensils',
    colorHex: '#F97316',
  ),
  (
    keywords: ['سوپر', 'بقالی', 'میوه', 'هایپر', 'خواربار'],
    icon: 'shopping-basket',
    colorHex: '#22C55E',
  ),
  (
    keywords: ['خرید', 'فروشگاه', 'شاپ', 'mall', 'shopping'],
    icon: 'shopping-bag',
    colorHex: '#EC4899',
  ),
  (
    keywords: ['پوشاک', 'لباس', 'کفش', 'مانتو', 'shirt'],
    icon: 'shirt',
    colorHex: '#8B5CF6',
  ),
  (
    keywords: ['تعمیر', 'مکانیک', 'سرویس', 'wrench', 'repair'],
    icon: 'wrench',
    colorHex: '#F59E0B',
  ),
  (
    keywords: [
      'حمل',
      'ونقل',
      'تاکسی',
      'اسنپ',
      'تپسی',
      'اتوبوس',
      'مترو',
      'قطار',
      'بنزین',
      'سوخت',
      'ماشین',
      'پارکینگ',
      'car',
      'taxi',
    ],
    icon: 'car',
    colorHex: '#3B82F6',
  ),
  (
    keywords: ['خانه', 'مسکن', 'اجاره', 'رهن', 'house', 'rent'],
    icon: 'house',
    colorHex: '#0EA5E9',
  ),
  (
    keywords: ['قبض', 'برق', 'آب', 'گاز', 'اینترنت', 'تلفن', 'شارژ', 'bill'],
    icon: 'receipt-text',
    colorHex: '#F59E0B',
  ),
  (
    keywords: ['درمان', 'دکتر', 'پزشک', 'دارو', 'بیمارستان', 'دندان', 'health'],
    icon: 'heart-pulse',
    colorHex: '#EF4444',
  ),
  (
    keywords: ['باشگاه', 'ورزش', 'فیتنس', 'بدنسازی', 'gym', 'fitness'],
    icon: 'dumbbell',
    colorHex: '#14B8A6',
  ),
  (
    keywords: [
      'تفریح',
      'بازی',
      'سینما',
      'فیلم',
      'کنسرت',
      'شهربازی',
      'fun',
      'game',
    ],
    icon: 'gamepad-2',
    colorHex: '#22C55E',
  ),
  (
    keywords: ['آموزش', 'کلاس', 'کتاب', 'مدرسه', 'دانشگاه', 'دوره', 'course'],
    icon: 'graduation-cap',
    colorHex: '#6366F1',
  ),
  (
    keywords: ['اشتراک', 'سابسکریپشن', 'subscription'],
    icon: 'repeat-2',
    colorHex: '#14B8A6',
  ),
  (
    keywords: ['سفر', 'هتل', 'بلیت', 'پرواز', 'تور', 'travel', 'trip'],
    icon: 'plane',
    colorHex: '#06B6D4',
  ),
  (
    keywords: ['کودک', 'بچه', 'نوزاد', 'baby', 'kids'],
    icon: 'baby',
    colorHex: '#EC4899',
  ),
  (
    keywords: ['حیوان', 'سگ', 'گربه', 'پت', 'pet'],
    icon: 'paw-print',
    colorHex: '#F97316',
  ),
  (keywords: ['هدیه', 'کادو', 'gift'], icon: 'gift', colorHex: '#EC4899'),
  (
    keywords: ['آرایش', 'زیبایی', 'سالن', 'beauty'],
    icon: 'sparkles',
    colorHex: '#EC4899',
  ),
  (
    keywords: ['حقوق', 'دستمزد', 'شغل', 'درآمد', 'salary', 'work'],
    icon: 'briefcase',
    colorHex: '#10B981',
  ),
  (
    keywords: ['سرمایه', 'سود', 'بورس', 'طلا', 'invest'],
    icon: 'trending-up',
    colorHex: '#10B981',
  ),
];

/// Picks a fitting icon/colour for a new category.
///
/// Topic rules win (coffee, gym, travel, bills, …). When the name has no clear
/// topic, a colour not used by the same category type is rotated in, so new
/// generic categories do not all look identical.
CategoryStyle suggestCategoryStyle(
  String name,
  CategoryType type, {
  Iterable<String> usedColors = const [],
}) {
  final normalized = _normalize(name);
  for (final rule in _categoryRules) {
    if (rule.keywords.any(normalized.contains)) {
      return CategoryStyle(rule.icon, rule.colorHex, semantic: true);
    }
  }

  final palette = type == CategoryType.income
      ? const ['#10B981', '#14B8A6', '#22C55E', '#0EA5E9', '#6366F1']
      : categoryColorPalette.map((option) => option.hex).toList();
  final used = usedColors.map((color) => color.toUpperCase()).toSet();
  final available = palette
      .where((color) => !used.contains(color.toUpperCase()))
      .toList();
  final color = available.isNotEmpty
      ? available.first
      : palette[used.length % palette.length];
  return CategoryStyle(
    type == CategoryType.income ? 'hand-coins' : 'circle-ellipsis',
    color,
  );
}

String _normalize(String value) => value
    .toLowerCase()
    .replaceAll('ي', 'ی')
    .replaceAll('ك', 'ک')
    .replaceAll('\u200c', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
