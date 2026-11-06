import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_inputs.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/domain/enums.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/date_presets.dart';
import '../../accounts/domain/account.dart';
import '../../categories/domain/category.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/transaction_record.dart';

enum TransactionView { all, income, expense, transfers }

class TransactionFilterState {
  const TransactionFilterState({
    this.view = TransactionView.all,
    this.accountId,
    this.categoryId,
    this.start,
    this.end,
    this.search = '',
  });

  final TransactionView view;
  final String? accountId;
  final String? categoryId;
  final CalendarDate? start;
  final CalendarDate? end;
  final String search;

  bool get hasFilters =>
      accountId != null ||
      categoryId != null ||
      start != null ||
      end != null ||
      search.isNotEmpty;
}

class TransactionFilterController extends Notifier<TransactionFilterState> {
  @override
  TransactionFilterState build() => const TransactionFilterState();

  void setView(TransactionView view) => state = TransactionFilterState(
    view: view,
    accountId: state.accountId,
    categoryId: view == TransactionView.transfers ? null : state.categoryId,
    start: state.start,
    end: state.end,
    search: state.search,
  );

  void setSearch(String value) => state = TransactionFilterState(
    view: state.view,
    accountId: state.accountId,
    categoryId: state.categoryId,
    start: state.start,
    end: state.end,
    search: value,
  );

  void setAccount(String? id) => state = TransactionFilterState(
    view: state.view,
    accountId: id,
    categoryId: state.categoryId,
    start: state.start,
    end: state.end,
    search: state.search,
  );

  void setCategory(String? id) => state = TransactionFilterState(
    view: state.view,
    accountId: state.accountId,
    categoryId: id,
    start: state.start,
    end: state.end,
    search: state.search,
  );

  void setRange(CalendarDate? start, CalendarDate? end) =>
      state = TransactionFilterState(
        view: state.view,
        accountId: state.accountId,
        categoryId: state.categoryId,
        start: start,
        end: end,
        search: state.search,
      );

