import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/domain/enums.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';
import '../../settings/domain/app_settings.dart';
import '../domain/chat_models.dart';
import '../domain/drafts.dart';
import 'chat_controller.dart';
import 'draft_editor.dart';

/// In-chat confirmation card for one financial draft.
class PendingActionCard extends ConsumerStatefulWidget {
  const PendingActionCard({super.key, required this.action});

  final PendingAction action;

  @override
  ConsumerState<PendingActionCard> createState() => _PendingActionCardState();
}

class _PendingActionCardState extends ConsumerState<PendingActionCard> {
  bool _busy = false;

  FinancialDraft? get _draft => FinancialDraft.fromPendingAction(widget.action);

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final draft = _draft;
    if (draft == null) {
      return const SizedBox.shrink();
    }
    final status = widget.action.status;
    final isPending = status == PendingActionStatus.pending;
    final accent = switch (draft) {
      TransactionDraft(:final type) =>
        type == TransactionType.income ? colors.income : colors.expense,
      TransferDraft() => colors.transfer,
      AccountDraft() => colors.accent,
      LoanDraft() => colors.warning,
      InstallmentPaymentDraft() => colors.income,
    };
    final icon = switch (draft) {
      TransactionDraft(:final type) =>
        type == TransactionType.income
            ? LucideIcons.arrowDownLeft
            : LucideIcons.arrowUpRight,
      TransferDraft() => LucideIcons.arrowLeftRight,
      AccountDraft() => LucideIcons.landmark,
      LoanDraft() => LucideIcons.banknote,
      InstallmentPaymentDraft() => LucideIcons.calendarCheck,
    };

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending ? accent.withValues(alpha: 0.35) : colors.border,
        ),
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
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 17, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'پیش‌نویس مالی',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(height: 1, color: colors.divider),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: _DraftDetails(draft: draft),
          ),
          if (draft.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final note in draft.notes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.info,
                            size: 13,
                            color: colors.warning,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              note,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          if (widget.action.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.expense.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.expense.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.circleAlert,
                      size: 14,
                      color: colors.expense,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.action.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.expense),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _ConfirmButton(busy: _busy, onTap: _confirm),
                  ),
                  const SizedBox(width: 8),
                  _SmallAction(
                    icon: LucideIcons.pencil,
                    label: 'ویرایش',
                    onTap: _busy ? null : _edit,
                  ),
                  const SizedBox(width: 4),
                  _SmallAction(
                    icon: LucideIcons.x,
                    label: 'رد',
                    onTap: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            try {
                              await ref
                                  .read(chatControllerProvider.notifier)
                                  .rejectAction(widget.action.id);
                            } finally {
                              if (mounted) setState(() => _busy = false);
                            }
                          },
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 10),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(chatControllerProvider.notifier)
          .confirmAction(widget.action.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('با موفقیت ثبت شد.')));
    } on Object {
      // The controller stores a Persian message; the card shows the new error.
      if (mounted) setState(() => _busy = false);
    } finally {
      if (mounted && _busy) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    final draft = _draft;
    if (draft == null) return;
    final settings =
        ref.read(settingsControllerProvider).value ??
        const AppSettings.defaults();
    final payload = await showDraftEditor(
      context,
      draft: draft,
      defaultCurrency: settings.currencyUnit,
    );
    if (payload == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(chatControllerProvider.notifier)
          .updateDraft(widget.action.id, payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تغییرات ذخیره شد؛ حالا تأیید کن.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DraftDetails extends StatelessWidget {
  const _DraftDetails({required this.draft});

  final FinancialDraft draft;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    final rows = <(String, Widget)>[];

    switch (draft) {
      case final TransactionDraft d:
        rows
          ..add((
            'مبلغ',
            _strong(
              context,
              d.amountRial,
              d.type == TransactionType.income ? colors.income : colors.expense,
            ),
          ))
          ..add(('حساب', _text(context, d.accountName)))
          ..add((
            'دسته‌بندی',
            _text(context, d.categoryName ?? 'بدون دسته‌بندی'),
          ))
          ..add(('تاریخ', _text(context, format.dates.date(d.date))))
          ..add(('توضیح', _text(context, d.description ?? '—')));
      case final TransferDraft d:
        rows
          ..add(('مبلغ', _strong(context, d.amountRial, colors.transfer)))
          ..add(('از', _text(context, d.sourceAccountName)))
          ..add(('به', _text(context, d.destinationAccountName)))
          ..add(('کارمزد', _text(context, format.money.format(d.feeRial))))
          ..add(('تاریخ', _text(context, format.dates.date(d.date))));
      case final AccountDraft d:
        rows
          ..add(('بانک', _text(context, d.bankName)))
          ..add(('نوع', _text(context, d.accountType.labelFa)))
          ..add((
            'موجودی اولیه',
            _strong(context, d.initialBalanceRial, colors.accent),
          ))
          ..add(('چهار رقم آخر', _text(context, d.cardLastFour ?? '—')));
      case final LoanDraft d:
        final installment =
            d.installmentAmountRial ??
            (d.installmentCount == 0
                ? Rial.zero
                : Rial(
                    (d.principalRial.value + d.interestRial.value) ~/
                        d.installmentCount,
                  ));
        rows
          ..add(('اصل وام', _strong(context, d.principalRial, colors.warning)))
          ..add((
            'تعداد اقساط',
            _text(context, PersianDigits.toPersian('${d.installmentCount}')),
          ))
          ..add(('هر قسط', _text(context, format.money.format(installment))))
          ..add(('حساب', _text(context, d.accountName ?? 'بدون حساب')))
          ..add((
            'اولین سررسید',
            _text(
              context,
              d.dueDates.isEmpty ? '—' : format.dates.date(d.dueDates.first),
            ),
          ));
      case final InstallmentPaymentDraft d:
        rows
          ..add(('وام', _text(context, d.loanTitle)))
          ..add((
            'شماره قسط',
            _text(context, PersianDigits.toPersian('${d.installmentNumber}')),
          ))
          ..add((
            'مبلغ پرداختی',
            _strong(context, d.paidAmountRial, colors.income),
          ))
          ..add((
            'تاریخ پرداخت',
            _text(context, format.dates.date(d.paymentDate)),
          ));
    }

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    row.$1,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: row.$2,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _text(BuildContext context, String value) => Text(
    value,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.daram.textPrimary),
    textAlign: TextAlign.start,
  );

  Widget _strong(BuildContext context, Rial amount, Color color) => AmountText(
    amount,
    style: Theme.of(context).textTheme.titleSmall,
    color: color,
  );
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return SizedBox(
      height: 42,
      child: FilledButton(
        onPressed: busy ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.onAccent,
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.check, size: 15),
                  SizedBox(width: 6),
                  Text('تأیید و ثبت'),
                ],
              ),
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: colors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 42),
      ),
      icon: Icon(icon, size: 14),
      label: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PendingActionStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final (color, icon) = switch (status) {
      PendingActionStatus.pending => (colors.warning, LucideIcons.clock),
      PendingActionStatus.confirmed => (colors.income, LucideIcons.check),
      PendingActionStatus.rejected => (colors.textMuted, LucideIcons.x),
      PendingActionStatus.failed => (colors.expense, LucideIcons.circleAlert),
    };
    return StatusPill(
      label: status.labelFa,
      color: color,
      icon: icon,
      compact: true,
    );
  }
}
