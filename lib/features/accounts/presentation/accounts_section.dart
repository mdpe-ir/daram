import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_providers.dart';
import '../../sms/data/sms_inbox.dart';
import '../../sms/presentation/sms_sender_picker.dart';
import '../../../app/design_system/bank_picker.dart';
import '../../../app/design_system/daram_inputs.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/constants/iranian_banks.dart';
import '../../../core/domain/enums.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../settings/domain/app_settings.dart';
import '../../transactions/domain/transaction_record.dart';
import '../domain/account.dart';

class AccountsSection extends ConsumerWidget {
  const AccountsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final async = ref.watch(accountsStreamProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => EmptyState(
        icon: LucideIcons.circleAlert,
        title: 'بارگذاری حساب‌ها ممکن نشد',
        action: OutlinedButton(
          onPressed: () => ref.invalidate(accountsStreamProvider),
          child: const Text('تلاش دوباره'),
        ),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return EmptyState(
            icon: LucideIcons.landmark,
            title: 'هنوز حسابی اضافه نکردی',
            message: 'اولین حساب یا کارتت را اضافه کن تا بتوانی هزینه‌ها و درآمدها را روی آن ثبت کنی.',
            action: FilledButton.icon(
              onPressed: () => showAccountEditor(context, ref),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('افزودن حساب'),
            ),
          );
        }
        final active = accounts
            .where((item) => !item.account.isArchived)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
          children: [
            if (active.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${PersianDigits.toPersian('${active.length}')} حساب فعال',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.textMuted),
                ),
              ),
              for (final item in active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AccountCard(item: item),
                ),
            ],
            if (accounts.any((item) => item.account.isArchived)) ...[
              const SizedBox(height: 8),
              Text(
                'بایگانی‌شده',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.textMuted),
              ),
              const SizedBox(height: 8),
              for (final item in accounts.where(
                (item) => item.account.isArchived,
              ))
                Opacity(
                  opacity: 0.6,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AccountCard(item: item),
                  ),
                ),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => showAccountEditor(context, ref),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('افزودن حساب جدید'),
            ),
          ],
        );
      },
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.item});

  final AccountWithBalance item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final account = item.account;
    return DaramCard(
      onTap: () => _showDetails(context, ref),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              BankAvatar(
                bankId: account.bankId,
                bankName: account.bankName,
                size: 46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.accountName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (account.isArchived) ...[
                          const SizedBox(width: 6),
                          StatusPill(
                            label: 'بایگانی',
                            color: colors.textMuted,
                            compact: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${account.bankName} · ${account.accountType.labelFa}${account.cardLastFour == null ? '' : ' · •••• ${account.cardLastFour}'}',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  LucideIcons.ellipsisVertical,
                  size: 18,
                  color: colors.textMuted,
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'edit':
                      await showAccountEditor(context, ref, account: account);
                    case 'archive':
                      final confirmed = await _confirmArchive(context, account);
                      if (confirmed == true) {
                        await ref
                            .read(accountRepositoryProvider)
                            .archive(account.id);
                      }
                    case 'unarchive':
                      await ref
                          .read(accountRepositoryProvider)
                          .unarchive(account.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('ویرایش حساب'),
                  ),
                  if (!account.isArchived)
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('بایگانی حساب'),
                    ),
                  if (account.isArchived)
                    const PopupMenuItem(
                      value: 'unarchive',
                      child: Text('بازگرداندن از بایگانی'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'موجودی فعلی',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: 2),
                  AmountText(
                    item.balance,
                    style: Theme.of(context).textTheme.titleLarge,
                    color: item.balance.isNegative
                        ? colors.expense
                        : colors.textPrimary,
                  ),
                ],
              ),
              const Spacer(),
              Icon(LucideIcons.chevronLeft, size: 16, color: colors.textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmArchive(BuildContext context, Account account) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('بایگانی حساب'),
        content: Text(
          'حساب «${account.accountName}» بایگانی شود؟ تراکنش‌های قبلی حفظ می‌شوند و حساب از فهرست اصلی خارج می‌شود.',
        ),
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
  }

  Future<void> _showDetails(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _AccountDetailsSheet(accountId: item.account.id),
    );
  }
}

