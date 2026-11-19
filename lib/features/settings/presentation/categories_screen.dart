import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/constants/category_icons.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../categories/domain/category.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoryType _type = CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final categories =
        ref.watch(categoriesStreamProvider).value ?? const <Category>[];
    final filtered = categories
        .where((category) => category.type == _type)
        .toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('دسته‌بندی‌ها'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.arrowRight, size: 20),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _showEditor(context),
            icon: const Icon(LucideIcons.plus, size: 20),
            label: const Text('دسته جدید'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: SegmentedButton<CategoryType>(
                segments: const [
                  ButtonSegment(
                    value: CategoryType.expense,
                    label: Text('هزینه‌ها'),
                  ),
                  ButtonSegment(
                    value: CategoryType.income,
                    label: Text('درآمدها'),
                  ),
                ],
                selected: {_type},
                showSelectedIcon: false,
                onSelectionChanged: (value) =>
                    setState(() => _type = value.first),
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: LucideIcons.tags,
                      title: 'دسته‌بندی‌ای وجود ندارد',
                      action: FilledButton(
                        onPressed: () => _showEditor(context),
                        child: const Text('افزودن دسته'),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final category = filtered[index];
                        return DaramCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          onTap: () => _showEditor(context, category: category),
                          child: Row(
                            children: [
                              CategoryAvatar(
                                icon: category.icon,
                                colorHex: category.colorHex,
                                size: 38,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    if (category.isDefault)
                                      Text(
                                        'پیش‌فرض',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(color: colors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _showEditor(context, category: category),
                                icon: const Icon(LucideIcons.pencil, size: 17),
                                tooltip: 'ویرایش',
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _delete(category),
                                icon: Icon(
                                  LucideIcons.trash2,
                                  size: 17,
                                  color: colors.textMuted,
                                ),
                                tooltip: 'حذف',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _delete(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف دسته‌بندی'),
        content: Text(
          'دسته «${category.name}» حذف شود؟ تراکنش‌های مرتبط حذف نمی‌شوند و به یک دسته دیگر از همین نوع (ترجیحاً «سایر») منتقل می‌شوند.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.daram.expense,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(categoryRepositoryProvider).delete(category.id);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _showEditor(BuildContext context, {Category? category}) async {
    await showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CategoryEditorSheet(
        type: category?.type ?? _type,
        category: category,
      ),
    );
  }
}

class _CategoryEditorSheet extends ConsumerStatefulWidget {
  const _CategoryEditorSheet({required this.type, this.category});

  final CategoryType type;
  final Category? category;

  @override
  ConsumerState<_CategoryEditorSheet> createState() =>
      _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends ConsumerState<_CategoryEditorSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.category?.name ?? '',
  );
  late String _icon = widget.category?.icon ?? 'circle-ellipsis';
  late String _color = widget.category?.colorHex ?? '#6366F1';
  final List<String> _colors = const [
    '#F97316',
    '#3B82F6',
    '#EC4899',
    '#8B5CF6',
    '#0EA5E9',
    '#F59E0B',
    '#EF4444',
    '#22C55E',
    '#6366F1',
    '#14B8A6',
    '#06B6D4',
    '#94A3B8',
  ];
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final isEdit = widget.category != null;
    return DaramSheet(
      title: isEdit ? 'ویرایش دسته‌بندی' : 'دسته‌بندی جدید',
      subtitle: widget.type == CategoryType.expense
          ? 'دسته هزینه'
          : 'دسته درآمد',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'نام دسته‌بندی'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('آیکون', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(width: 6),
              Text(
                '${categoryIconSlugs.length} گزینه',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 168,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 44,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: categoryIconSlugs.length,
              itemBuilder: (context, index) {
                final icon = categoryIconSlugs[index];
                final selected = _icon == icon;
                return InkWell(
                  onTap: () => setState(() => _icon = icon),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected ? colors.accentSoft : colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? colors.accent.withValues(alpha: 0.5)
                            : colors.border,
                      ),
                    ),
                    child: Icon(
                      categoryIcon(icon),
                      size: 18,
                      color: selected ? colors.accent : colors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('رنگ', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in _colors)
                InkWell(
                  onTap: () => setState(() => _color = color),
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: daramColorFromHex(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == color
                            ? colors.textPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: _color == color
                        ? const Icon(
                            LucideIcons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CategoryAvatar(icon: _icon, colorHex: _color, size: 36),
              const SizedBox(width: 8),
              Text(
                _name.text.isEmpty ? 'پیش‌نمایش' : _name.text,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
      actions: [
        Expanded(
          child: PrimaryButton(
            label: isEdit ? 'ذخیره' : 'افزودن',
            loading: _busy,
            onPressed: _busy ? null : _save,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('نام دسته‌بندی را وارد کن.')),
        );
      return;
    }
    setState(() => _busy = true);
    try {
      final repository = ref.read(categoryRepositoryProvider);
      if (widget.category == null) {
        await repository.create(
          name: _name.text.trim(),
          type: widget.type,
          icon: _icon,
          colorHex: _color,
        );
      } else {
        await repository.update(
          widget.category!.copyWith(
            name: _name.text.trim(),
            icon: _icon,
            colorHex: _color,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}
