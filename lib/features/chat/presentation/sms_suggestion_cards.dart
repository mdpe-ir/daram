import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../data/database/app_database.dart';
import '../../settings/domain/app_settings.dart';
import '../../sms/data/sms_review_repository.dart';
import '../../sms/presentation/sms_controller.dart';
import '../domain/drafts.dart';
import 'draft_editor.dart';
import 'sms_chat_focus_controller.dart';

/// The SMS suggestions an assistant message presented.
///
/// Suggestions are rendered as one compact review panel instead of a stack of
/// tall cards. Each row can be replied to, and the header can switch the panel
/// into a multi-select mode for group commands.
class SmsSuggestionCards extends ConsumerWidget {
  const SmsSuggestionCards({super.key, required this.ids});

  final List<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unique = <String>[];
    for (final id in ids) {
      if (!unique.contains(id)) unique.add(id);
    }
    final rows = <SmsSuggestionRow>[];
    for (final id in unique) {
      final row = ref.watch(smsSuggestionProvider(id)).value;
      if (row != null) rows.add(row);
    }
    if (rows.isEmpty) return const SizedBox.shrink();

    final focus = ref.watch(smsChatFocusProvider);
    final openIds = <String>{
      for (final row in rows)
        if (SmsReviewRepository.openStatuses.contains(row.status)) row.id,
    };
    final selecting = focus.selecting && openIds.isNotEmpty;
    final colors = context.daram;
    final controller = ref.read(smsChatFocusProvider.notifier);

    return DaramCard(
      padding: EdgeInsets.zero,
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            count: rows.length,
            selecting: selecting,
            canSelect: openIds.isNotEmpty,
            canSelectAll: openIds.length > 1,
            onSelect: controller.beginSelection,
            onSelectAll: () => controller.selectAll(openIds),
            onCancel: controller.cancelSelection,
          ),
          Divider(height: 1, color: colors.divider),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 12,
                endIndent: 8,
                color: colors.divider,
              ),
            _SuggestionRow(
              row: rows[i],
              selecting: selecting && openIds.contains(rows[i].id),
              selected: focus.selectedIds.contains(rows[i].id),
              onToggle: () => controller.toggle(rows[i].id),
              onReply: () => controller.setReply(rows[i].id),
              onDetails: () => _showDetails(context, rows[i]),
            ),
          ],
          if (selecting) _SelectionHint(count: focus.selectedIds.length),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context, SmsSuggestionRow row) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.daram.surface,
      builder: (_) => SmsSuggestionDetailsSheet(row: row),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.count,
    required this.selecting,
    required this.canSelect,
    required this.canSelectAll,
    required this.onSelect,
    required this.onSelectAll,
    required this.onCancel,
  });

  final int count;
  final bool selecting;
  final bool canSelect;
  final bool canSelectAll;
  final VoidCallback onSelect;
  final VoidCallback onSelectAll;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 6, 4),
      child: Row(
        children: [
          Icon(LucideIcons.messageSquare, size: 15, color: colors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'پیشنهادهای پیامکی',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${PersianDigits.toPersian('$count')} مورد',
            style: text.labelSmall?.copyWith(color: colors.textMuted),
          ),
          if (!selecting && canSelect)
            _HeaderAction(label: 'انتخاب', onTap: onSelect),
          if (selecting) ...[
            if (canSelectAll) _HeaderAction(label: 'همه', onTap: onSelectAll),
            _HeaderAction(label: 'لغو', onTap: onCancel),
          ],
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({
    required this.row,
    required this.selecting,
    required this.selected,
    required this.onToggle,
    required this.onReply,
    required this.onDetails,
  });

  final SmsSuggestionRow row;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onReply;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final text = Theme.of(context).textTheme;
    final format = DaramFormat.of(context);
    final draft = SmsReviewRepository.draftOf(row);
    final isOpen = SmsReviewRepository.openStatuses.contains(row.status);
    final isIncome = draft.type == TransactionType.income;
    final accent = isIncome ? colors.income : colors.expense;
    final title = _titleOf(draft);
    final meta = [
      if (draft.accountName.isNotEmpty) draft.accountName,
      format.dates.relative(draft.date),
    ].join(' · ');
    final status = _rowStatus(context, row.status);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: selecting ? onToggle : onDetails,
        onLongPress: isOpen && !selecting ? onToggle : null,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
          child: Row(
            children: [
              if (selecting)
                _SelectionMark(selected: selected, accent: colors.accent)
              else
                _TypeMark(isIncome: isIncome, accent: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final titleWidget = Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        );
                        final amountWidget = draft.amountRial.isZero
                            ? Text(
                                'مبلغ نامشخص',
                                style: text.labelSmall?.copyWith(
                                  color: colors.warning,
                                ),
                              )
                            : AmountText(
                                draft.amountRial,
                                style: text.titleSmall,
                                color: accent,
                              );
                        // A very large amount (or a narrow screen) should drop
                        // below the title instead of squeezing it to zero width.
                        if (constraints.maxWidth < 220) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              titleWidget,
                              const SizedBox(height: 2),
                              amountWidget,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: titleWidget),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * 0.6,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerEnd,
                                child: amountWidget,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.labelSmall?.copyWith(color: colors.textMuted),
                    ),
                    if (status != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(status.icon, size: 12, color: status.color),
                          const SizedBox(width: 4),
                          Text(
                            status.label,
                            style: text.labelSmall?.copyWith(
                              color: status.color,
                            ),
                          ),
                        ],
                      ),
                    ] else if (row.editedAt != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.pencil,
                            size: 11,
                            color: colors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ویرایش‌شده',
                            style: text.labelSmall?.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (!selecting)
                Tooltip(
                  message: 'پاسخ در چت',
                  child: TextButton.icon(
                    onPressed: isOpen ? onReply : null,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: Icon(
                      LucideIcons.reply,
                      size: 15,
                      color: isOpen ? colors.accent : colors.textMuted,
                    ),
                    label: Text(
                      'پاسخ',
                      style: text.labelSmall?.copyWith(
                        color: isOpen ? colors.accent : colors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  const _SelectionMark({required this.selected, required this.accent});

  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: selected ? accent : colors.border),
      ),
      child: Icon(
        LucideIcons.check,
        size: 16,
        color: selected ? accent : Colors.transparent,
      ),
    );
  }
}