  void clear() => state = TransactionFilterState(view: state.view);
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterController, TransactionFilterState>(
      TransactionFilterController.new,
    );

final transactionFeedProvider =
    StreamProvider.autoDispose<List<TransactionRecord>>((ref) {
      final filter = ref.watch(transactionFilterProvider);
      if (filter.view == TransactionView.transfers) return const Stream.empty();
      return ref
          .watch(transactionRepositoryProvider)
          .watch(
            TransactionFilter(
              type: switch (filter.view) {
                TransactionView.income => TransactionType.income,
                TransactionView.expense => TransactionType.expense,
                _ => null,
              },
              accountId: filter.accountId,
              categoryId: filter.categoryId,
              start: filter.start?.stored,
              end: filter.end?.stored,
              searchQuery: filter.search.trim().isEmpty
                  ? null
                  : filter.search.trim(),
              limit: 500,
            ),
          );
    });

final transfersFeedProvider = StreamProvider.autoDispose<List<TransferRecord>>((
  ref,
) {
  final filter = ref.watch(transactionFilterProvider);
  return ref.watch(transferRepositoryProvider).watch(limit: 300).map((rows) {
    return rows.where((row) {
      final date = CalendarDate.fromStored(row.transferDate);
      if (filter.start != null && date.isBefore(filter.start!)) return false;
      if (filter.end != null && date.isAfter(filter.end!)) return false;
      if (filter.accountId != null &&
          row.sourceAccountId != filter.accountId &&
          row.destinationAccountId != filter.accountId) {
        return false;
      }
      final query = filter.search.trim();
      if (query.isNotEmpty) {
        final haystack =
            '${row.description ?? ''} '
            '${row.sourceAccountName ?? ''} ${row.destinationAccountName ?? ''}';
        if (!haystack.contains(query)) return false;
      }
      return true;
    }).toList();
  });
});

class TransactionsSection extends ConsumerWidget {
  const TransactionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final filter = ref.watch(transactionFilterProvider);
    final async = filter.view == TransactionView.transfers
        ? ref
              .watch(transfersFeedProvider)
              .whenData<List<Object>>((value) => value)
        : ref
              .watch(transactionFeedProvider)
              .whenData<List<Object>>((value) => value);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => ref
                      .read(transactionFilterProvider.notifier)
                      .setSearch(value),
                  decoration: const InputDecoration(
                    hintText: 'جست‌وجو در تراکنش‌ها',
                    prefixIcon: Icon(LucideIcons.search, size: 17),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                isLabelVisible: filter.hasFilters,
                backgroundColor: colors.accent,
                child: SoftIconButton(
                  icon: LucideIcons.slidersHorizontal,
                  tooltip: 'فیلترها',
                  onTap: () => _showFilters(context, ref),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _ViewChip(
                label: 'همه',
                selected: filter.view == TransactionView.all,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .setView(TransactionView.all),
              ),
              _ViewChip(
                label: 'درآمد',
                selected: filter.view == TransactionView.income,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .setView(TransactionView.income),
              ),
              _ViewChip(
                label: 'هزینه',
                selected: filter.view == TransactionView.expense,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .setView(TransactionView.expense),
              ),
              _ViewChip(
                label: 'انتقال‌ها',
                selected: filter.view == TransactionView.transfers,
                onTap: () => ref
                    .read(transactionFilterProvider.notifier)
                    .setView(TransactionView.transfers),
              ),
            ],
          ),
        ),
        if (filter.hasFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                if (filter.start != null && filter.end != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: StatusPill(
                      label:
                          '${DaramFormatScope.of(context).dates.date(filter.start!)} تا ${DaramFormatScope.of(context).dates.date(filter.end!)}',
                      color: colors.transfer,
                      icon: LucideIcons.calendarDays,
                      compact: true,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      ref.read(transactionFilterProvider.notifier).clear(),
                  child: const Text('پاک کردن فیلترها'),
                ),
              ],
            ),
          ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => EmptyState(
              icon: LucideIcons.circleAlert,
              title: 'بارگذاری تراکنش‌ها ممکن نشد',
              action: OutlinedButton(
                onPressed: () {
                  ref.invalidate(transactionFeedProvider);
                  ref.invalidate(transfersFeedProvider);
                },
                child: const Text('تلاش دوباره'),
              ),
            ),
            data: (items) {
              if (filter.view == TransactionView.transfers) {
                final transfers = items.cast<TransferRecord>();
                if (transfers.isEmpty) {
                  return const EmptyState(
                    icon: LucideIcons.arrowLeftRight,
                    title: 'انتقالی ثبت نشده',
                    message: 'برای جابه‌جایی پول بین حساب‌های خودت، از دکمه افزودن یا گفتگو استفاده کن.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  itemCount: transfers.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TransferTile(transfer: transfers[index]),
                  ),
                );
              }
              final transactions = items.cast<TransactionRecord>();
              if (transactions.isEmpty) {
                return const EmptyState(
                  icon: LucideIcons.receiptText,
                  title: 'تراکنشی پیدا نشد',
                  message: 'می‌توانی از دکمه بالا یا از گفتگو با دارام تراکنش جدید ثبت کنی.',
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final row = transactions[index];
                  final date = CalendarDate.fromStored(row.transactionDate);
                  final previous = index == 0
                      ? null
                      : CalendarDate.fromStored(
                          transactions[index - 1].transactionDate,
                        );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (previous == null || previous != date)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                          child: Text(
                            _dateHeader(context, date),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TransactionTile(transaction: row),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _dateHeader(BuildContext context, CalendarDate date) {
    final format = DaramFormatScope.of(context);
    final relative = format.dates.relative(date);
    if (relative == 'امروز' || relative == 'دیروز') return relative;
    return format.dates.dateWithWeekday(date);
  }

  Future<void> _showFilters(BuildContext context, WidgetRef ref) async {
    final filter = ref.read(transactionFilterProvider);
    await showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FilterSheet(initial: filter),
    );
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: DaramChip(label: label, selected: selected, onTap: onTap),
    );
  }
}

class _TransactionTile extends ConsumerWidget {
  const _TransactionTile({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    return DaramCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      onTap: () => _showDetails(context, ref),
      child: Row(
        children: [
          CategoryAvatar(
            icon: transaction.categoryIcon ?? 'circle-ellipsis',
            colorHex: transaction.categoryColorHex ?? '#94A3B8',
            size: 40,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description?.isNotEmpty == true
                      ? transaction.description!
                      : (transaction.categoryName ?? transaction.type.labelFa),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${transaction.categoryName ?? 'بدون دسته‌بندی'} · ${transaction.accountName ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          AmountText(
            transaction.amountRial,
            signed: true,
            showSymbol: false,
            style: Theme.of(context).textTheme.titleSmall,
            color: transaction.isIncome ? colors.income : colors.expense,
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TransactionDetails(transaction: transaction),
    );
  }
}

class _TransferTile extends ConsumerWidget {
  const _TransferTile({required this.transfer});

  final TransferRecord transfer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    return DaramCard(
      padding: const EdgeInsets.all(12),
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('حذف انتقال'),
          content: Text(
            'انتقال ${format.money.format(transfer.amountRial)} حذف شود؟ موجودی هر دو حساب اصلاح می‌شود.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('انصراف'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.expense),
              onPressed: () async {
                await ref.read(transferRepositoryProvider).delete(transfer.id);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.transfer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.arrowLeftRight,
              size: 18,
              color: colors.transfer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${transfer.sourceAccountName ?? ''} ← ${transfer.destinationAccountName ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${format.dates.relative(CalendarDate.fromStored(transfer.transferDate))}'
                  '${transfer.feeRial.isZero ? '' : ' · کارمزد ${format.money.format(transfer.feeRial)}'}',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ],
            ),
          ),
          AmountText(
            transfer.amountRial,
            showSymbol: false,
            style: Theme.of(context).textTheme.titleSmall,
            color: colors.transfer,
          ),
        ],
      ),
    );
  }
}

class _TransactionDetails extends ConsumerWidget {
  const _TransactionDetails({required this.transaction});

  final TransactionRecord transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    final isIncome = transaction.isIncome;
    return DaramSheet(
      title: isIncome ? 'درآمد' : 'هزینه',
      subtitle: format.dates.dateWithWeekday(
        CalendarDate.fromStored(transaction.transactionDate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isIncome ? colors.income : colors.expense).withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isIncome ? colors.income : colors.expense).withValues(
                  alpha: 0.2,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  isIncome ? 'درآمد ثبت‌شده' : 'هزینه ثبت‌شده',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(height: 4),
                AmountText(
                  transaction.amountRial,
                  style: Theme.of(context).textTheme.headlineSmall,
                  color: isIncome ? colors.income : colors.expense,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'حساب', value: transaction.accountName ?? '—'),
          _DetailRow(
            label: 'دسته‌بندی',
            value: transaction.categoryName ?? 'بدون دسته‌بندی',
          ),
          _DetailRow(
            label: 'تاریخ',
            value: format.dates.date(
              CalendarDate.fromStored(transaction.transactionDate),
            ),
          ),
          _DetailRow(label: 'توضیح', value: transaction.description ?? '—'),
        ],
      ),
      actions: [
        Expanded(
          child: PrimaryButton(
            label: 'ویرایش',
            icon: LucideIcons.pencil,
            onPressed: () async {
              Navigator.of(context).pop();
              await showTransactionEditor(
                context,
                ref,
                transaction: transaction,
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        SoftIconButton(
          icon: LucideIcons.trash2,
          color: colors.expense,
          onTap: () => _delete(context, ref),
        ),
      ],
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف تراکنش'),
        content: const Text('این تراکنش حذف شود؟ موجودی حساب اصلاح می‌شود.'),
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
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(transactionRepositoryProvider).delete(transaction.id);
      if (context.mounted) Navigator.of(context).pop();
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('حذف تراکنش ممکن نشد.')));
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.daram.textMuted),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});

  final TransactionFilterState initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late DateRangePreset? _preset;
  late CalendarDate? _start;
  late CalendarDate? _end;
  late String? _accountId;
  late String? _categoryId;

  @override
  void initState() {
    super.initState();
    _start = widget.initial.start;
    _end = widget.initial.end;
    _accountId = widget.initial.accountId;
    _categoryId = widget.initial.categoryId;
    _preset = null;
    for (final preset in DateRangePreset.values) {
      if (preset == DateRangePreset.custom) continue;
      final range = dateRangeFor(preset);
      if (range.start == _start && range.end == _end) _preset = preset;
    }
  }

  void _applyPreset(DateRangePreset preset) {
    final range = dateRangeFor(preset);
    setState(() {
      _preset = preset;
      _start = range.start;
      _end = range.end;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(accountsStreamProvider).value ?? const <AccountWithBalance>[];
    final categories =
        ref.watch(categoriesStreamProvider).value ?? const <Category>[];
    final colors = context.daram;
    return DaramSheet(
      title: 'فیلترها',
      subtitle: 'بازه، حساب و دسته‌بندی را محدود کن.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('بازه زمانی', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in DateRangePreset.values)
                if (preset != DateRangePreset.custom)
                  DaramChip(
                    label: preset.labelFa,
                    selected: _preset == preset,
                    onTap: () => _applyPreset(preset),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: JalaliDateField(
                  value: _start ?? CalendarDate.today(),
                  label: 'از تاریخ',
                  lastDate: _end,
                  onChanged: (value) => setState(() {
                    _start = value;
                    _preset = DateRangePreset.custom;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: JalaliDateField(
                  value: _end ?? CalendarDate.today(),
                  label: 'تا تاریخ',
                  firstDate: _start,
                  onChanged: (value) => setState(() {
                    _end = value;
                    _preset = DateRangePreset.custom;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _accountId,
            decoration: const InputDecoration(labelText: 'حساب'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('همه حساب‌ها'),
              ),
              for (final item in accounts)
                DropdownMenuItem<String?>(
                  value: item.account.id,
                  child: Text(item.account.accountName),
                ),
            ],
            onChanged: (value) => setState(() => _accountId = value),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'دسته‌بندی'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('همه دسته‌بندی‌ها'),
              ),
              for (final category in categories)
                DropdownMenuItem<String?>(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 4),
          Text(
            'برای دیدن انتقال‌ها از فیلتر «انتقال‌ها» استفاده کن.',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: PrimaryButton(
            label: 'اعمال فیلتر',
            onPressed: () {
              final controller = ref.read(transactionFilterProvider.notifier);
              controller.setRange(_start, _end);
              controller.setAccount(_accountId);
              controller.setCategory(_categoryId);
              Navigator.of(context).pop();
            },
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () {
            ref.read(transactionFilterProvider.notifier).setRange(null, null);
            ref.read(transactionFilterProvider.notifier).setAccount(null);
            ref.read(transactionFilterProvider.notifier).setCategory(null);
            Navigator.of(context).pop();
          },
          child: const Text('پاک'),
        ),
      ],
    );
  }
}

/// Opens the manual transaction editor for create or edit.
Future<void> showTransactionEditor(
  BuildContext context,
  WidgetRef ref, {
  TransactionRecord? transaction,
}) async {
  final settings =
      ref.read(settingsControllerProvider).value ??
      const AppSettings.defaults();
  await showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _TransactionEditorSheet(
      transaction: transaction,
      defaultUnit: settings.currencyUnit,
    ),
  );
}

class _TransactionEditorSheet extends ConsumerStatefulWidget {
  const _TransactionEditorSheet({this.transaction, required this.defaultUnit});

  final TransactionRecord? transaction;
  final CurrencyUnit defaultUnit;

  @override
  ConsumerState<_TransactionEditorSheet> createState() =>
      _TransactionEditorSheetState();
}

class _TransactionEditorSheetState
    extends ConsumerState<_TransactionEditorSheet> {
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late TransactionType _type;
  late CalendarDate _date;
  late CurrencyUnit _unit;
  late String? _accountId;
  late String? _categoryId;
  Rial? _parsed;
  bool _busy = false;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _type = transaction?.type ?? TransactionType.expense;
    _date = transaction == null
        ? CalendarDate.today()
        : CalendarDate.fromStored(transaction.transactionDate);
    _unit = widget.defaultUnit;
    _parsed = transaction?.amountRial;
    _amount = TextEditingController(
      text: transaction == null
          ? ''
          : _unit == CurrencyUnit.toman
          ? '${transaction.amountRial.value ~/ 10}'
          : '${transaction.amountRial.value}',
    );
    _description = TextEditingController(text: transaction?.description ?? '');
    _accountId = transaction?.accountId;
    _categoryId = transaction?.categoryId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(accountsStreamProvider).value ?? const <AccountWithBalance>[];
    final categories =
        ref.watch(categoriesStreamProvider).value ?? const <Category>[];
    final filtered = categories
        .where(
          (category) =>
              category.type.name ==
              (_type == TransactionType.income ? 'income' : 'expense'),
        )
        .toList();
    if (_accountId == null && accounts.isNotEmpty) {
      _accountId = accounts.first.account.id;
    }
    if (_categoryId == null && filtered.isNotEmpty) {
      _categoryId = filtered.first.id;
    }

    return DaramSheet(
      title: _isEdit ? 'ویرایش تراکنش' : 'ثبت تراکنش',
      subtitle: 'مبلغ به ریال ذخیره می‌شود و با واحد نمایشی تغییر نمی‌کند.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('هزینه'),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('درآمد'),
              ),
            ],
            selected: {_type},
            showSelectedIcon: false,
            onSelectionChanged: (value) => setState(() {
              _type = value.first;
              _categoryId = null;
            }),
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _amount,
            unit: _unit,
            allowZero: false,
            onUnitChanged: (unit) => setState(() {
              _unit = unit;
              _amount.text = _parsed == null
                  ? ''
                  : unit == CurrencyUnit.toman
                  ? '${_parsed!.value ~/ 10}'
                  : '${_parsed!.value}';
            }),
            onChanged: (value) => _parsed = value,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            decoration: const InputDecoration(labelText: 'حساب'),
            items: [
              for (final item in accounts)
                DropdownMenuItem(
                  value: item.account.id,
                  child: Text(item.account.accountName),
                ),
            ],
            onChanged: (value) => setState(() => _accountId = value),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'دسته‌بندی'),
            items: [
              for (final category in filtered)
                DropdownMenuItem(
                  value: category.id,
                  child: Text(category.name),
                ),
            ],
            onChanged: (value) => setState(() => _categoryId = value),
          ),
          const SizedBox(height: 14),
          JalaliDateField(
            value: _date,
            label: 'تاریخ',
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'توضیح (اختیاری)'),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: PrimaryButton(
            label: _isEdit ? 'ذخیره تغییرات' : 'ثبت تراکنش',
            loading: _busy,
            onPressed: _busy ? null : _save,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final amount = _parsed;
    if (amount == null || amount <= Rial.zero) {
      _snack(context, 'مبلغ معتبر وارد کن.');
      return;
    }
    if (_accountId == null) {
      _snack(context, 'حساب را انتخاب کن.');
      return;
    }
    setState(() => _busy = true);
    try {
      final repository = ref.read(transactionRepositoryProvider);
      if (_isEdit) {
        await repository.update(
          id: widget.transaction!.id,
          type: _type,
          amount: amount,
          accountId: _accountId,
          categoryId: _categoryId,
          date: _date,
          description: _description.text.trim(),
        );
      } else {
        await repository.create(
          type: _type,
          amount: amount,
          accountId: _accountId!,
          categoryId: _categoryId,
          date: _date,
          description: _description.text.trim(),
          operationId: const Uuid().v4(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        _snack(context, 'ثبت تراکنش ممکن نشد.');
      }
    }
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
