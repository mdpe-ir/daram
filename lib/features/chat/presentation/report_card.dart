import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';

class ReportCategorySlice {
  const ReportCategorySlice({
    required this.name,
    required this.amount,
    required this.share,
    required this.colorHex,
  });

  factory ReportCategorySlice.fromJson(Map<String, Object?> json) =>
      ReportCategorySlice(
        name: (json['name'] ?? 'بدون دسته‌بندی').toString(),
        amount: Rial((json['amountRial'] as num?)?.toInt() ?? 0),
        share: (json['share'] as num?)?.toDouble() ?? 0,
        colorHex: (json['colorHex'] ?? '#94A3B8').toString(),
      );

  final String name;
  final Rial amount;
  final double share;
  final String colorHex;
}

/// Report payload attached to an assistant message.
class ReportCardData {
  const ReportCardData({
    required this.start,
    required this.end,
    required this.income,
    required this.expense,
    required this.net,
    required this.count,
    required this.categories,
    this.accountId,
    this.categoryId,
  });

  factory ReportCardData.fromJson(Map<String, Object?> json) {
    final range = json['range'];
    final summary = json['summary'];
    final rangeMap = range is Map ? range : const {};
    final summaryMap = summary is Map ? summary : const {};
    final rawCategories = json['categories'];
    return ReportCardData(
      start: CalendarDate.parseIso('${rangeMap['start'] ?? '2024-01-01'}'),
      end: CalendarDate.parseIso('${rangeMap['end'] ?? '2024-01-01'}'),
      income: Rial((summaryMap['incomeRial'] as num?)?.toInt() ?? 0),
      expense: Rial((summaryMap['expenseRial'] as num?)?.toInt() ?? 0),
      net: Rial((summaryMap['netRial'] as num?)?.toInt() ?? 0),
      count: (summaryMap['count'] as num?)?.toInt() ?? 0,
      categories: rawCategories is List
          ? rawCategories
                .whereType<Map>()
                .map(
                  (item) => ReportCategorySlice.fromJson(
                    item.map((key, value) => MapEntry('$key', value)),
                  ),
                )
                .toList()
          : const [],
    );
  }

  final CalendarDate start;
  final CalendarDate end;
  final Rial income;
  final Rial expense;
  final Rial net;
  final int count;
  final List<ReportCategorySlice> categories;
  final String? accountId;
  final String? categoryId;

  Map<String, Object?> toJson() => {
    'range': {'start': start.toIso(), 'end': end.toIso()},
    'summary': {
      'incomeRial': income.value,
      'expenseRial': expense.value,
      'netRial': net.value,
      'count': count,
    },
    'categories': [
      for (final item in categories)
        {
          'name': item.name,
          'amountRial': item.amount.value,
          'share': item.share,
          'colorHex': item.colorHex,
        },
    ],
  };
}

class ChatReportCard extends ConsumerWidget {
  const ChatReportCard({super.key, required this.report});

  final ReportCardData report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    final slices = report.categories.take(5).toList();
    final total = report.categories.fold<int>(
      0,
      (sum, item) => sum + item.amount.value,
    );

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    LucideIcons.chartPie,
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
                        'گزارش مالی',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '${format.dates.date(report.start)} تا ${format.dates.date(report.end)}',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(LucideIcons.fileDown, size: 18),
                  onSelected: (value) => _export(context, ref, value),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'pdf', child: Text('خروجی PDF')),
                    PopupMenuItem(value: 'csv', child: Text('خروجی CSV')),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: colors.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                _ReportStatRow(
                  label: 'درآمد',
                  amount: report.income,
                  color: colors.income,
                ),
                const SizedBox(height: 8),
                _ReportStatRow(
                  label: 'هزینه',
                  amount: report.expense,
                  color: colors.expense,
                ),
                const SizedBox(height: 8),
                _ReportStatRow(
                  label: 'خالص',
                  amount: report.net,
                  color: report.net.isNegative ? colors.expense : colors.accent,
                ),
                if (slices.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sections: [
                                  for (final slice in slices)
                                    PieChartSectionData(
                                      value: slice.amount.value.toDouble(),
                                      color: daramColorFromHex(slice.colorHex),
                                      radius: 18,
                                      showTitle: false,
                                    ),
                                ],
                                centerSpaceRadius: 46,
                                sectionsSpace: 2,
                                startDegreeOffset: -90,
                              ),
                            ),
                            Text(
                              'هزینه',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            for (final slice in slices)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: daramColorFromHex(
                                          slice.colorHex,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: Text(
                                        slice.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                    Text(
                                      total == 0
                                          ? ''
                                          : '${PersianDigits.toPersian((slice.amount.value / total * 100).round().toString())}٪',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: colors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.info,
                          size: 15,
                          color: colors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'در این بازه تراکنشی ثبت نشده است.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 12, 12),
            child: Row(
              children: [
                Text(
                  '${PersianDigits.toPersian('${report.count}')} تراکنش',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('مشاهده در آمار'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    WidgetRef ref,
    String format,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final range = DateRange(report.start, report.end);
      final service = ref.read(exportServiceProvider);
      final bytes = format == 'pdf'
          ? await service.reportPdf(
              range,
              accountId: report.accountId,
              categoryId: report.categoryId,
            )
          : await service.transactionsCsv(
              range,
              accountId: report.accountId,
              categoryId: report.categoryId,
            );
      final name = format == 'pdf'
          ? 'daram-report-${report.end.toIso()}.pdf'
          : 'daram-transactions-${report.end.toIso()}.csv';
      await service.saveFile(
        fileName: name,
        bytes: bytes,
        mimeType: format == 'pdf' ? 'application/pdf' : 'text/csv',
      );
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              format == 'pdf' ? 'گزارش PDF آماده شد.' : 'فایل CSV آماده شد.',
            ),
          ),
        );
    } on Object {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('ساخت خروجی ممکن نشد.')));
    }
  }
}

class _ReportStatRow extends StatelessWidget {
  const _ReportStatRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final Rial amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final formatter = DaramFormatScope.of(context).money;
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: context.daram.textMuted),
        ),
        const Spacer(),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              formatter.format(amount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