class _TypeMark extends StatelessWidget {
  const _TypeMark({required this.isIncome, required this.accent});

  final bool isIncome;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isIncome ? LucideIcons.arrowDownLeft : LucideIcons.arrowUpRight,
        size: 14,
        color: accent,
      ),
    );
  }
}

class _SelectionHint extends StatelessWidget {
  const _SelectionHint({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.penLine, size: 14, color: colors.accent),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              count == 0
                  ? 'موارد را انتخاب کن؛ سپس پایین در چت دستور بده.'
                  : 'برای ${PersianDigits.toPersian('$count')} مورد انتخاب‌شده در چت دستور بده.',
              style: text.labelSmall?.copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full details and manual actions for one suggestion.
class SmsSuggestionDetailsSheet extends ConsumerStatefulWidget {
  const SmsSuggestionDetailsSheet({super.key, required this.row});

  final SmsSuggestionRow row;

  @override
  ConsumerState<SmsSuggestionDetailsSheet> createState() =>
      _SmsSuggestionDetailsSheetState();
}

class _SmsSuggestionDetailsSheetState
    extends ConsumerState<SmsSuggestionDetailsSheet> {
  bool _busy = false;

  SmsReviewRepository get _repository => ref.read(smsReviewRepositoryProvider);

  @override
  Widget build(BuildContext context) {
    final row =
        ref.watch(smsSuggestionProvider(widget.row.id)).value ?? widget.row;
    final draft = SmsReviewRepository.draftOf(row);
    final colors = context.daram;
    final text = Theme.of(context).textTheme;
    final format = DaramFormat.of(context);
    final accounts = ref.watch(accountsStreamProvider).value ?? const [];
    final categories = ref.watch(categoriesStreamProvider).value ?? const [];
    final ready = SmsReviewRepository.isReady(
      row,
      accountIds: {for (final item in accounts) item.account.id},
      categoryIds: {for (final item in categories) item.id},
    );
    final isOpen = SmsReviewRepository.openStatuses.contains(row.status);
    final isIncome = draft.type == TransactionType.income;
    final accent = isIncome ? colors.income : colors.expense;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, 0, 18, 18 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeMark(isIncome: isIncome, accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleOf(draft), style: text.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'پیشنهاد پیامکی',
                      style: text.labelSmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: row.status),
            ],
          ),
          const SizedBox(height: 12),
          if (draft.amountRial.isZero)
            Text(
              'مبلغ این پیشنهاد مشخص نیست.',
              style: text.bodyMedium?.copyWith(color: colors.warning),
            )
          else
            AmountText(
              draft.amountRial,
              style: text.headlineSmall,
              color: accent,
            ),
          const SizedBox(height: 14),
          _DetailRow(label: 'نوع', value: draft.type.labelFa),
          _DetailRow(
            label: 'حساب',
            value: draft.accountName.isEmpty ? 'نامشخص' : draft.accountName,
          ),
          _DetailRow(
            label: 'دسته‌بندی',
            value: draft.categoryName ?? 'بدون دسته‌بندی',
          ),
          _DetailRow(label: 'تاریخ', value: format.dates.date(draft.date)),
          _DetailRow(label: 'سرشماره', value: isolateLtr(row.sender)),
          _DetailRow(label: 'توضیح', value: draft.description ?? '—'),
          if (row.editedAt != null)
            const _DetailRow(
              label: 'ویرایش',
              value: 'این پیشنهاد دستی یا توسط دستیار ویرایش شده است.',
            ),
          if (row.contextMessageId != null)
            const _DetailRow(
              label: 'تطبیق',
              value: 'با پیامک مرتبط تطبیق داده شد.',
            ),
          if (isOpen && !ready)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colors.warning.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  row.status == 'possibleDuplicate'
                      ? 'شاید این تراکنش قبلاً دستی ثبت شده باشد؛ قبل از تأیید بررسی کن.'
                      : 'برای تأیید، مبلغ و حساب این پیشنهاد را ویرایش کن.',
                  style: text.bodySmall?.copyWith(color: colors.warning),
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (isOpen) ...[
            FilledButton.icon(
              onPressed: _busy ? null : () => _reply(row),
              icon: const Icon(LucideIcons.reply, size: 17),
              label: const Text('پاسخ در چت'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: ready && !_busy ? () => _confirm(row) : null,
                    icon: const Icon(LucideIcons.check, size: 17),
                    label: const Text('تأیید'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _edit(row),
                    icon: const Icon(LucideIcons.pencil, size: 16),
                    label: const Text('ویرایش دستی'),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _busy ? null : () => _dismiss(row),
              icon: const Icon(LucideIcons.x, size: 16),
              label: const Text('رد کردن'),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                row.status == 'confirmed'
                    ? 'این پیشنهاد قبلاً به‌عنوان تراکنش ثبت شده است.'
                    : 'این پیشنهاد رد شده است.',
                style: text.bodySmall?.copyWith(color: colors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  void _reply(SmsSuggestionRow row) {
    ref.read(smsChatFocusProvider.notifier).setReply(row.id);
    Navigator.of(context).pop();
  }

  Future<void> _confirm(SmsSuggestionRow row) async {
    setState(() => _busy = true);
    try {
      await _repository.confirm(row.id);
      ref.read(smsChatFocusProvider.notifier).remove(row.id);
      _showMessage('پیشنهاد پیامکی ثبت شد.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } on Object {
      _showMessage('این پیشنهاد ثبت نشد. دوباره تلاش کن.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(SmsSuggestionRow row) async {
    final settings =
        ref.read(settingsControllerProvider).value ??
        const AppSettings.defaults();
    final payload = await showDraftEditor(
      context,
      draft: SmsReviewRepository.draftOf(row),
      defaultCurrency: settings.currencyUnit,
      saveLabel: 'تأیید و ثبت',
    );
    if (payload == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.confirm(
        row.id,
        edited: TransactionDraft.fromPayload(payload),
      );
      ref.read(smsChatFocusProvider.notifier).remove(row.id);
      _showMessage('پیشنهاد ویرایش و ثبت شد.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } on Object {
      _showMessage('این پیشنهاد ثبت نشد. دوباره تلاش کن.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _dismiss(SmsSuggestionRow row) async {
    final ignorePattern = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رد کردن پیشنهاد'),
        content: const Text(
          'می‌توانی فقط این مورد را رد کنی یا قالب مشابه را هم برای این سرشماره کنار بگذاری.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('بازگشت'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('فقط همین مورد'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('این قالب تراکنش نیست'),
          ),
        ],
      ),
    );
    if (ignorePattern == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _repository.dismiss(row.id, ignorePattern: ignorePattern);
      ref.read(smsChatFocusProvider.notifier).remove(row.id);
      _showMessage('پیشنهاد پیامکی رد شد.');
    } on AppException catch (error) {
      _showMessage(error.message);
    } on Object {
      _showMessage('این پیشنهاد رد نشد. دوباره تلاش کن.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: colors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodySmall?.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final (color, icon, label) = switch (status) {
      'pending' => (colors.warning, LucideIcons.clock, 'در انتظار تأیید'),
      'needsReview' => (
        colors.warning,
        LucideIcons.circleHelp,
        'نیازمند بررسی',
      ),
      'possibleDuplicate' => (colors.warning, LucideIcons.copy, 'شاید تکراری'),
      'confirmed' => (colors.income, LucideIcons.check, 'ثبت شد'),
      'dismissed' => (colors.textMuted, LucideIcons.x, 'رد شد'),
      _ => (colors.textMuted, LucideIcons.info, status),
    };
    return StatusPill(label: label, color: color, icon: icon, compact: true);
  }
}

({Color color, IconData icon, String label})? _rowStatus(
  BuildContext context,
  String status,
) {
  final colors = context.daram;
  return switch (status) {
    'needsReview' => (
      color: colors.warning,
      icon: LucideIcons.circleHelp,
      label: 'نیازمند بررسی',
    ),
    'possibleDuplicate' => (
      color: colors.warning,
      icon: LucideIcons.copy,
      label: 'شاید تکراری',
    ),
    'confirmed' => (
      color: colors.income,
      icon: LucideIcons.check,
      label: 'ثبت شد',
    ),
    'dismissed' => (
      color: colors.textMuted,
      icon: LucideIcons.x,
      label: 'رد شد',
    ),
    _ => null,
  };
}

String _titleOf(TransactionDraft draft) {
  final description = draft.description?.trim();
  if (description != null && description.isNotEmpty) return description;
  return 'تراکنش پیامکی';
}
