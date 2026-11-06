import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/branding/daram_logo.dart';
import '../../../app/design_system/daram_inputs.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_presets.dart';
import '../../loans/domain/loan.dart';
import '../../transactions/domain/transaction_record.dart';
import '../../loans/presentation/loans_section.dart';
import '../domain/analytics.dart';

class DashboardRangeState {
  const DashboardRangeState({required this.preset, required this.range});

  final DateRangePreset preset;
  final DateRange range;
}

class DashboardRangeController extends Notifier<DashboardRangeState> {
  @override
  DashboardRangeState build() {
    const preset = DateRangePreset.thisMonth;
    return DashboardRangeState(preset: preset, range: dateRangeFor(preset));
  }

  void select(DateRangePreset preset) {
    if (preset == DateRangePreset.custom) {
      state = DashboardRangeState(preset: preset, range: state.range);
      return;
    }
    state = DashboardRangeState(preset: preset, range: dateRangeFor(preset));
  }

  void setCustom(DateRange range) {
    state = DashboardRangeState(preset: DateRangePreset.custom, range: range);
  }
}

final dashboardRangeProvider =
    NotifierProvider<DashboardRangeController, DashboardRangeState>(
      DashboardRangeController.new,
    );

final dashboardProvider = StreamProvider.autoDispose<DashboardSnapshot>((ref) {
  final range = ref.watch(dashboardRangeProvider).range;
  return ref.watch(analyticsRepositoryProvider).watchDashboard(range: range);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final async = ref.watch(dashboardProvider);
    final rangeState = ref.watch(dashboardRangeProvider);
    final format = DaramFormatScope.of(context);
    final today = CalendarDate.today();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          color: colors.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'آمار و گزارش‌ها',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          format.dates.dateWithWeekday(today),
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
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final preset in DateRangePreset.values)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: DaramChip(
                          label: preset.labelFa,
                          icon: preset == DateRangePreset.custom
                              ? LucideIcons.calendarDays
                              : null,
                          selected: rangeState.preset == preset,
                          onTap: () async {
                            if (preset == DateRangePreset.custom) {
                              final range = await showDialog<DateRange>(
                                context: context,
                                builder: (context) => _CustomRangeDialog(
                                  initial: rangeState.range,
                                ),
                              );
                              if (range != null) {
                                ref
                                    .read(dashboardRangeProvider.notifier)
                                    .setCustom(range);
                              }
                            } else {
                              ref
                                  .read(dashboardRangeProvider.notifier)
                                  .select(preset);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => DaramCard(
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.cloudOff,
                        size: 32,
                        color: colors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'بارگذاری آمار ممکن نشد.',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'داده‌های محلی در دسترس هستند؛ دوباره تلاش کن.',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(dashboardProvider),
                        child: const Text('تلاش دوباره'),
                      ),
                    ],
                  ),
                ),
                data: (snapshot) => _DashboardBody(snapshot: snapshot),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BalanceHero(snapshot: snapshot),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'درآمد',
                amount: snapshot.summary.income,
                icon: LucideIcons.arrowDownLeft,
                color: colors.income,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'هزینه',
                amount: snapshot.summary.expense,
                icon: LucideIcons.arrowUpRight,
                color: colors.expense,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatCard(
                label: 'خالص',
                amount: snapshot.summary.net,
                icon: LucideIcons.scale,
                color: snapshot.summary.net.isNegative
                    ? colors.expense
                    : colors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MonthlyChartCard(points: snapshot.monthly),
        const SizedBox(height: 14),
        _CategoryCard(
          items: snapshot.categoryBreakdown,
          totalExpense: snapshot.summary.expense,
        ),
        if (snapshot.upcomingInstallments.isNotEmpty) ...[
          const SizedBox(height: 14),
          _UpcomingInstallments(installments: snapshot.upcomingInstallments),
        ],
        const SizedBox(height: 14),
        _RecentTransactions(transactions: snapshot.recentTransactions),
        if (snapshot.loans.isNotEmpty) ...[
          const SizedBox(height: 14),
          _LoanSummary(loans: snapshot.loans),
        ],
      ],
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: colors.balanceGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'موجودی کل',
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: Colors.white.withValues(alpha: 0.72)),
              ),
              const Spacer(),
              const DaramMark(size: 26),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              format.money.format(snapshot.totalBalance),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${PersianDigits.toPersian('${snapshot.accounts.length}')} حساب فعال',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: Colors.white.withValues(alpha: 0.6)),
          ),
          if (snapshot.accounts.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.14)),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final account = snapshot.accounts[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        BankAvatar(
                          bankId: account.account.bankId,
                          bankName: account.account.bankName,
                          size: 26,
                        ),
                        const SizedBox(width: 7),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              account.account.accountName,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              format.money.format(account.balance),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 10,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final Rial amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: AmountText(
              amount,
              style: Theme.of(context).textTheme.titleSmall,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyChartCard extends StatelessWidget {
  const _MonthlyChartCard({required this.points});

  final List<MonthlyPoint> points;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final maxValue = points.fold<double>(0, (max, point) {
      final value = point.income.value > point.expense.value
          ? point.income.value
          : point.expense.value;
      return value > max ? value.toDouble() : max;
    });
    final hasData = maxValue > 0;

    return DaramCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'روند ماهانه',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              _LegendDot(color: colors.income, label: 'درآمد'),
              const SizedBox(width: 10),
              _LegendDot(color: colors.expense, label: 'هزینه'),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasData)
            Container(
              height: 150,
              alignment: Alignment.center,
              child: Text(
                'برای این بازه هنوز داده‌ای ثبت نشده است.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.textMuted),
              ),
            )
          else
            SizedBox(
              height: 168,
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.18,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barsSpace: 3,
                        barRods: [
                          BarChartRodData(
                            toY: points[i].income.value.toDouble(),
                            color: colors.income,
                            width: 7,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          BarChartRodData(
                            toY: points[i].expense.value.toDouble(),
                            color: colors.expense,
                            width: 7,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              points[index].label,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.textMuted,
                                    fontSize: 9.5,
                                  ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue / 3,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colors.divider,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => colors.surfaceElevated,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'درآمد' : 'هزینه';
                        return BarTooltipItem(
                          '$label\n${DaramFormatScope.of(context).money.format(Rial(rod.toY.toInt()))}',
                          Theme.of(context).textTheme.labelSmall!
                              .copyWith(color: colors.textPrimary),
                        );
                      },
                    ),
                  ),
                ),
                duration: const Duration(milliseconds: 450),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: context.daram.textMuted),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.items, required this.totalExpense});

  final List<CategoryBreakdownItem> items;
  final Rial totalExpense;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final shown = items.take(5).toList();
    return DaramCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'هزینه‌ها بر اساس دسته',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              Text(
                '${PersianDigits.toPersian('${items.length}')} دسته',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'هنوز هزینه‌ای در این بازه ثبت نشده.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 132,
                  height: 132,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: [
                            for (final item in shown)
                              PieChartSectionData(
                                value: item.amount.value.toDouble(),
                                color: daramColorFromHex(item.colorHex),
                                radius: 17,
                                showTitle: false,
                              ),
                          ],
                          centerSpaceRadius: 46,
                          sectionsSpace: 2,
                          startDegreeOffset: -90,
                        ),
                        duration: const Duration(milliseconds: 450),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'هزینه',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              DaramFormatScope.of(context).money
                                  .format(totalExpense),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    children: [
                      for (final item in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: daramColorFromHex(item.colorHex),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                '${PersianDigits.toPersian('${(item.share * 100).round()}')}٪',
                                style: Theme.of(context).textTheme.labelSmall
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
        ],
      ),
    );
  }
}

