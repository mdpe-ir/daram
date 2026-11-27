import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/crypto_assets.dart';
import '../../core/formatting/persian_formatting.dart';
import '../theme/daram_colors.dart';
import 'daram_widgets.dart';

/// A form field that opens the searchable cryptocurrency picker.
///
/// Used instead of a free-text ticker field so people pick «بیت‌کوین» and the
/// symbol is filled in automatically.
class CryptoPickerField extends StatelessWidget {
  const CryptoPickerField({
    super.key,
    required this.symbol,
    required this.onChanged,
    this.label = 'رمزارز',
    this.enabled = true,
  });

  final String symbol;
  final ValueChanged<CryptoAsset> onChanged;
  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final coin = symbol.trim().isEmpty ? null : cryptoOrSymbol(symbol);
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? () async {
                final picked = await showCryptoPicker(
                  context,
                  selectedSymbol: symbol,
                );
                if (picked != null) onChanged(picked);
              }
            : null,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(LucideIcons.chevronDown, size: 18),
          ),
          child: coin == null
              ? Text(
                  'انتخاب رمزارز',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.textMuted),
                )
              : Row(
                  children: [
                    CryptoBadge(coin: coin),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            coin.nameFa,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            coin.nameEn.isEmpty
                                ? 'خارج از فهرست'
                                : '${coin.nameEn} · ${coin.symbol}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

/// Circular coin icon used in the picker rows and the form field.
class CryptoBadge extends StatelessWidget {
  const CryptoBadge({super.key, required this.coin, this.size = 34});

  final CryptoAsset coin;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final asset = coin.iconAsset;
    Widget fallback() => Container(
      color: colors.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(LucideIcons.coins, size: size * 0.5, color: colors.textMuted),
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

/// Opens the searchable list of cryptocurrencies. Returns `null` when the
/// sheet is dismissed.
Future<CryptoAsset?> showCryptoPicker(
  BuildContext context, {
  required String selectedSymbol,
}) {
  return showModalBottomSheet<CryptoAsset>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.daram.surface,
    builder: (context) => _CryptoPickerSheet(selectedSymbol: selectedSymbol),
  );
}

class _CryptoPickerSheet extends StatefulWidget {
  const _CryptoPickerSheet({required this.selectedSymbol});

  final String selectedSymbol;

  @override
  State<_CryptoPickerSheet> createState() => _CryptoPickerSheetState();
}

class _CryptoPickerSheetState extends State<_CryptoPickerSheet> {
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
    final matches = searchCryptoAssets(_query);
    final popular = matches.where((coin) => coin.popular).toList();
    final others = matches.where((coin) => !coin.popular).toList();
    final selected = widget.selectedSymbol.trim().toUpperCase();

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
                          'انتخاب رمزارز',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${PersianDigits.toPersian('${cryptoAssets.length}')} رمزارز',
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
                  hintText: 'جست‌وجوی رمزارز؛ بیت‌کوین، ETH…',
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
                            'رمزارزی با این نام پیدا نشد.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  if (popular.isNotEmpty) ...[
                    const _SectionHeader(label: 'رایج‌ترین رمزارزها'),
                    for (final coin in popular)
                      _CryptoRow(
                        coin: coin,
                        selected: coin.symbol == selected,
                        onTap: () => Navigator.of(context).pop(coin),
                      ),
                  ],
                  if (others.isNotEmpty) ...[
                    const _SectionHeader(label: 'سایر رمزارزها'),
                    for (final coin in others)
                      _CryptoRow(
                        coin: coin,
                        selected: coin.symbol == selected,
                        onTap: () => Navigator.of(context).pop(coin),
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
                  final coin = await _promptCustomSymbol(context);
                  if (coin != null && context.mounted) {
                    Navigator.of(context).pop(coin);
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
                              'رمزارزم در فهرست نیست',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'نماد آن را خودت وارد کن',
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

Future<CryptoAsset?> _promptCustomSymbol(BuildContext context) =>
    showDialog<CryptoAsset>(
      context: context,
      builder: (context) => const _CustomSymbolDialog(),
    );

class _CustomSymbolDialog extends StatefulWidget {
  const _CustomSymbolDialog();

  @override
  State<_CustomSymbolDialog> createState() => _CustomSymbolDialogState();
}

class _CustomSymbolDialogState extends State<_CustomSymbolDialog> {
  final _controller = TextEditingController();
  static final _valid = RegExp(r'^[A-Z]{3,10}$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final symbol = _controller.text.trim().toUpperCase();
    if (!_valid.hasMatch(symbol)) return;
    Navigator.of(context).pop(cryptoOrSymbol(symbol));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final canSubmit = _valid.hasMatch(_controller.text.trim().toUpperCase());
    return AlertDialog(
      backgroundColor: colors.surface,
      title: const Text('رمزارز دیگر'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('نماد رمزارز را وارد کن؛ مثلاً SHIB یا TON.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            textCapitalization: TextCapitalization.characters,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'نماد',
              hintText: 'SHIB',
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

class _CryptoRow extends StatelessWidget {
  const _CryptoRow({
    required this.coin,
    required this.selected,
    required this.onTap,
  });

  final CryptoAsset coin;
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
              CryptoBadge(coin: coin, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.nameFa,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? colors.accent : colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${coin.nameEn} · ${coin.symbol}',
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
