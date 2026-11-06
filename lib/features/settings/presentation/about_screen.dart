import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';

import '../../../app/branding/daram_logo.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/constants/app_version.dart';
import '../../../core/formatting/persian_formatting.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final info = ref.watch(packageInfoProvider).value;
    final version = appVersionName(info);
    final build = appVersionCode(info);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('درباره دارام'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.arrowRight, size: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        children: [
          Center(
            child: Column(
              children: [
                const DaramMark(size: 76),
                const SizedBox(height: 14),
                Text(
                  'دارام',
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'DARAM · ${appVersionLabel(info)}',
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted, letterSpacing: 1.4),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    'نسخه ${PersianDigits.toPersian(version)} · '
                    'کد ساخت ${PersianDigits.toPersian(build)}',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppInfo.tagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          DaramCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              'دارام یک دستیار مالی شخصی است که مدیریت پول را به گفتگو تبدیل می‌کند. کافی است بنویسید چه هزینه یا درآمدی داشته‌اید؛ دارام اطلاعات را استخراج می‌کند، پیش‌نویس می‌سازد و پیش از ثبت از شما تأیید می‌گیرد. همه محاسبات و داده‌ها محلی هستند.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(height: 1.9, color: colors.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          DaramCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AboutRow(
                  icon: LucideIcons.shieldCheck,
                  title: 'حریم خصوصی',
                  body: 'هیچ حساب کاربری، سرور یا Firebase وجود ندارد. داده‌های مالی فقط روی دستگاه ذخیره می‌شوند. هنگام استفاده از دستیار، فقط متن گفتگو و زمینه لازم (حساب‌ها و دسته‌بندی‌ها) به سرویس‌دهنده‌ای که خودتان انتخاب کرده‌اید فرستاده می‌شود.',
                ),
                const SizedBox(height: 14),
                _AboutRow(
                  icon: LucideIcons.lock,
                  title: 'کلید API',
                  body: 'کلید در حافظه امن دستگاه نگهداری می‌شود و در پایگاه داده، لاگ یا فایل پشتیبان قرار نمی‌گیرد.',
                ),
                const SizedBox(height: 14),
                _AboutRow(
                  icon: LucideIcons.phone,
                  title: 'این نسخه',
                  body:
                      '${AppInfo.phase} — بدون اتصال به بانک، بدون خواندن پیامک و بدون اجرای پرداخت. تمام محاسبات مالی در دستگاه و با اعداد صحیح ریالی انجام می‌شود.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DaramCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'منابع و مجوزها',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                _CreditRow(
                  label: 'قلم وزیرمتن',
                  value: 'SIL OFL 1.1 · rastikerdar/vazirmatn',
                ),
                _CreditRow(
                  label: 'لوگوی بانک‌ها',
                  value: 'CC0 1.0 · zegond/logos-per-banks',
                ),
                _CreditRow(
                  label: 'لوگوی بلوبانک',
                  value: 'CC BY-SA 4.0 · Wikimedia Commons (blubank)',
                ),
                _CreditRow(label: 'آیکون‌ها', value: 'Lucide · ISC License'),
                _CreditRow(
                  label: 'چارچوب',
                  value: 'Flutter · Dart · Drift · Riverpod',
                ),
                _CreditRow(
                  label: 'دارام و هویت بصری',
                  value: 'طراحی اختصاصی این پروژه',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'دارام',
              applicationVersion: appVersionLabel(info),
              applicationIcon: const Padding(
                padding: EdgeInsets.all(8),
                child: DaramMark(size: 48),
              ),
            ),
            icon: const Icon(LucideIcons.fileText, size: 16),
            label: const Text('مجوزهای نرم‌افزاری'),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              AppInfo.taglineEn,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.textMuted, letterSpacing: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: colors.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                body,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.textSecondary, height: 1.8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