class _UpcomingInstallments extends ConsumerWidget {
  const _UpcomingInstallments({required this.installments});

  final List<Installment> installments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    return DaramCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'اقساط نزدیک',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/records/loans'),
                child: const Text('همه وام‌ها'),
              ),
            ],
          ),
          for (final installment in installments.take(3))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.calendarClock,
                      size: 16,
                      color: colors.warning,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قسط ${PersianDigits.toPersian('${installment.number}')} — ${installment.loanTitle ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          format.dates.date(
                            CalendarDate.fromStored(installment.dueDate),
                          ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  AmountText(
                    installment.amountRial,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'ثبت پرداخت',
                    onPressed: () => _showPaySheet(context, ref, installment),
                    icon: Icon(
                      LucideIcons.checkCircle2,
                      size: 18,
                      color: colors.income,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showPaySheet(
    BuildContext context,
    WidgetRef ref,
    Installment installment,
  ) async {
    final paid = await showInstallmentPaySheet(
      context,
      ref,
      installment: installment,
    );
    if (paid == true) {
      ref.invalidate(dashboardProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('قسط ثبت شد.')));
      }
    }
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions({required this.transactions});

  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    return DaramCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'تراکنش‌های اخیر',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go('/records/transactions'),
                child: const Text('همه'),
              ),
            ],
          ),
          if (transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  'هنوز تراکنشی ثبت نشده است.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ),
            )
          else
            for (final transaction in transactions)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    CategoryAvatar(
                      icon: transaction.categoryIcon ?? 'circle-ellipsis',
                      colorHex: transaction.categoryColorHex ?? '#94A3B8',
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.description?.isNotEmpty == true
                                ? transaction.description!
                                : (transaction.categoryName ?? 'تراکنش'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '${format.dates.relative(CalendarDate.fromStored(transaction.transactionDate))} · ${transaction.accountName ?? ''}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    AmountText(
                      transaction.amountRial,
                      style: Theme.of(context).textTheme.labelMedium,
                      color: transaction.isIncome
                          ? colors.income
                          : colors.expense,
                      signed: true,
                      showSymbol: false,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _LoanSummary extends StatelessWidget {
  const _LoanSummary({required this.loans});

  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    final active = loans.where((loan) => !loan.isClosed).toList();
    final outstanding = Rial.sum(active.map((loan) => loan.outstandingRial));
    return DaramCard(
      onTap: () => context.go('/records/loans'),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(LucideIcons.banknote, size: 19, color: colors.warning),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بدهی وام‌ها',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${PersianDigits.toPersian('${active.length}')} وام در جریان · ${format.money.format(outstanding)}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          Icon(LucideIcons.chevronLeft, size: 17, color: colors.textMuted),
        ],
      ),
    );
  }
}

class _CustomRangeDialog extends StatefulWidget {
  const _CustomRangeDialog({required this.initial});

  final DateRange initial;

  @override
  State<_CustomRangeDialog> createState() => _CustomRangeDialogState();
}

class _CustomRangeDialogState extends State<_CustomRangeDialog> {
  late CalendarDate _start = widget.initial.start;
  late CalendarDate _end = widget.initial.end;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('بازه دلخواه'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          JalaliDateField(
            value: _start,
            label: 'از تاریخ',
            lastDate: _end,
            onChanged: (value) => setState(() => _start = value),
          ),
          const SizedBox(height: 12),
          JalaliDateField(
            value: _end,
            label: 'تا تاریخ',
            firstDate: _start,
            onChanged: (value) => setState(() => _end = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(DateRange(_start, _end)),
          child: const Text('اعمال'),
        ),
      ],
    );
  }
}
