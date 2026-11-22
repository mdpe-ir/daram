import 'package:daram/core/constants/category_styles.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('topic rules give distinct, fitting icons and colours', () {
    final coffee = suggestCategoryStyle('قهوه', CategoryType.expense);
    final gym = suggestCategoryStyle('باشگاه ورزشی', CategoryType.expense);
    final travel = suggestCategoryStyle('سفر خارجی', CategoryType.expense);

    expect(coffee.semantic, isTrue);
    expect(coffee.icon, 'coffee');
    expect(coffee.colorHex, '#F97316');
    expect(gym.icon, 'dumbbell');
    expect(gym.colorHex, '#14B8A6');
    expect(travel.icon, 'plane');
    expect(travel.colorHex, '#06B6D4');
    expect({coffee.colorHex, gym.colorHex, travel.colorHex}, hasLength(3));
  });

  test('unknown names rotate through unused palette colours', () {
    final first = suggestCategoryStyle('دسته خاص', CategoryType.expense);
    final second = suggestCategoryStyle(
      'دسته ویژه',
      CategoryType.expense,
      usedColors: [first.colorHex],
    );

    expect(first.semantic, isFalse);
    expect(first.colorHex, isNot(second.colorHex));
    expect(second.colorHex, isNot(first.colorHex));
  });

  test('income fallback uses an income icon and palette', () {
    final style = suggestCategoryStyle('دسته ورودی', CategoryType.income);
    expect(style.icon, 'hand-coins');
    expect(const [
      '#10B981',
      '#14B8A6',
      '#22C55E',
      '#0EA5E9',
      '#6366F1',
    ], contains(style.colorHex));
  });

  test('the shared palette is unique and valid', () {
    final hexes = categoryColorPalette
        .map((option) => option.hex.toUpperCase())
        .toList();
    expect(hexes.toSet(), hasLength(hexes.length));
    for (final hex in hexes) {
      expect(RegExp(r'^#[0-9A-F]{6}$').hasMatch(hex), isTrue, reason: hex);
    }
  });
}