class _AccountDetailsSheet extends ConsumerWidget {
  const _AccountDetailsSheet({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.daram;
    final accounts =
        ref.watch(accountsStreamProvider).value ?? const <AccountWithBalance>[];
    final account = accounts
        .where((item) => item.account.id == accountId)
        .firstOrNull;
    if (account == null) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('حساب پیدا نشد.')),
      );
    }
    final format = DaramFormatScope.of(context);
    return DaramSheet(
      title: account.account.accountName,
      subtitle: account.account.bankName,
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
                  'موجودی فعلی',
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 4),
                AmountText(
                  account.balance,
                  style: Theme.of(context).textTheme.headlineSmall,
                  color: Colors.white,
                ),
                if (account.account.cardLastFour != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    'کارت •••• ${account.account.cardLastFour}',
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.65)),
                  ),
                ],
              ],
            ),
          ),
          if (SmsInbox.supported && !account.account.isArchived)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(LucideIcons.messageSquare),
              title: const Text('انتخاب سرشماره‌ها'),
              trailing: const Icon(LucideIcons.chevronLeft),
              onTap: () => showSmsSenderPicker(context, account.account),
            ),
          const SizedBox(height: 16),
          Text(
            'آخرین تراکنش‌ها',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<TransactionRecord>>(
            stream: ref
                .read(transactionRepositoryProvider)
                .watch(TransactionFilter(accountId: accountId, limit: 8)),
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <TransactionRecord>[];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'تراکنشی برای این حساب ثبت نشده است.',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.textMuted),
                  ),
                );
              }
              return Column(
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          CategoryAvatar(
                            icon: row.categoryIcon ?? 'circle-ellipsis',
                            colorHex: row.categoryColorHex ?? '#94A3B8',
                            size: 34,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  row.description?.isNotEmpty == true
                                      ? row.description!
                                      : (row.categoryName ?? 'تراکنش'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  format.dates.relative(
                                    CalendarDate.fromStored(
                                      row.transactionDate,
                                    ),
                                  ),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: colors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          AmountText(
                            row.amountRial,
                            signed: true,
                            showSymbol: false,
                            color: row.isIncome
                                ? colors.income
                                : colors.expense,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
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
              Navigator.of(context).pop();
              await showAccountEditor(context, ref, account: account.account);
            },
            icon: const Icon(LucideIcons.pencil, size: 16),
            label: const Text('ویرایش حساب'),
          ),
        ),
      ],
    );
  }
}

/// Opens the account editor for create or edit.
Future<void> showAccountEditor(
  BuildContext context,
  WidgetRef ref, {
  Account? account,
}) async {
  final settings =
      ref.read(settingsControllerProvider).value ??
      const AppSettings.defaults();
  await showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _AccountEditorSheet(
      account: account,
      defaultUnit: settings.currencyUnit,
    ),
  );
}

class _AccountEditorSheet extends ConsumerStatefulWidget {
  const _AccountEditorSheet({this.account, required this.defaultUnit});

  final Account? account;
  final CurrencyUnit defaultUnit;

  @override
  ConsumerState<_AccountEditorSheet> createState() =>
      _AccountEditorSheetState();
}

