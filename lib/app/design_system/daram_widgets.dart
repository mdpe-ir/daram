import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/category_icons.dart';
import '../../core/constants/iranian_banks.dart';
import '../../core/formatting/persian_formatting.dart';
import '../../core/money/currency.dart';
import '../../core/money/rial.dart';
import '../../core/time/jalali_text.dart';
import '../theme/daram_colors.dart';

/// Central formatting context so every amount and date uses the same unit and
/// digit style without reading providers inside leaf widgets.
@immutable
class DaramFormat {
  const DaramFormat({
    this.unit = CurrencyUnit.toman,
    this.persianDigits = true,
  });

  final CurrencyUnit unit;
  final bool persianDigits;

  MoneyFormatter get money =>
      MoneyFormatter(unit: unit, usePersianDigits: persianDigits);

  JalaliText get dates => JalaliText(persianDigits: persianDigits);

  NumberFormat get numbers =>
      NumberFormat.decimalPattern('en')..turnOffGrouping();

  static DaramFormat of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<DaramFormatScope>();
    return scope?.format ?? const DaramFormat();
  }

  DaramFormat copyWith({CurrencyUnit? unit, bool? persianDigits}) =>
      DaramFormat(
        unit: unit ?? this.unit,
        persianDigits: persianDigits ?? this.persianDigits,
      );
}

class DaramFormatScope extends InheritedWidget {
  const DaramFormatScope({
    super.key,
    required this.format,
    required super.child,
  });

  final DaramFormat format;

  static DaramFormat of(BuildContext context) => DaramFormat.of(context);

  @override
  bool updateShouldNotify(DaramFormatScope oldWidget) =>
      oldWidget.format.unit != format.unit ||
      oldWidget.format.persianDigits != format.persianDigits;
}

/// Formatted money with tabular figures and an optional semantic colour.
class AmountText extends StatelessWidget {
  const AmountText(
    this.amount, {
    super.key,
    this.style,
    this.color,
    this.signed = false,
    this.showSymbol = true,
    this.unitLabel,
    this.maxLines = 1,
  });

  final Rial amount;
  final TextStyle? style;
  final Color? color;
  final bool signed;
  final bool showSymbol;
  final String? unitLabel;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final format = DaramFormat.of(context);
    final formatter = format.money;
    final text = signed
        ? formatter.formatSigned(amount)
        : formatter.format(amount, symbol: unitLabel);
    return Text(
      showSymbol ? text : formatter.formatPlain(amount),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: (style ?? Theme.of(context).textTheme.titleMedium)?.copyWith(
        color: color ?? context.daram.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: style?.fontWeight ?? FontWeight.w700,
      ),
    );
  }
}

class DaramCard extends StatelessWidget {
  const DaramCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.gradient,
    this.borderColor,
    this.radius = 20,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? colors.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? colors.border),
        boxShadow: colors.isDark
            ? null
            : [
                BoxShadow(
                  color: colors.shadow,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class DaramChip extends StatelessWidget {
  const DaramChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Material(
      color: selected ? colors.accentSoft : colors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.35)
                  : colors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? colors.accent : colors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.accent : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.onAccent,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 18, color: colors.onAccent),
        if (loading || icon != null) const SizedBox(width: 8),
        Text(label),
      ],
    );
    return Opacity(
      opacity: onPressed == null && !loading ? 0.6 : 1,
      child: Container(
        decoration: BoxDecoration(
          gradient: onPressed == null && !loading ? null : colors.brandGradient,
          color: onPressed == null || loading ? colors.surfaceMuted : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: onPressed == null
              ? null
              : [
                  BoxShadow(
                    color: colors.accent.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 52),
            foregroundColor: colors.onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: colors.onAccent),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: onPressed == null ? colors.textMuted : colors.onAccent,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: onPressed == null ? colors.textMuted : colors.onAccent,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class SoftIconButton extends StatelessWidget {
  const SoftIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 40,
    this.iconSize = 19,
    this.background,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final button = Material(
      color: background ?? colors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: iconSize,
            color: color ?? colors.textSecondary,
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class BankAvatar extends StatelessWidget {
  const BankAvatar({
    super.key,
    required this.bankId,
    this.bankName,
    this.size = 44,
    this.showBackground = true,
  });

  final String bankId;

  /// Used for custom banks (`bankId == 'other'`) so the monogram reflects the
  /// user's own bank name instead of the generic catalog entry.
  final String? bankName;

  final double size;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final bank = bankById(bankId);
    final colors = context.daram;
    final customName = bankId == 'other' ? bankName?.trim() : null;
    final hasCustomName = customName != null && customName.isNotEmpty;
    final monogramText = hasCustomName
        ? _monogramFrom(customName)
        : bank.monogram;
    // Wordmark logos are unreadable in tiny chips; fall back to the monogram.
    final logo = bank.logoIsWordmark && size < 34 ? null : bank.logoAsset;
    final isRasterLogo =
        logo != null &&
        RegExp(r'\.(png|jpe?g|webp)$', caseSensitive: false).hasMatch(logo);
    final monogram = Container(
      decoration: BoxDecoration(
        color: bank.color.withValues(alpha: colors.isDark ? 0.18 : 0.10),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        monogramText,
        style: TextStyle(
          color: bank.color,
          fontWeight: FontWeight.w700,
          fontSize: size * (monogramText.length > 1 ? 0.30 : 0.38),
        ),
      ),
    );

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * (bank.logoIsWordmark ? 0.12 : 0.18)),
      decoration: showBackground
          ? BoxDecoration(
              color: colors.isDark ? Colors.white : colors.surface,
              borderRadius: BorderRadius.circular(size * 0.32),
              border: Border.all(
                color: colors.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : colors.border,
              ),
            )
          : null,
      child: logo == null
          ? monogram
          : ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.18),
              child: isRasterLogo
                  ? Image.asset(
                      logo,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => monogram,
                    )
                  : SvgPicture.asset(
                      logo,
                      fit: BoxFit.contain,
                      placeholderBuilder: (_) => monogram,
                    ),
            ),
    );
  }
}

String _monogramFrom(String name) {
  final cleaned = name
      .replaceAll('نئوبانک', '')
      .replaceAll('بانک', '')
      .replaceAll('‌', ' ')
      .trim();
  final words = cleaned
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return '؟';
  final first = words.first.characters.first;
  final second = words.length > 1 ? words[1].characters.first : '';
  return '$first$second';
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.colorHex,
    this.size = 40,
  });

  final String icon;
  final String colorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = daramColorFromHex(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(categoryIcon(icon), size: size * 0.45, color: color),
    );
  }
}

/// Parses a `#RRGGBB` colour with a safe fallback.
Color daramColorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0x94A3B8;
  return Color(0xFF000000 | value);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.border),
              ),
              child: Icon(icon, size: 28, color: colors.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Subtle press scale used on primary cards and buttons.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.985,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Shared sheet shell with a title and close affordance.
class DaramSheet extends StatelessWidget {
  const DaramSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              SoftIconButton(
                icon: LucideIcons.x,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Flexible(child: SingleChildScrollView(child: child)),
          if (actions != null) ...[
            const SizedBox(height: 18),
            Row(children: actions!),
          ],
        ],
      ),
    );
  }
}
