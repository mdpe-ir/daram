import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/branding/daram_logo.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/money/currency.dart';
import '../../settings/domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final settings =
        ref.watch(settingsControllerProvider).value ??
        const AppSettings.defaults();
    final package = ref.watch(packageInfoProvider).value;
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تنظیمات',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ظاهر، داده‌ها و دستیار هوشمند',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                const DaramMark(size: 34),
              ],
            ),
            const SizedBox(height: 16),
            DaramCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const DaramLogo(markSize: 46, showEnglish: true),
                  const Spacer(),
                  StatusPill(
                    label: settings.isAIConfigured
                        ? 'دستیار متصل'
                        : 'تنظیم نشده',
                    color: settings.isAIConfigured
                        ? colors.income
                        : colors.warning,
                    icon: settings.isAIConfigured
                        ? LucideIcons.check
                        : LucideIcons.keyRound,
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(title: 'ظاهر'),
            DaramCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'تم برنامه',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ThemeOption(
                        label: 'سیستم',
                        icon: LucideIcons.smartphone,
                        selected: settings.themeMode == ThemeMode.system,
                        onTap: () => controller.setThemeMode(ThemeMode.system),
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        label: 'روشن',
                        icon: LucideIcons.sun,
                        selected: settings.themeMode == ThemeMode.light,
                        onTap: () => controller.setThemeMode(ThemeMode.light),
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        label: 'تیره',
                        icon: LucideIcons.moon,
                        selected: settings.themeMode == ThemeMode.dark,
                        onTap: () => controller.setThemeMode(ThemeMode.dark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: colors.divider),
                  const SizedBox(height: 14),
                  Text(
                    'واحد نمایش',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'مقادیر همیشه به ریال ذخیره می‌شوند؛ این تنظیم فقط نمایش را تغییر می‌دهد.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<CurrencyUnit>(
                    segments: const [
                      ButtonSegment(
                        value: CurrencyUnit.toman,
                        label: Text('تومان'),
                      ),
                      ButtonSegment(
                        value: CurrencyUnit.rial,
                        label: Text('ریال'),
                      ),
                    ],
                    selected: {settings.currencyUnit},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) =>
                        controller.setCurrency(value.first),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    type: MaterialType.transparency,
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: settings.persianDigits,
                      onChanged: controller.setPersianDigits,
                      title: Text(
                        'نمایش ارقام فارسی',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      subtitle: Text(
                        'اعداد در کل برنامه با ارقام ۰ تا ۹ نمایش داده شوند.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel(title: 'دستیار و داده‌ها'),
            DaramCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: LucideIcons.sparkles,
                    color: colors.accent,
                    title: 'دستیار هوشمند',
                    subtitle: settings.isAIConfigured
                        ? '${settings.aiConfig.provider.label} · ${isolateLtr(settings.aiConfig.model)}'
                        : 'کلید API را وارد کن تا گفتگو فعال شود',
                    onTap: () => context.push('/settings/ai'),
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: LucideIcons.tags,
                    color: colors.transfer,
                    title: 'دسته‌بندی‌ها',
                    subtitle: 'دسته‌های هزینه و درآمد را مدیریت کن',
                    onTap: () => context.push('/settings/categories'),
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: LucideIcons.database,
                    color: colors.warning,
                    title: 'مدیریت داده‌ها',
                    subtitle: 'خروجی CSV، گزارش PDF و پشتیبان محلی',
                    onTap: () => context.push('/settings/data'),
                    showDivider: true,
                  ),
                  _SettingsTile(
                    icon: LucideIcons.info,
                    color: colors.income,
                    title: 'درباره دارام',
                    subtitle:
                        'نسخه ${PersianDigits.toPersian(appVersionLabel(package))} · حریم خصوصی و مجوزها',
                    onTap: () => context.push('/settings/about'),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const DaramMark(size: 26, withBackground: false),
                  const SizedBox(height: 6),
                  Text(
                    AppInfo.tagline,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: context.daram.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? colors.accentSoft : colors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.5)
                  : colors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? colors.accent : colors.textMuted,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? colors.accent : colors.textMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.showDivider,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(right: 64),
            child: Container(height: 1, color: colors.divider),
          ),
      ],
    );
  }
}
