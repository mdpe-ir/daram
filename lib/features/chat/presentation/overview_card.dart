import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/daram_colors.dart';
import '../../../core/formatting/persian_formatting.dart';

/// Rich chat card for the `get_financial_overview` tool.
///
/// Every number is already computed and formatted by the tool in the user's
/// display currency, so the card only lays it out and never does money math.
class ChatOverviewCard extends StatelessWidget {
  const ChatOverviewCard({super.key, required this.overview});

  final Map<String, Object?> overview;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final health = _map(overview['health']);
    final cashflow = _map(overview['cashflow']);
    final roadmap = _list(overview['roadmap']);
    final categories = _list(overview['top_expense_categories']);
    final installments = _list(overview['upcoming_installments']);
    final score = _int(health['score']);
    final scoreColor = score >= 80
        ? colors.income
        : score >= 60
        ? colors.accent
        : score >= 40
        ? colors.warning
        : colors.expense;

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
                    LucideIcons.gauge,
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
                        'وضعیت مالی',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _text(overview['as_of_label_fa'], fallback: ''),
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: scoreColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${PersianDigits.toPersian('$score')} · ${_text(health['label'], fallback: '')}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scoreColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ارزش خالص',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  _text(overview['net_worth_display'], fallback: '—'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetricChip(
                  icon: LucideIcons.wallet,
                  label: 'نقدینگی',
                  value: _text(overview['cash_display'], fallback: '—'),
                  color: colors.accent,
                ),
                _MetricChip(
                  icon: LucideIcons.gem,
                  label: 'دارایی‌ها',
                  value: _text(overview['assets_display'], fallback: '—'),
                  color: colors.income,
                ),
                _MetricChip(
                  icon: LucideIcons.receiptText,
                  label: 'طلب‌ها',
                  value: _text(overview['receivables_display'], fallback: '—'),
                  color: colors.transfer,
                ),
                _MetricChip(
                  icon: LucideIcons.landmark,
                  label: 'بدهی‌ها',
                  value: _text(
                    overview['loans_outstanding_display'],
                    fallback: '—',
                  ),
                  color: colors.expense,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(height: 1, color: colors.divider),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'سلامت مالی',
                      style: Theme.of(context).textTheme.labelMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${PersianDigits.toPersian('$score')} از ۱۰۰',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: scoreColor),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (score.clamp(0, 100)) / 100,
                    minHeight: 7,
                    backgroundColor: colors.surfaceMuted,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _SmallStat(
                      label: 'نرخ پس‌انداز',
                      value: _percent(cashflow['savings_rate_percent']),
                    ),
                    _SmallStat(
                      label: 'پوشش اضطراری',
                      value: _months(health['emergency_months']),
                    ),
                    _SmallStat(
                      label: 'نسبت بدهی',
                      value: _percent(health['debt_ratio_percent']),
                    ),
                    _SmallStat(
                      label: 'میانگین درآمد ماه',
                      value: _text(
                        cashflow['avg_income_display'],
                        fallback: '—',
                      ),
                    ),
                    _SmallStat(
                      label: 'میانگین هزینه ماه',
                      value: _text(
                        cashflow['avg_expense_display'],
                        fallback: '—',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (roadmap.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                'قدم‌های بعدی',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
              child: Column(
                children: [
                  for (final item in roadmap.take(4)) _RoadmapRow(item: item),
                ],
              ),
            ),
          ],
          if (categories.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Text(
                'بیشترین هزینه این ماه',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
              child: Column(
                children: [
                  for (final item in categories.take(4))
                    _CategoryRow(item: item),
                ],
              ),
            ),
          ],
          if (installments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 2),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendarClock,
                    size: 14,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'قسط بعدی: ${_text(installments.first['amount_display'], fallback: '—')}'
                      ' · ${_text(installments.first['due_date_label_fa'], fallback: '')}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Text(
              'محاسبه‌شده از داده‌های محلی دارام',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.textMuted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, Object?> _map(Object? value) => value is Map
      ? value.map((key, item) => MapEntry('$key', item))
      : const <String, Object?>{};

  static List<Map<String, Object?>> _list(Object? value) => value is List
      ? [
          for (final item in value)
            if (item is Map) item.map((key, entry) => MapEntry('$key', entry)),
        ]
      : const <Map<String, Object?>>[];

  static int _int(Object? value) => value is num ? value.toInt() : 0;

  static String _text(Object? value, {required String fallback}) {
    if (value == null) return fallback;
    final text = '$value'.trim();
    return text.isEmpty ? fallback : text;
  }

  static String _percent(Object? value) {
    if (value is num) {
      final rounded = value.round();
      final sign = rounded > 0 ? '+' : '';
      return '$sign${PersianDigits.toPersian('$rounded')}٪';
    }
    return '—';
  }

  static String _months(Object? value) {
    if (value is num) {
      return '${PersianDigits.toPersian(value.toStringAsFixed(1))} ماه';
    }
    final text = _text(value, fallback: '');
    return text.isEmpty ? '—' : '$text ماه';
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Container(
      width: 132,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted, fontSize: 10),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.textMuted, fontSize: 10),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w600, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _RoadmapRow extends StatelessWidget {
  const _RoadmapRow({required this.item});

  final Map<String, Object?> item;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final priority = '${item['priority'] ?? 'low'}';
    final color = switch (priority) {
      'high' => colors.expense,
      'medium' => colors.warning,
      _ => colors.accent,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['title'] ?? ''}',
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${item['detail'] ?? ''}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item});

  final Map<String, Object?> item;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final share = item['share_percent'];
    final percent = share is num ? share.round().clamp(0, 100) : 0;
    final color = _hexColor('${item['color_hex'] ?? '#94A3B8'}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              '${item['name'] ?? ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${item['amount_display'] ?? ''}',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 34,
            child: Text(
              '${PersianDigits.toPersian('$percent')}٪',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.textMuted, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Color _hexColor(String value) {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16);
    if (parsed == null) return const Color(0xFF94A3B8);
    return Color(0xFF000000 | parsed);
  }
}
