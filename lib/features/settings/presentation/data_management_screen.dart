import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/time/calendar_date.dart';
import '../../chat/presentation/chat_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../transactions/presentation/transactions_section.dart';
import '../data/export_service.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() =>
      _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  String? _busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final today = CalendarDate.today();
    final range = DateRange(today.startOfJalaliMonth, today);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('مدیریت داده‌ها'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.arrowRight, size: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.hardDrive, size: 18, color: colors.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    kIsWeb
                        ? 'همه داده‌ها در حافظه مرورگر ذخیره می‌شوند. پاک کردن داده‌های مرورگر، داده‌های دارام را هم از بین می‌برد؛ مرتب پشتیبان بگیر. فایل پشتیبان رمزگذاری نمی‌شود.'
                        : 'همه داده‌ها روی همین دستگاه ذخیره می‌شوند. فایل پشتیبان رمزگذاری نمی‌شود؛ آن را در جای امن نگه دار.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.textSecondary, height: 1.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ActionCard(
            icon: LucideIcons.fileText,
            color: colors.income,
            title: 'خروجی CSV تراکنش‌ها',
            description:
                'تراکنش‌های این ماه به‌صورت فایل CSV با پشتیبانی از فارسی.',
            actionLabel: 'دریافت CSV',
            busy: _busy == 'csv',
            onTap: () => _exportCsv(range),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: LucideIcons.fileDown,
            color: colors.expense,
            title: 'گزارش PDF',
            description:
                'گزارش مالی این ماه با نمودار خلاصه و جدول دسته‌بندی‌ها.',
            actionLabel: 'دریافت PDF',
            busy: _busy == 'pdf',
            onTap: () => _exportPdf(range),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: LucideIcons.download,
            color: colors.transfer,
            title: 'پشتیبان کامل',
            description: 'همه حساب‌ها، تراکنش‌ها، وام‌ها، گفتگوها و پیش‌نویس‌ها در یک فایل JSON.',
            actionLabel: 'ساخت پشتیبان',
            busy: _busy == 'backup',
            onTap: _exportBackup,
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: LucideIcons.upload,
            color: colors.warning,
            title: 'بازیابی از پشتیبان',
            description: 'داده‌های فعلی با محتوای فایل پشتیبان جایگزین می‌شوند. پیش از بازیابی، پشتیبان بگیر.',
            actionLabel: 'انتخاب فایل',
            busy: _busy == 'restore',
            onTap: _restore,
          ),
          const SizedBox(height: 20),
          Text(
            'خروجی‌ها با واحد تومان و تاریخ شمسی نمایش داده می‌شوند؛ مبلغ‌های ذخیره‌شده در فایل پشتیبان همیشه ریال هستند.',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(DateRange range) async {
    setState(() => _busy = 'csv');
    try {
      final bytes = await ref
          .read(exportServiceProvider)
          .transactionsCsv(range);
      await _save(
        bytes,
        'daram-transactions-${range.end.toIso()}.csv',
        'text/csv',
      );
    } on Object {
      _error('ساخت فایل CSV ممکن نشد.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _exportPdf(DateRange range) async {
    setState(() => _busy = 'pdf');
    try {
      final bytes = await ref.read(exportServiceProvider).reportPdf(range);
      await _save(
        bytes,
        'daram-report-${range.end.toIso()}.pdf',
        'application/pdf',
      );
    } on Object {
      _error('ساخت گزارش PDF ممکن نشد.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _busy = 'backup');
    try {
      final bytes = await ref.read(exportServiceProvider).backupJson();
      await _save(
        bytes,
        'daram-backup-${DateTime.now().toUtc().toIso8601String().substring(0, 10)}.json',
        'application/json',
      );
    } on Object {
      _error('ساخت پشتیبان ممکن نشد.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _save(Uint8List bytes, String name, String mimeType) async {
    try {
      final uri = await ref
          .read(exportServiceProvider)
          .saveFile(fileName: name, bytes: bytes, mimeType: mimeType);
      if (!mounted) return;
      if (uri != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'فایل ذخیره شد: ${uri.pathSegments.isEmpty ? name : uri.pathSegments.last}',
              ),
            ),
          );
      }
    } on Object {
      if (!mounted) return;
      _error('ذخیره فایل ممکن نشد.');
    }
  }

  Future<void> _restore() async {
    final ExportService service = ref.read(exportServiceProvider);
    Uint8List? bytes;
    try {
      bytes = await service.pickBackupFile();
    } on Object {
      _error('خواندن فایل ممکن نشد.');
      return;
    }
    if (bytes == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بازیابی پشتیبان'),
        content: const Text(
          'همه داده‌های فعلی (حساب‌ها، تراکنش‌ها، وام‌ها و گفتگوها) با محتوای این فایل جایگزین می‌شود. اگر داده فعلی مهمی داری، اول پشتیبان بگیر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.daram.warning,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('بازیابی'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = 'restore');
    try {
      final summary = await service.restore(bytes);
      ref.invalidate(accountsStreamProvider);
      ref.invalidate(categoriesStreamProvider);
      ref.invalidate(transactionFeedProvider);
      ref.invalidate(transfersFeedProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(chatControllerProvider);
      if (!mounted) return;
      final total = summary.rowCounts.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('پشتیبان بازیابی شد ($total رکورد).')),
        );
    } on AppException catch (error) {
      _error(error.message);
    } on Object {
      _error('بازیابی پشتیبان ممکن نشد؛ داده‌های فعلی تغییری نکرد.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _error(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
    required this.busy,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return DaramCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              SizedBox(
                height: 38,
                child: FilledButton(
                  onPressed: busy ? null : onTap,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    backgroundColor: color.withValues(alpha: 0.14),
                    foregroundColor: color,
                  ),
                  child: busy
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: color,
                          ),
                        )
                      : Text(actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
