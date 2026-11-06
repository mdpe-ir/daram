import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_inputs.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../accounts/domain/account.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/loan.dart';
import '../domain/loan_calculator.dart';

final loansProvider = StreamProvider.autoDispose<List<Loan>>(
  (ref) => ref.watch(loanRepositoryProvider).watch(),
);

class LoansSection extends ConsumerWidget {
  const LoansSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    return ref
        .watch(loansProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => EmptyState(
            icon: LucideIcons.circleAlert,
            title: 'بارگذاری وام‌ها ممکن نشد',
            action: OutlinedButton(
              onPressed: () => ref.invalidate(loansProvider),
              child: const Text('تلاش دوباره'),
            ),
          ),
          data: (loans) {
            if (loans.isEmpty) {
              return EmptyState(
                icon: LucideIcons.banknote,
                title: 'هنوز وامی ثبت نکردی',
                message: 'وام را اضافه کن تا اقساط، سررسیدها و بدهی باقی‌مانده به‌صورت خودکار محاسبه شود.',
                action: FilledButton.icon(
                  onPressed: () => showLoanEditor(context, ref),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('افزودن وام'),
                ),
              );
            }
            final active = loans
                .where((loan) => loan.status == LoanStatus.active)
                .toList();
            final closed = loans
                .where((loan) => loan.status != LoanStatus.active)
                .toList();
            final outstanding = Rial.sum(
              active.map((loan) => loan.outstandingRial),
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: colors.balanceGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'بدهی باقی‌مانده',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AmountText(
                        outstanding,
                        style: Theme.of(context).textTheme.headlineSmall,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${PersianDigits.toPersian('${active.length}')} وام در جریان',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final loan in active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _LoanCard(loan: loan),
                  ),
                if (closed.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'تسویه‌شده / بایگانی',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  for (final loan in closed)
                    Opacity(
                      opacity: 0.65,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LoanCard(loan: loan),
                      ),
                    ),
                ],
                OutlinedButton.icon(
                  onPressed: () => showLoanEditor(context, ref),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('افزودن وام جدید'),
                ),
              ],
            );
          },
        );
  }
}