class _AccountEditorSheetState extends ConsumerState<_AccountEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _balance;
  late final TextEditingController _card;
  late final TextEditingController _description;
  late final TextEditingController _customBankName;
  late String _bankId;
  late AccountType _type;
  late CurrencyUnit _unit;
  Rial? _parsedBalance;
  bool _busy = false;

  bool get _isEdit => widget.account != null;

  @override
  void initState() {
    super.initState();
    final account = widget.account;
    _name = TextEditingController(text: account?.accountName ?? '');
    _balance = TextEditingController(
      text: account == null
          ? ''
          : widget.defaultUnit == CurrencyUnit.toman
          ? '${account.initialBalanceRial.value ~/ 10}'
          : '${account.initialBalanceRial.value}',
    );
    _card = TextEditingController(text: account?.cardLastFour ?? '');
    _description = TextEditingController(text: account?.description ?? '');
    _bankId = account?.bankId ?? 'mellat';
    _customBankName = TextEditingController(
      text: _bankId == 'other' ? account?.bankName ?? '' : '',
    );
    _type = account?.accountType ?? AccountType.bank;
    _unit = widget.defaultUnit;
    _parsedBalance = account?.initialBalanceRial ?? Rial.zero;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _card.dispose();
    _description.dispose();
    _customBankName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DaramSheet(
      title: _isEdit ? 'ویرایش حساب' : 'افزودن حساب',
      subtitle: _isEdit
          ? 'سال اول ثبت شده است.'
          : 'موجودی اولیه، نقطه شروع محاسبه موجودی است.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BankPickerField(
            bankId: _bankId,
            onChanged: (bank) => setState(() => _bankId = bank.id),
          ),
          if (_bankId == 'other') ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _customBankName,
              decoration: const InputDecoration(
                labelText: 'نام بانک یا نئوبانک',
                hintText: 'مثلاً بانک آینده یا یک نئوبانک جدید',
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'نام حساب',
              hintText: 'مثلاً حساب حقوق',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<AccountType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'نوع حساب'),
            items: [
              for (final item in AccountType.values)
                DropdownMenuItem(value: item, child: Text(item.labelFa)),
            ],
            onChanged: (value) => setState(() => _type = value ?? _type),
          ),
          const SizedBox(height: 14),
          if (!_isEdit)
            AmountField(
              controller: _balance,
              unit: _unit,
              label: 'موجودی اولیه',
              allowZero: true,
              onUnitChanged: (unit) => setState(() {
                _unit = unit;
                _balance.text = _parsedBalance == null || _parsedBalance!.isZero
                    ? ''
                    : unit == CurrencyUnit.toman
                    ? '${_parsedBalance!.value ~/ 10}'
                    : '${_parsedBalance!.value}';
              }),
              onChanged: (value) => _parsedBalance = value,
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.daram.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.info,
                    size: 15,
                    color: context.daram.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'موجودی اولیه پس از ثبت قابل تغییر نیست؛ برای اصلاح از تراکنش استفاده کن.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.daram.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _card,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'چهار رقم آخر کارت (اختیاری)',
              counterText: '',
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'توضیح (اختیاری)'),
          ),
        ],
      ),
      actions: [
        Expanded(
          child: PrimaryButton(
            label: _isEdit ? 'ذخیره تغییرات' : 'افزودن حساب',
            loading: _busy,
            onPressed: _busy ? null : _save,
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack(context, 'نام حساب را وارد کن.');
      return;
    }
    final card = _card.text.trim();
    if (card.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(card)) {
      _snack(context, 'چهار رقم آخر کارت باید چهار رقم باشد.');
      return;
    }
    setState(() => _busy = true);
    try {
      final repository = ref.read(accountRepositoryProvider);
      final customBank = _customBankName.text.trim();
      if (_bankId == 'other' && customBank.isEmpty) {
        if (mounted) setState(() => _busy = false);
        _snack(context, 'نام بانک یا نئوبانک را وارد کن.');
        return;
      }
      final selectedBank = bankById(_bankId);
      final selectedBankName = _bankId == 'other'
          ? customBank
          : selectedBank.nameFa;
      if (_isEdit) {
        await repository.update(
          id: widget.account!.id,
          bankId: selectedBank.id,
          bankName: selectedBankName,
          accountName: name,
          accountType: _type,
          cardLastFour: card,
          description: _description.text.trim(),
        );
      } else {
        await repository.create(
          bankId: selectedBank.id,
          bankName: selectedBankName,
          accountName: name,
          accountType: _type,
          initialBalance: _parsedBalance ?? Rial.zero,
          cardLastFour: card,
          description: _description.text.trim(),
          operationId: const Uuid().v4(),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() => _busy = false);
        _snack(context, 'ثبت حساب ممکن نشد.');
      }
    }
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
