import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/jalali_text.dart';
import '../../ai/domain/ai_log.dart';

/// Local diagnostics for failed or empty assistant answers.
class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  bool _errorsOnly = false;
  final Set<String> _expanded = <String>{};

  String _formatTime(DateTime time) {
    final date = JalaliText(persianDigits: false)
        .numeric(CalendarDate.fromDateTime(time));
    String two(int value) => value.toString().padLeft(2, '0');
    final clock = '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
    return PersianDigits.toPersian('$date · $clock');
  }

  String _report(List<AILogEntry> entries) {
    final buffer = StringBuffer('DARAM · گزارش عیب‌یابی دستیار\n\n');
    for (final entry in entries) {
      buffer
        ..writeln(
          '[${entry.level.name.toUpperCase()}] '
          '${entry.time.toIso8601String()} · ${entry.area.name}',
        )
        ..writeln(entry.title);
      final meta = [
        if (entry.provider != null) entry.provider!,
        if (entry.model != null) entry.model!,
        if (entry.statusCode != null) 'HTTP ${entry.statusCode}',
        if (entry.durationMs != null) '${entry.durationMs}ms',
      ].join(' · ');
      if (meta.isNotEmpty) buffer.writeln(meta);
      if (entry.detail != null) buffer.writeln(entry.detail);
      buffer.writeln();
    }
    return buffer.toString();
  }

  Future<void> _copy(List<AILogEntry> entries) async {
    if (entries.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: _report(entries)));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${PersianDigits.toPersian('${entries.length}')} رویداد کپی شد.',
          ),
        ),
      );
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('پاک کردن گزارش‌ها'),
        content: const Text(
          'همه رویدادهای ذخیره‌شده روی این دستگاه پاک شوند؟ این کار روی گفتگوها و داده‌های مالی اثری ندارد.',
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
            child: const Text('پاک کردن'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(aiLogStoreProvider).clear();
    setState(_expanded.clear);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final store = ref.watch(aiLogStoreProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        centerTitle: false,
        title: const Text('گزارش‌های دستیار'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.arrowRight, size: 20),
        ),
        actions: [
          ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final all = store.entries;
              final visible = _errorsOnly
                  ? all
                        .where((entry) => entry.level == AILogLevel.error)
                        .toList()
                  : all;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'کپی گزارش‌ها',
                    onPressed: visible.isEmpty ? null : () => _copy(visible),
                    icon: const Icon(LucideIcons.copy, size: 18),
                  ),
                  IconButton(
                    tooltip: 'پاک کردن گزارش‌ها',
                    onPressed: all.isEmpty ? null : _confirmClear,
                    icon: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: all.isEmpty ? colors.textMuted : colors.expense,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final all = store.entries;
          final entries = _errorsOnly
              ? all.where((entry) => entry.level == AILogLevel.error).toList()
              : all;
          return ListView(
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
                    Icon(
                      LucideIcons.scrollText,
                      size: 18,
                      color: colors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'رویدادهای درخواست دستیار روی همین دستگاه ذخیره می‌شوند تا وقتی پاسخ نمی‌آید بتوانی علت را ببینی. کلید API، هدرها و متن کامل گفتگو در گزارش‌ها ثبت نمی‌شود.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          height: 1.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DaramChip(
                    label: 'همه (${PersianDigits.toPersian('${all.length}')})',
                    selected: !_errorsOnly,
                    icon: LucideIcons.list,
                    onTap: () => setState(() => _errorsOnly = false),
                  ),
                  DaramChip(
                    label:
                        'فقط خطاها (${PersianDigits.toPersian('${store.errorCount}')})',
                    selected: _errorsOnly,
                    icon: LucideIcons.circleAlert,
                    onTap: () => setState(() => _errorsOnly = true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (entries.isEmpty)
                EmptyState(
                  icon: _errorsOnly
                      ? LucideIcons.circleCheck
                      : LucideIcons.scrollText,
                  title: _errorsOnly ? 'خطایی ثبت نشده' : 'گزارشی ثبت نشده',
                  message: _errorsOnly ? 'هیچ خطایی در رویدادهای فعلی نیست.' : 'به محض اولین درخواست به دستیار، رویدادها اینجا ثبت می‌شوند.',
                )
              else
                for (final entry in entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _LogTile(
                      entry: entry,
                      timeLabel: _formatTime(entry.time),
                      expanded: _expanded.contains(entry.id),
                      onToggle: entry.detail == null
                          ? null
                          : () => setState(() {
                              if (!_expanded.add(entry.id)) {
                                _expanded.remove(entry.id);
                              }
                            }),
                      onCopy: entry.detail == null
                          ? null
                          : () => _copy(<AILogEntry>[entry]),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({
    required this.entry,
    required this.timeLabel,
    required this.expanded,
    required this.onToggle,
    required this.onCopy,
  });

  final AILogEntry entry;
  final String timeLabel;
  final bool expanded;
  final VoidCallback? onToggle;
  final VoidCallback? onCopy;

  Color _color(DaramColors colors) => switch (entry.level) {
    AILogLevel.error => colors.expense,
    AILogLevel.warning => colors.warning,
    AILogLevel.info => switch (entry.area) {
      AILogArea.network => colors.transfer,
      AILogArea.tool => colors.warning,
      AILogArea.chat => colors.accent,
    },
  };

  IconData _icon() => switch (entry.area) {
    AILogArea.chat => LucideIcons.sparkles,
    AILogArea.network => LucideIcons.wifi,
    AILogArea.tool => LucideIcons.wrench,
  };

  String get _meta => [
    timeLabel,
    entry.area.labelFa,
    if (entry.provider != null) entry.provider!,
    if (entry.model != null) isolateLtr(entry.model!),
    if (entry.statusCode != null) 'HTTP ${entry.statusCode}',
    if (entry.durationMs != null) '${entry.durationMs}ms',
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final color = _color(colors);
    return DaramCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      entry.level == AILogLevel.error
                          ? LucideIcons.circleAlert
                          : _icon(),
                      size: 17,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _meta,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (onToggle != null)
                    Icon(
                      expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: colors.textMuted,
                    ),
                ],
              ),
            ),
          ),
          if (expanded && entry.detail != null) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.divider),
              ),
              child: SelectableText(
                entry.detail!,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.7,
                  color: colors.textSecondary,
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 6),
                child: TextButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(LucideIcons.copy, size: 14),
                  label: const Text('کپی جزئیات'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