class _LoanCard extends ConsumerWidget {
  const _LoanCard({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    return DaramCard(
      onTap: () => showLoanDetails(context, ref, loan),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  LucideIcons.banknote,
                  size: 19,
                  color: colors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '${loan.accountName ?? 'بدون حساب'} · ${PersianDigits.toPersian('${loan.installmentCount}')} قسط',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: loan.status.labelFa,
                color: loan.status == LoanStatus.active
                    ? colors.warning
                    : colors.income,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: loan.progress,
              minHeight: 6,
              backgroundColor: colors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(
                loan.progress >= 1 ? colors.income : colors.warning,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'بدهی باقی‌مانده',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                  AmountText(
                    loan.outstandingRial,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${PersianDigits.toPersian('${loan.paidInstallments}')} از ${PersianDigits.toPersian('${loan.installmentCount}')} قسط',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                  if (loan.nextDueDate != null)
                    Text(
                      'بعدی: ${format.dates.date(CalendarDate.fromStored(loan.nextDueDate!))}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showLoanDetails(
  BuildContext context,
  WidgetRef ref,
  Loan loan,
) async {
  await showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _LoanDetailsSheet(loan: loan),
  );
}

class _LoanDetailsSheet extends ConsumerStatefulWidget {
  const _LoanDetailsSheet({required this.loan});

  final Loan loan;

  @override
  ConsumerState<_LoanDetailsSheet> createState() => _LoanDetailsSheetState();
}

class _LoanDetailsSheetState extends ConsumerState<_LoanDetailsSheet> {
  late Future<List<Installment>> _future = _load();

  Future<List<Installment>> _load() =>
      ref.read(loanRepositoryProvider).installmentsOf(widget.loan.id);

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    final loan = widget.loan;
    return DaramSheet(
      title: loan.title,
      subtitle:
          'اصل ${format.money.format(loan.principalAmountRial)} · ${loan.accountName ?? 'بدون حساب'}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: colors.balanceGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بدهی باقی‌مانده',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 4),
                AmountText(
                  loan.outstandingRial,
                  style: Theme.of(context).textTheme.headlineSmall,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: loan.progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${PersianDigits.toPersian('${loan.paidInstallments}')} از ${PersianDigits.toPersian('${loan.installmentCount}')} قسط پرداخت شده',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.65)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'مبلغ هر قسط',
                  value: format.money.format(loan.installmentAmountRial),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'پرداخت‌شده',
                  value: format.money.format(loan.totalPaidRial),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: 'سود',
                  value: format.money.format(loan.interestAmountRial),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('جدول اقساط', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          FutureBuilder<List<Installment>>(
            future: _future,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <Installment>[];
              if (rows.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                children: [
                  for (final installment in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: installment.isPaid
                              ? colors.income.withValues(alpha: 0.06)
                              : colors.surfaceMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: installment.isPaid
                                ? colors.income.withValues(alpha: 0.2)
                                : colors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: installment.isPaid
                                    ? colors.income.withValues(alpha: 0.15)
                                    : colors.surface,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: installment.isPaid
                                  ? Icon(
                                      LucideIcons.check,
                                      size: 14,
                                      color: colors.income,
                                    )
                                  : Text(
                                      PersianDigits.toPersian(
                                        '${installment.number}',
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    format.dates.date(
                                      CalendarDate.fromStored(
                                        installment.dueDate,
                                      ),
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                  Text(
                                    installment.isPaid
                                        ? 'پرداخت‌شده در ${format.dates.date(CalendarDate.fromStored(installment.paidAt!))}'
                                        : 'سررسید',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: colors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            AmountText(
                              installment.amountRial,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            if (!installment.isPaid) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () async {
                                  final paid = await showInstallmentPaySheet(
                                    context,
                                    ref,
                                    installment: installment,
                                  );
                                  if (paid == true) {
                                    setState(() => _future = _load());
                                    ref.invalidate(loansProvider);
                                  }
                                },
                                icon: Icon(
                                  LucideIcons.checkCircle2,
                                  size: 20,
                                  color: colors.income,
                                ),
                                tooltip: 'ثبت پرداخت',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('بایگانی وام'),
                  content: const Text('این وام از فهرست فعال خارج شود؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('انصراف'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('بایگانی'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(loanRepositoryProvider).archive(loan.id);
                ref.invalidate(loansProvider);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            icon: const Icon(LucideIcons.archive, size: 16),
            label: const Text('بایگانی وام'),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: context.daram.textMuted),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Shared installment payment sheet (used by the dashboard and the loans tab).
Future<bool?> showInstallmentPaySheet(
  BuildContext context,
  WidgetRef ref, {
  required Installment installment,
}) {
  final settings =
      ref.read(settingsControllerProvider).value ??
      const AppSettings.defaults();
  return showModalBottomSheet<bool>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _InstallmentPaySheet(
      installment: installment,
      defaultUnit: settings.currencyUnit,
    ),
  );
}

class _InstallmentPaySheet extends ConsumerStatefulWidget {
  const _InstallmentPaySheet({
    required this.installment,
    required this.defaultUnit,
  });

  final Installment installment;
  final CurrencyUnit defaultUnit;

  @override
  ConsumerState<_InstallmentPaySheet> createState() =>
      _InstallmentPaySheetState();
}

class _InstallmentPaySheetState extends ConsumerState<_InstallmentPaySheet> {
  late final TextEditingController _amount;
  late CurrencyUnit _unit;
  late CalendarDate _date;
  Rial? _parsed;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _unit = widget.defaultUnit;
    _date = CalendarDate.today();
    _parsed = widget.installment.amountRial;
    _amount = TextEditingController(
      text: _unit == CurrencyUnit.toman
          ? '${widget.installment.amountRial.value ~/ 10}'
          : '${widget.installment.amountRial.value}',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DaramSheet(
      title: 'ثبت پرداخت قسط',
      subtitle:
          '${widget.installment.loanTitle ?? ''} — قسط ${PersianDigits.toPersian('${widget.installment.number}')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountField(
            controller: _amount,
            unit: _unit,
            label: 'مبلغ پرداختی',
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
          JalaliDateField(
            value: _date,
            label: 'تاریخ پرداخت',
            onChanged: (value) => setState(() => _date = value),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: PrimaryButton(
            label: 'ثبت پرداخت',
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final amount = _parsed;
    if (amount == null || amount <= Rial.zero) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('مبلغ پرداخت معتبر نیست.')),
        );
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(loanRepositoryProvider)
          .markInstallmentPaid(
            loanId: widget.installment.loanId,
            installmentId: widget.installment.id,
            paymentDate: _date,
            paidAmount: amount,
            operationId: const Uuid().v4(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('ثبت پرداخت ممکن نشد.')));
      }
    }
  }
}

/// Opens the loan creation form.
Future<void> showLoanEditor(BuildContext context, WidgetRef ref) async {
  final settings =
      ref.read(settingsControllerProvider).value ??
      const AppSettings.defaults();
  await showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _LoanEditorSheet(defaultUnit: settings.currencyUnit),
  );
}

class _LoanEditorSheet extends ConsumerStatefulWidget {
  const _LoanEditorSheet({required this.defaultUnit});

  final CurrencyUnit defaultUnit;

  @override
  ConsumerState<_LoanEditorSheet> createState() => _LoanEditorSheetState();
}

class _LoanEditorSheetState extends ConsumerState<_LoanEditorSheet> {
  final _title = TextEditingController();
  final _principal = TextEditingController();
  final _interest = TextEditingController();
  final _count = TextEditingController(text: '3');
  final _description = TextEditingController();
  late CurrencyUnit _unit;
  late CalendarDate _start;
  late CalendarDate _firstDue;
  String? _accountId;
  Rial? _parsedPrincipal;
  Rial? _parsedInterest;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _unit = widget.defaultUnit;
    _start = CalendarDate.today();
    _firstDue = _start.addJalaliMonths(1);
  }

  @override
  void dispose() {
    _title.dispose();
    _principal.dispose();
    _interest.dispose();
    _count.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts =
        ref.watch(accountsStreamProvider).value ?? const <AccountWithBalance>[];
    final count = int.tryParse(PersianDigits.toLatin(_count.text)) ?? 0;
    final installment = count > 0 && _parsedPrincipal != null
        ? LoanCalculator.baseInstallment(
            principal: _parsedPrincipal!,
            interest: _parsedInterest ?? Rial.zero,
            installmentCount: count,
          )
        : Rial.zero;

    return DaramSheet(
      title: 'افزودن وام',
      subtitle: 'پول وام درآمد نیست؛ فقط بدهی و موجودی حساب ثبت می‌شود.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'عنوان وام'),
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _principal,
            unit: _unit,
            label: 'مبلغ اصل وام',
            onUnitChanged: (unit) => setState(() => _unit = unit),
            onChanged: (value) => setState(() => _parsedPrincipal = value),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _count,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'تعداد اقساط'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _interest,
            unit: _unit,
            label: 'سود کل (اختیاری)',
            allowZero: true,
            onChanged: (value) => setState(() => _parsedInterest = value),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.daram.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calculator,
                  size: 16,
                  color: context.daram.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'مبلغ هر قسط: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                AmountText(
                  installment,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String?>(
            initialValue: _accountId,
            decoration: const InputDecoration(
              labelText: 'حساب مرتبط (اختیاری)',
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('بدون حساب'),
              ),
              for (final account in accounts)
                DropdownMenuItem<String?>(
                  value: account.account.id,
                  child: Text(account.account.accountName),
                ),
            ],
            onChanged: (value) => setState(() => _accountId = value),
          ),
          const SizedBox(height: 14),
          JalaliDateField(
            value: _start,
            label: 'تاریخ دریافت وام',
            onChanged: (value) => setState(() {
              _start = value;
              _firstDue = value.addJalaliMonths(1);
            }),
          ),
          const SizedBox(height: 14),
          JalaliDateField(
            value: _firstDue,
            label: 'سررسید اولین قسط',
            onChanged: (value) => setState(() => _firstDue = value),
          ),
          const SizedBox(height: 8),
          Text(
            'اقساط بعدی ماهانه از تاریخ اولین قسط ساخته می‌شوند.',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: context.daram.textMuted),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'توضیح (اختیاری)'),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: PrimaryButton(
            label: 'ثبت وام',
            loading: _busy,
            onPressed: _busy ? null : _save,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final principal = _parsedPrincipal;
    final count = int.tryParse(PersianDigits.toLatin(_count.text));
    if (title.isEmpty) {
      _snack('عنوان وام را وارد کن.');
      return;
    }
    if (principal == null || principal <= Rial.zero) {
      _snack('مبلغ وام معتبر نیست.');
      return;
    }
    if (count == null || count < 1 || count > 360) {
      _snack('تعداد اقساط باید بین ۱ تا ۳۶۰ باشد.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(loanRepositoryProvider)
          .create(
            title: title,
            principal: principal,
            interest: _parsedInterest ?? Rial.zero,
            installmentCount: count,
            accountId: _accountId,
            startDate: _start,
            dueDates: List<CalendarDate>.generate(
              count,
              (index) => _firstDue.addJalaliMonths(index),
            ),
            description: _description.text.trim(),
            operationId: const Uuid().v4(),
          );
      ref.invalidate(loansProvider);
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        _snack('ثبت وام ممکن نشد.');
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
