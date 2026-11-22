import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_inputs.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../records/presentation/record_editor.dart';
import '../domain/obligation.dart';

final _obligationsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(obligationRepositoryProvider).watch(),
);

final _paymentsProvider = StreamProvider.autoDispose.family(
  (ref, String id) => ref.watch(obligationRepositoryProvider).watchPayments(id),
);

class ObligationsSection extends ConsumerStatefulWidget {
  const ObligationsSection({super.key});

  @override
  ConsumerState<ObligationsSection> createState() => _ObligationsSectionState();
}

class _ObligationsSectionState extends ConsumerState<ObligationsSection> {
  bool _showSettled = false;

  @override
  Widget build(BuildContext context) {
    final format = DaramFormat.of(context);
    return ref
        .watch(_obligationsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            icon: LucideIcons.circleAlert,
            title: 'خواندن بدهی‌ها و طلب‌ها انجام نشد.',
            action: TextButton(
              onPressed: () => ref.invalidate(_obligationsProvider),
              child: const Text('تلاش دوباره'),
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return EmptyState(
                icon: LucideIcons.handshake,
                title: 'بدهی یا طلبی ثبت نشده است',
                message:
                    'برای ثبت مبلغی که باید بپردازی یا بگیری، موردی اضافه کن.',
                action: FilledButton.icon(
                  onPressed: () => showObligationEditor(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('افزودن بدهی یا طلب'),
                ),
              );
            }
            final visible = rows
                .where((row) => row.remaining.isZero == _showSettled)
                .toList();
            String total(bool receivable) => formatRecordTotal(
              format,
              rows
                  .where((row) => row.isReceivable == receivable)
                  .map((row) => row.remaining),
            );
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              itemCount: visible.length + 1,
              itemBuilder: (context, index) {
                if (index != 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ObligationCard(row: visible[index - 1]),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DaramCard(
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _Balance(
                                label: 'بدهی باقی‌مانده',
                                value: total(false),
                                color: context.daram.expense,
                              ),
                            ),
                            const VerticalDivider(width: 24),
                            Expanded(
                              child: _Balance(
                                label: 'طلب باقی‌مانده',
                                value: total(true),
                                color: context.daram.income,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('باز'),
                            selected: !_showSettled,
                            onSelected: (_) =>
                                setState(() => _showSettled = false),
                          ),
                          ChoiceChip(
                            label: const Text('تسویه‌شده'),
                            selected: _showSettled,
                            onSelected: (_) =>
                                setState(() => _showSettled = true),
                          ),
                        ],
                      ),
                    ),
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _showSettled
                              ? 'هنوز موردی تسویه نشده است.'
                              : 'همهٔ بدهی‌ها و طلب‌ها تسویه شده‌اند.',
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color),
      ),
    ],
  );
}

class _ObligationCard extends ConsumerWidget {
  const _ObligationCard({required this.row});

  final Obligation row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = DaramFormat.of(context);
    final due = row.dueDate;
    final overdue =
        due != null &&
        !row.remaining.isZero &&
        due.isBefore(CalendarDate.today());
    return DaramCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                row.isReceivable
                    ? LucideIcons.arrowDownLeft
                    : LucideIcons.arrowUpRight,
                color: row.isReceivable
                    ? context.daram.income
                    : context.daram.expense,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.counterparty,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<bool>(
                icon: const Icon(LucideIcons.ellipsis),
                tooltip: 'گزینه‌های ${row.counterparty}',
                onSelected: (edit) {
                  if (edit) {
                    showObligationEditor(context, row: row);
                  } else {
                    final repository = ref.read(obligationRepositoryProvider);
                    confirmRecordDeletion(
                      context,
                      title: 'حذف ${row.isReceivable ? 'طلب' : 'بدهی'}',
                      message: 'این مورد و سابقهٔ پرداخت‌هایش حذف می‌شوند.',
                      delete: () => repository.delete(row.id),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: true, child: Text('ویرایش')),
                  PopupMenuItem(value: false, child: Text('حذف')),
                ],
              ),
            ],
          ),
          Text(
            row.remaining.isZero
                ? 'تسویه‌شده'
                : row.isReceivable
                ? 'ماندهٔ طلب'
                : 'ماندهٔ بدهی',
          ),
          const SizedBox(height: 4),
          AmountText(
            row.remaining,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text('مبلغ اولیه ${format.money.format(row.amount)}'),
          if (due != null)
            Text(
              '${overdue ? 'سررسید گذشته' : 'سررسید'} · ${format.dates.date(due)}',
              style: TextStyle(
                color: overdue
                    ? context.daram.expense
                    : context.daram.textMuted,
              ),
            ),
          if (row.note case final note?)
            Text(note, maxLines: 3, overflow: TextOverflow.ellipsis),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: () => showRecordSheet(
                context,
                (_) => _PaymentHistory(id: row.id, title: row.counterparty),
              ),
              icon: const Icon(LucideIcons.list, size: 18),
              label: const Text('پرداخت‌ها'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showObligationEditor(BuildContext context, {Obligation? row}) =>
    showRecordSheet(context, (_) => _ObligationEditor(row: row));

class _ObligationEditor extends ConsumerStatefulWidget {
  const _ObligationEditor({this.row});

  final Obligation? row;

  @override
  ConsumerState<_ObligationEditor> createState() => _ObligationEditorState();
}

class _ObligationEditorState extends ConsumerState<_ObligationEditor> {
  late final _name = TextEditingController(text: widget.row?.counterparty);
  late final _note = TextEditingController(text: widget.row?.note);
  final _amountText = TextEditingController();
  bool _initialized = false;
  late Rial? _amount = widget.row?.amount;
  late bool _receivable = widget.row?.isReceivable ?? false;
  late CalendarDate? _due = widget.row?.dueDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final format = DaramFormat.of(context);
    if (_initialized) return;
    _initialized = true;
    if (widget.row != null) {
      _amountText.text = format.money.formatPlain(widget.row!.amount);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    _amountText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RecordEditor(
    title: widget.row == null ? 'ثبت بدهی یا طلب' : 'ویرایش بدهی یا طلب',
    onSave: () async {
      final amount = _amount;
      if (amount == null || amount.value <= 0) {
        throw const ValidationException('مبلغ معتبر وارد کنید.');
      }
      await ref
          .read(obligationRepositoryProvider)
          .save(
            id: widget.row?.id,
            counterparty: _name.text,
            isReceivable: _receivable,
            amount: amount,
            dueDate: _due,
            note: _note.text,
          );
    },
    fields: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('بدهی'),
              selected: !_receivable,
              onSelected: (_) => setState(() => _receivable = false),
            ),
            ChoiceChip(
              label: const Text('طلب'),
              selected: _receivable,
              onSelected: (_) => setState(() => _receivable = true),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _name,
          maxLength: 100,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'طرف حساب',
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        AmountField(
          controller: _amountText,
          unit: DaramFormat.of(context).unit,
          onChanged: (amount) => _amount = amount,
        ),
        const SizedBox(height: 12),
        if (_due case final due?)
          Row(
            children: [
              Expanded(
                child: JalaliDateField(
                  label: 'سررسید',
                  value: due,
                  onChanged: (date) {
                    if (mounted) setState(() => _due = date);
                  },
                ),
              ),
              IconButton(
                tooltip: 'برداشتن سررسید',
                onPressed: () => setState(() => _due = null),
                icon: const Icon(LucideIcons.x),
              ),
            ],
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () async {
                final date = await showJalaliDatePicker(context);
                if (date != null && mounted) setState(() => _due = date);
              },
              icon: const Icon(LucideIcons.calendarDays, size: 18),
              label: const Text('افزودن سررسید'),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _note,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'یادداشت (اختیاری)',
            counterText: '',
          ),
        ),
      ],
    ),
  );
}

