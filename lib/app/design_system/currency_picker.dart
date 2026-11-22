import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/world_currencies.dart';
import '../../core/formatting/persian_formatting.dart';
import '../theme/daram_colors.dart';
import 'daram_widgets.dart';

/// A form field that opens the searchable currency picker.
///
/// Used instead of a free-text ISO code field so people pick «دلار آمریکا» and
/// the code is filled in automatically.
class CurrencyPickerField extends StatelessWidget {
  const CurrencyPickerField({
    super.key,
    required this.code,
    required this.onChanged,
    this.label = 'ارز',
    this.enabled = true,
  });

  final String code;
  final ValueChanged<WorldCurrency> onChanged;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final currency = code.trim().isEmpty ? null : currencyOrCode(code);
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? () async {
                final picked = await showCurrencyPicker(
                  context,
                  selectedCode: code,
                );
                if (picked != null) onChanged(picked);
              }
            : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
          ),
          child: currency == null
              ? Text(
                  'انتخاب ارز',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.textMuted),
                )
              : Row(
                  children: [
                    CurrencyBadge(currency: currency),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            currency.nameFa,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _subtitle(currency),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

String _subtitle(WorldCurrency currency) =>
    currency.countryFa.isEmpty ? 'ارز خارج از فهرست' : currency.countryFa;

/// Circular flag standing in for the currency in the picker and form field.
///
/// Codes typed outside the catalog have no country, so they keep a neutral
/// currency icon instead of a flag.
class CurrencyBadge extends StatelessWidget {
  const CurrencyBadge({super.key, required this.currency, this.size = 34});

  final WorldCurrency currency;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final asset = currency.flagAsset;
    Widget fallback() => Container(
      color: colors.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(
        LucideIcons.banknote,
        size: size * 0.5,
        color: colors.textMuted,
      ),
    );
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.border),
      ),
      child: asset == null
          ? fallback()
          : SvgPicture.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholderBuilder: (_) => fallback(),
              errorBuilder: (_, _, _) => fallback(),
            ),
    );
  }
}

/// Opens the searchable list of currencies. Returns `null` when dismissed.
Future<WorldCurrency?> showCurrencyPicker(
  BuildContext context, {
  required String selectedCode,
}) {
  return showModalBottomSheet<WorldCurrency>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.daram.surface,
    builder: (context) => _CurrencyPickerSheet(selectedCode: selectedCode),
  );
}

class _CurrencyPickerSheet extends StatefulWidget {
  const _CurrencyPickerSheet({required this.selectedCode});

  final String selectedCode;

  @override
  State<_CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<_CurrencyPickerSheet> {
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
    final matches = searchCurrencies(_query);
    final popular = matches.where((currency) => currency.popular).toList();
    final others = matches.where((currency) => !currency.popular).toList();
    final selected = widget.selectedCode.trim().toUpperCase();

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
                          'انتخاب ارز',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${PersianDigits.toPersian('${worldCurrencies.length}')} ارز خارجی',
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
                  hintText: 'جست‌وجوی ارز؛ دلار، یورو یا EUR…',
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
                  if (matches.isEmpty)
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
                            'ارزی با این نام پیدا نشد.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  if (popular.isNotEmpty) ...[
                    const _SectionHeader(label: 'رایج‌ترین ارزها'),
                    for (final currency in popular)
                      _CurrencyRow(
                        currency: currency,
                        selected: currency.code == selected,
                        onTap: () => Navigator.of(context).pop(currency),
                      ),
                  ],
                  if (others.isNotEmpty) ...[
                    const _SectionHeader(label: 'سایر ارزها'),
                    for (final currency in others)
                      _CurrencyRow(
                        currency: currency,
                        selected: currency.code == selected,
                        onTap: () => Navigator.of(context).pop(currency),
                      ),
                  ],
                ],
              ),
            ),
            Container(height: 1, color: colors.divider),
            SafeArea(
              top: false,
              child: InkWell(
                onTap: () async {
                  final currency = await _promptCustomCode(context);
                  if (currency != null && context.mounted) {
                    Navigator.of(context).pop(currency);
                  }
                },
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
                          LucideIcons.keyboard,
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
                              'ارز من در فهرست نیست',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'کد سه‌حرفی را خودت وارد کن',
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

Future<WorldCurrency?> _promptCustomCode(BuildContext context) =>
    showDialog<WorldCurrency>(
      context: context,
      builder: (context) => const _CustomCurrencyDialog(),
    );

class _CustomCurrencyDialog extends StatefulWidget {
  const _CustomCurrencyDialog();

  @override
  State<_CustomCurrencyDialog> createState() => _CustomCurrencyDialogState();
}

class _CustomCurrencyDialogState extends State<_CustomCurrencyDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final code = _controller.text.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(code)) return;
    Navigator.of(context).pop(currencyOrCode(code));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final canSubmit = RegExp(r'^[A-Z]{3}$')
        .hasMatch(_controller.text.trim().toUpperCase());
    return AlertDialog(
      backgroundColor: colors.surface,
      title: const Text('ارز دیگر'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('کد سه‌حرفی بین‌المللی ارز را وارد کن.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            textCapitalization: TextCapitalization.characters,
            maxLength: 3,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'کد ارز',
              hintText: 'GBP',
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: canSubmit ? _submit : null,
          child: const Text('تأیید'),
        ),
      ],
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

class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({
    required this.currency,
    required this.selected,
    required this.onTap,
  });

  final WorldCurrency currency;
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
              CurrencyBadge(currency: currency, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency.nameFa,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? colors.accent : colors.textPrimary,
                      ),
                    ),
                    Text(
                      _subtitle(currency),
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
