import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/iranian_banks.dart';
import '../../core/formatting/persian_formatting.dart';
import '../theme/daram_colors.dart';
import 'daram_widgets.dart';

/// A form field that opens the searchable bank/neobank picker.
class BankPickerField extends StatelessWidget {
  const BankPickerField({
    super.key,
    required this.bankId,
    required this.onChanged,
    this.label = 'بانک',
  });

  final String bankId;
  final ValueChanged<IranianBank> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bank = bankById(bankId);
    final colors = context.daram;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showBankPicker(context, selectedId: bankId);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
        ),
        child: Row(
          children: [
            BankAvatar(bankId: bank.id, size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    bank.nameFa,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    bank.subtitle,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.textMuted),
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

/// Opens the searchable catalog of banks, neobanks, credit institutions and
/// foreign banks. Returns `null` when the sheet is dismissed.
Future<IranianBank?> showBankPicker(
  BuildContext context, {
  required String selectedId,
}) {
  return showModalBottomSheet<IranianBank>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.daram.surface,
    builder: (context) => _BankPickerSheet(selectedId: selectedId),
  );
}

class _BankPickerSheet extends StatefulWidget {
  const _BankPickerSheet({required this.selectedId});

  final String selectedId;

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final groups = groupedBanks(_query);
    final count = iranianBanks.length - 1; // exclude the generic "other" entry

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: (screenHeight - keyboard) * 0.88,
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
                          'انتخاب بانک',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${PersianDigits.toPersian('$count')} بانک، نئوبانک و مؤسسه',
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
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'جست‌وجوی بانک یا نئوبانک…',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
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
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 24,
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
                            'بانک یا نئوبانکی با این نام پیدا نشد.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  for (final kind in bankPickerGroups)
                    if ((groups[kind] ?? const [])
                        .where((bank) => bank.id != 'other')
                        .isNotEmpty) ...[
                      _SectionHeader(label: kind.label),
                      for (final bank in groups[kind]!)
                        if (bank.id != 'other')
                          _BankRow(
                            bank: bank,
                            selected: bank.id == widget.selectedId,
                            onTap: () => Navigator.of(context).pop(bank),
                          ),
                    ],
                ],
              ),
            ),
            Container(height: 1, color: colors.divider),
            SafeArea(
              top: false,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(bankById('other')),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colors.surfaceMuted,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          LucideIcons.plus,
                          size: 17,
                          color: colors.accent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'بانک من در فهرست نیست',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'نام بانک را خودت وارد کن',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        LucideIcons.chevronLeft,
                        size: 16,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: colors.divider)),
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({
    required this.bank,
    required this.selected,
    required this.onTap,
  });

  final IranianBank bank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Material(
      color: selected ? colors.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              BankAvatar(bankId: bank.id, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bank.nameFa,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? colors.accent : colors.textPrimary,
                      ),
                    ),
                    Text(
                      bank.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(LucideIcons.check, size: 18, color: colors.accent)
              else
                Icon(
                  LucideIcons.chevronLeft,
                  size: 15,
                  color: colors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
