import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/domain/enums.dart';
import '../../core/formatting/persian_formatting.dart';
import '../../features/categories/domain/category.dart';
import '../theme/daram_colors.dart';
import 'daram_widgets.dart';

/// A form field that opens the searchable category picker.
///
/// Shows the selected category's avatar and name, or «بدون دسته‌بندی» when
/// nothing is selected. Shared by the chat draft editor and the manual
/// transaction editor so both use the same bottom sheet.
class CategoryPickerField extends StatelessWidget {
  const CategoryPickerField({
    super.key,
    required this.selected,
    required this.categories,
    required this.type,
    required this.onChanged,
    this.enabled = true,
    this.label = 'دسته‌بندی',
  });

  /// The category currently shown in the field, if any.
  final Category? selected;

  /// Categories offered in the sheet, already filtered by [type].
  final List<Category> categories;

  /// Whether the sheet lists income or expense categories.
  final TransactionType type;

  /// Called with the chosen category, or with `null` for «بدون دسته‌بندی».
  final ValueChanged<Category?> onChanged;

  /// Whether the field can be tapped.
  final bool enabled;

  /// Form label shown above the selected category.
  final String label;

  Future<void> _open(BuildContext context) async {
    final picked = await showCategoryPicker(
      context,
      categories: categories,
      selectedId: selected?.id,
      type: type,
    );
    if (picked == null) return;
    onChanged(picked.category);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? () => _open(context) : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
          ),
          child: Row(
            children: [
              CategoryAvatar(
                icon: selected?.icon ?? 'tag',
                colorHex: selected?.colorHex ?? '#94A3B8',
                size: 30,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selected?.name ?? 'بدون دسته‌بندی',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected == null ? colors.textMuted : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Result of [showCategoryPicker].
///
/// A `null` [category] means the user explicitly chose «بدون دسته‌بندی». The
/// sheet itself returns a `null` future result when it is dismissed, so
/// callers can tell "leave the current category alone" apart from
/// "clear the category".
final class CategoryPick {
  const CategoryPick(this.category);

  /// The chosen category, or `null` for «بدون دسته‌بندی».
  final Category? category;
}

/// Opens the searchable category bottom sheet and returns the user's choice.
///
/// Returns `null` when the sheet is dismissed, or a [CategoryPick] whose
/// [CategoryPick.category] is `null` when «بدون دسته‌بندی» is chosen.
Future<CategoryPick?> showCategoryPicker(
  BuildContext context, {
  required List<Category> categories,
  String? selectedId,
  required TransactionType type,
}) {
  return showModalBottomSheet<CategoryPick>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.daram.surface,
    builder: (_) => _CategoryPickerSheet(
      categories: categories,
      selectedId: selectedId,
      type: type,
    ),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
    required this.type,
  });

  final List<Category> categories;
  final String? selectedId;
  final TransactionType type;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('\u200c', ' ')
      .toLowerCase()
      .trim();

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final query = _normalize(_search.text);
    final filtered = widget.categories
        .where((category) => _normalize(category.name).contains(query))
        .toList();
    final typeLabel = widget.type == TransactionType.expense
        ? 'هزینه'
        : 'درآمد';

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: (screenHeight - keyboard) * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 10, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'انتخاب دسته‌بندی',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '$typeLabel · ${PersianDigits.toPersian('${widget.categories.length}')} دسته',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SoftIconButton(
                    icon: LucideIcons.x,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'جست‌وجوی دسته‌بندی…',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(LucideIcons.x, size: 16),
                        ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _CategoryTile(
                    name: 'بدون دسته‌بندی',
                    icon: 'tag',
                    colorHex: '#94A3B8',
                    selected: widget.selectedId == null,
                    onTap: () =>
                        Navigator.of(context).pop(const CategoryPick(null)),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.searchX,
                            size: 30,
                            color: colors.textMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'دسته‌ای با این نام پیدا نشد.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final category in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CategoryTile(
                          name: category.name,
                          icon: category.icon,
                          colorHex: category.colorHex,
                          selected: category.id == widget.selectedId,
                          onTap: () =>
                              Navigator.of(context).pop(CategoryPick(category)),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String icon;
  final String colorHex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Material(
      color: selected ? colors.accentSoft : colors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? colors.accent : colors.border),
          ),
          child: Row(
            children: [
              CategoryAvatar(icon: icon, colorHex: colorHex, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (selected)
                Icon(LucideIcons.check, size: 17, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}