class _PaymentHistory extends ConsumerWidget {
  const _PaymentHistory({required this.id, required this.title});

  final String id;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = ref
        .watch(_obligationsProvider)
        .value
        ?.where((row) => row.id == id)
        .firstOrNull;
    final format = DaramFormat.of(context);
    final payments = ref.watch(_paymentsProvider(id));
    return DaramSheet(
      title: 'پرداخت‌ها',
      subtitle: title,
      actions: [
        if (row != null && !row.remaining.isZero)
          Expanded(
            child: PrimaryButton(
              label: row.isReceivable ? 'ثبت دریافت' : 'ثبت پرداخت',
              onPressed: () =>
                  showRecordSheet(context, (_) => _PaymentEditor(row: row)),
            ),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (row != null)
            Text(
              row.remaining.isZero
                  ? 'تسویه شده'
                  : 'مانده ${format.money.format(row.remaining)}',
            ),
          const SizedBox(height: 8),
          payments.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => TextButton(
              onPressed: () => ref.invalidate(_paymentsProvider(id)),
              child: const Text('تلاش دوباره برای خواندن پرداخت‌ها'),
            ),
            data: (rows) => rows.isEmpty
                ? const Text('پرداختی ثبت نشده است.')
                : Column(
                    children: [
                      for (final payment in rows)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: AmountText(Rial(payment.amountRial)),
                          subtitle: Text(
                            format.dates.date(
                              CalendarDate.fromStored(payment.paidOn),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 18),
                            tooltip: 'حذف پرداخت',
                            onPressed: () {
                              final repository = ref.read(
                                obligationRepositoryProvider,
                              );
                              confirmRecordDeletion(
                                context,
                                title: 'حذف پرداخت',
                                message: 'مبلغ این پرداخت به مانده برمی‌گردد.',
                                delete: () =>
                                    repository.deletePayment(payment.id),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PaymentEditor extends ConsumerStatefulWidget {
  const _PaymentEditor({required this.row});

  final Obligation row;

  @override
  ConsumerState<_PaymentEditor> createState() => _PaymentEditorState();
}

class _PaymentEditorState extends ConsumerState<_PaymentEditor> {
  final _controller = TextEditingController();
  Rial? _amount;
  CalendarDate _date = CalendarDate.today();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final format = DaramFormat.of(context);
    final label = widget.row.isReceivable ? 'ثبت دریافت' : 'ثبت پرداخت';
    return RecordEditor(
      title: label,
      saveLabel: label,
      onSave: () async {
        final amount = _amount;
        if (amount == null) {
          throw const ValidationException('مبلغ معتبر وارد کنید.');
        }
        await ref
            .read(obligationRepositoryProvider)
            .addPayment(widget.row.id, amount, _date);
      },
      fields: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountField(
            controller: _controller,
            unit: format.unit,
            onChanged: (amount) => _amount = amount,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () {
                _amount = widget.row.remaining;
                _controller.text = format.money.formatPlain(_amount!);
              },
              child: const Text('واردکردن کل مانده'),
            ),
          ),
          JalaliDateField(
            label: 'تاریخ پرداخت',
            value: _date,
            lastDate: CalendarDate.today(),
            onChanged: (date) {
              if (mounted) setState(() => _date = date);
            },
          ),
        ],
      ),
    );
  }
}
