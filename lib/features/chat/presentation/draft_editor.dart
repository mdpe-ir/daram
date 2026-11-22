import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
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
import '../../categories/domain/category.dart';
import '../../loans/domain/loan_calculator.dart';
import '../domain/drafts.dart';

/// Opens the draft editor and returns the edited canonical payload.
Future<Map<String, Object?>?> showDraftEditor(
  BuildContext context, {
  required FinancialDraft draft,
  required CurrencyUnit defaultCurrency,
  String saveLabel = 'ذخیره تغییرات',
}) {
  return showModalBottomSheet<Map<String, Object?>>(
    context: context,
    // The chat/records tabs use a nested navigator inside AppShell, whose
    // floating bottom bar draws over the body. Opening on the root navigator
    // keeps the editor and its sticky save action above that bar.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => switch (draft) {
      TransactionDraft() => _TransactionEditor(
        draft: draft,
        unit: defaultCurrency,
        saveLabel: saveLabel,
      ),
      AccountDraft() => _AccountEditor(
        draft: draft,
        unit: defaultCurrency,
        saveLabel: saveLabel,
      ),
      TransferDraft() => _TransferEditor(
        draft: draft,
        unit: defaultCurrency,
        saveLabel: saveLabel,
      ),
      LoanDraft() => _LoanEditor(
        draft: draft,
        unit: defaultCurrency,
        saveLabel: saveLabel,
      ),
      InstallmentPaymentDraft() => _InstallmentEditor(
        draft: draft,
        unit: defaultCurrency,
        saveLabel: saveLabel,
      ),
    },
  );
}

String _rawAmount(Rial amount, CurrencyUnit unit) {
  if (unit == CurrencyUnit.toman) {
    final whole = amount.value ~/ 10;
    final remainder = amount.value % 10;
    return remainder == 0 ? '$whole' : '$whole.$remainder';
  }
  return '${amount.value}';
}

class _BaseEditor extends StatelessWidget {
  const _BaseEditor({
    required this.title,
    required this.child,
    required this.onSave,
    required this.saveLabel,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;
  final String saveLabel;

  @override
  Widget build(BuildContext context) {
    return DaramSheet(
      title: title,
      subtitle: 'مقادیر استخراج‌شده را بررسی و در صورت نیاز اصلاح کن.',
      child: child,
      actions: [
        Expanded(
          child: PrimaryButton(
            label: saveLabel,
            icon: LucideIcons.check,
            onPressed: onSave,
          ),
        ),
      ],
    );
  }
}

class _TransactionEditor extends ConsumerStatefulWidget {
  const _TransactionEditor({
    required this.draft,
    required this.unit,
    required this.saveLabel,
  });

  final TransactionDraft draft;
  final CurrencyUnit unit;
  final String saveLabel;

  @override
  ConsumerState<_TransactionEditor> createState() => _TransactionEditorState();
}

class _TransactionEditorState extends ConsumerState<_TransactionEditor> {
  late TransactionType _type;
  late CalendarDate _date;
  late TextEditingController _amount;
  late TextEditingController _description;
  CurrencyUnit _unit = CurrencyUnit.toman;
  String? _accountId;
  String? _categoryId;
  Rial? _parsedAmount;

  @override
  void initState() {
    super.initState();
    _type = widget.draft.type;
    _date = widget.draft.date;
    _unit = widget.unit;
    _amount = TextEditingController(
      text: _rawAmount(widget.draft.amountRial, _unit),
    );
    _description = TextEditingController(text: widget.draft.description ?? '');
    _accountId = widget.draft.accountId.isEmpty ? null : widget.draft.accountId;
    _categoryId = widget.draft.categoryId;
    _parsedAmount = widget.draft.amountRial;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsStreamProvider).value ?? const [];
    final categoriesAsync = ref.watch(categoriesStreamProvider);
    final categories = categoriesAsync.value ?? const [];
    final filtered = categories
        .where(
          (category) =>
              category.type.name ==
              (_type == TransactionType.income ? 'income' : 'expense'),
        )
        .toList();
    // Do not drop the saved category while the stream is still loading; only
    // clear it once the loaded list proves it no longer exists for this type.
    if (categoriesAsync.hasValue &&
        _categoryId != null &&
        !filtered.any((category) => category.id == _categoryId)) {
      _categoryId = null;
    }

    return _BaseEditor(
      title: widget.draft.title,
      saveLabel: widget.saveLabel,
      onSave: () {
        final amount = _parsedAmount;
        if (amount == null || amount <= Rial.zero) {
          _snack(context, 'مبلغ معتبر وارد کن.');
          return;
        }
        final account = accounts
            .where((item) => item.account.id == _accountId)
            .firstOrNull;
        if (account == null) {
          _snack(context, 'حساب فعال را انتخاب کن.');
          return;
        }
        final draft = widget.draft.copyWith(
          type: _type,
          amountRial: amount,
          accountId: _accountId,
          accountName: account.account.accountName,
          categoryId: _categoryId,
          clearCategory: _categoryId == null,
          categoryName: filtered
              .where((category) => category.id == _categoryId)
              .map((category) => category.name)
              .firstOrNull,
          date: _date,
          description: _description.text.trim(),
        );
        Navigator.of(context).pop(draft.toPayload());
      },
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
            onSelectionChanged: (value) => setState(() => _type = value.first),
          ),
          const SizedBox(height: 16),
          AmountField(
            controller: _amount,
            unit: _unit,
            onUnitChanged: (unit) => setState(() {
              _unit = unit;
              _amount.text = _rawAmount(_parsedAmount ?? Rial.zero, unit);
            }),
            onChanged: (value) => _parsedAmount = value,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: accounts.any((item) => item.account.id == _accountId)
                ? _accountId
                : null,
            isExpanded: true,
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
          _CategoryField(
            categories: filtered,
            selected: filtered
                .where((category) => category.id == _categoryId)
                .firstOrNull,
            type: _type,
            onChanged: (category) => setState(() => _categoryId = category?.id),
          ),
          const SizedBox(height: 14),
          JalaliDateField(
            value: _date,
            label: 'تاریخ تراکنش',
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'توضیح'),
          ),
        ],
      ),
    );
  }
}

class _AccountEditor extends ConsumerStatefulWidget {
  const _AccountEditor({
    required this.draft,
    required this.unit,
    required this.saveLabel,
  });

  final AccountDraft draft;
  final CurrencyUnit unit;
  final String saveLabel;

  @override
  ConsumerState<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<_AccountEditor> {
  late TextEditingController _name;
  late TextEditingController _balance;
  late TextEditingController _card;
  late TextEditingController _description;
  late final TextEditingController _customBankName;
  late String _bankId;
  late AccountType _type;
  CurrencyUnit _unit = CurrencyUnit.toman;
  Rial? _parsedBalance;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft.accountName);
    _balance = TextEditingController(
      text: _rawAmount(widget.draft.initialBalanceRial, widget.unit),
    );
    _card = TextEditingController(text: widget.draft.cardLastFour ?? '');
    _description = TextEditingController(text: widget.draft.description ?? '');
    _bankId = widget.draft.bankId;
    _customBankName = TextEditingController(
      text: _bankId == 'other' ? widget.draft.bankName : '',
    );
    _type = widget.draft.accountType;
    _unit = widget.unit;
    _parsedBalance = widget.draft.initialBalanceRial;
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
    return _BaseEditor(
      title: 'ویرایش حساب',
      saveLabel: widget.saveLabel,
      onSave: () {
        if (_name.text.trim().isEmpty) {
          _snack(context, 'نام حساب را وارد کن.');
          return;
        }
        final customBank = _customBankName.text.trim();
        if (_bankId == 'other' && customBank.isEmpty) {
          _snack(context, 'نام بانک یا نئوبانک را وارد کن.');
          return;
        }
        final bank = bankById(_bankId);
        final draft = widget.draft.copyWith(
          bankId: bank.id,
          bankName: _bankId == 'other' ? customBank : bank.nameFa,
          accountName: _name.text.trim(),
          accountType: _type,
          initialBalanceRial: _parsedBalance ?? Rial.zero,
          cardLastFour: _card.text.trim(),
          description: _description.text.trim(),
        );
        Navigator.of(context).pop(draft.toPayload());
      },
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
            decoration: const InputDecoration(labelText: 'نام حساب'),
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
          AmountField(
            controller: _balance,
            unit: _unit,
            label: 'موجودی اولیه',
            allowZero: true,
            onUnitChanged: (unit) => setState(() {
              _unit = unit;
              _balance.text = _rawAmount(_parsedBalance ?? Rial.zero, unit);
            }),
            onChanged: (value) => _parsedBalance = value,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _card,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              labelText: 'چهار رقم آخر کارت (اختیاری)',
            ),
          ),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'توضیح (اختیاری)'),
          ),
        ],
      ),
    );
  }
}

class _TransferEditor extends ConsumerStatefulWidget {
  const _TransferEditor({
    required this.draft,
    required this.unit,
    required this.saveLabel,
  });

  final TransferDraft draft;
  final CurrencyUnit unit;
  final String saveLabel;

  @override
  ConsumerState<_TransferEditor> createState() => _TransferEditorState();
}

class _TransferEditorState extends ConsumerState<_TransferEditor> {
  late TextEditingController _amount;
  late TextEditingController _fee;
  late TextEditingController _description;
  late CalendarDate _date;
  late String _sourceId;
  late String _destinationId;
  CurrencyUnit _unit = CurrencyUnit.toman;
  Rial? _parsedAmount;
  Rial? _parsedFee;

  @override
  void initState() {
    super.initState();
    _unit = widget.unit;
    _amount = TextEditingController(
      text: _rawAmount(widget.draft.amountRial, _unit),
    );
    _fee = TextEditingController(text: _rawAmount(widget.draft.feeRial, _unit));
    _description = TextEditingController(text: widget.draft.description ?? '');
    _date = widget.draft.date;
    _sourceId = widget.draft.sourceAccountId;
    _destinationId = widget.draft.destinationAccountId;
    _parsedAmount = widget.draft.amountRial;
    _parsedFee = widget.draft.feeRial;
  }

  @override
  void dispose() {
    _amount.dispose();
    _fee.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsStreamProvider).value ?? const [];
    return _BaseEditor(
      title: 'ویرایش انتقال',
      saveLabel: widget.saveLabel,
      onSave: () {
        if (_parsedAmount == null || _parsedAmount! <= Rial.zero) {
          _snack(context, 'مبلغ انتقال معتبر نیست.');
          return;
        }
        if (_sourceId == _destinationId) {
          _snack(context, 'حساب مبدأ و مقصد باید متفاوت باشند.');
          return;
        }
        String nameOf(String id) =>
            accounts
                .where((item) => item.account.id == id)
                .map((item) => item.account.accountName)
                .firstOrNull ??
            '';
        final draft = widget.draft.copyWith(
          sourceAccountId: _sourceId,
          sourceAccountName: nameOf(_sourceId),
          destinationAccountId: _destinationId,
          destinationAccountName: nameOf(_destinationId),
          amountRial: _parsedAmount,
          feeRial: _parsedFee ?? Rial.zero,
          date: _date,
          description: _description.text.trim(),
        );
        Navigator.of(context).pop(draft.toPayload());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountField(
            controller: _amount,
            unit: _unit,
            onUnitChanged: (unit) => setState(() {
              _unit = unit;
              _amount.text = _rawAmount(_parsedAmount ?? Rial.zero, unit);
              _fee.text = _rawAmount(_parsedFee ?? Rial.zero, unit);
            }),
            onChanged: (value) => _parsedAmount = value,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _sourceId,
            decoration: const InputDecoration(labelText: 'از حساب'),
            items: [
              for (final item in accounts)
                DropdownMenuItem(
                  value: item.account.id,
                  child: Text(item.account.accountName),
                ),
            ],
            onChanged: (value) =>
                setState(() => _sourceId = value ?? _sourceId),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _destinationId,
            decoration: const InputDecoration(labelText: 'به حساب'),
            items: [
              for (final item in accounts)
                DropdownMenuItem(
                  value: item.account.id,
                  child: Text(item.account.accountName),
                ),
            ],
            onChanged: (value) =>
                setState(() => _destinationId = value ?? _destinationId),
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _fee,
            unit: _unit,
            label: 'کارمزد (اختیاری)',
            allowZero: true,
            onChanged: (value) => _parsedFee = value,
          ),
          const SizedBox(height: 14),
          JalaliDateField(
            value: _date,
            label: 'تاریخ انتقال',
            onChanged: (value) => setState(() => _date = value),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'توضیح (اختیاری)'),
          ),
        ],
      ),
    );
  }
}

class _LoanEditor extends ConsumerStatefulWidget {
  const _LoanEditor({
    required this.draft,
    required this.unit,
    required this.saveLabel,
  });

  final LoanDraft draft;
  final CurrencyUnit unit;
  final String saveLabel;

  @override
  ConsumerState<_LoanEditor> createState() => _LoanEditorState();
}

class _LoanEditorState extends ConsumerState<_LoanEditor> {
  late TextEditingController _title;
  late TextEditingController _principal;
  late TextEditingController _count;
  late TextEditingController _description;
  late CalendarDate _start;
  late CalendarDate _firstDue;
  late String? _accountId;
  CurrencyUnit _unit = CurrencyUnit.toman;
  Rial? _parsedPrincipal;

  @override
  void initState() {
    super.initState();
    _unit = widget.unit;
    _title = TextEditingController(text: widget.draft.loanTitle);
    _principal = TextEditingController(
      text: _rawAmount(widget.draft.principalRial, _unit),
    );
    _count = TextEditingController(text: '${widget.draft.installmentCount}');
    _description = TextEditingController(text: widget.draft.description ?? '');
    _start = widget.draft.startDate;
    _firstDue = widget.draft.dueDates.isEmpty
        ? _start.addJalaliMonths(1)
        : widget.draft.dueDates.first;
    _accountId = widget.draft.accountId;
    _parsedPrincipal = widget.draft.principalRial;
  }

  @override
  void dispose() {
    _title.dispose();
    _principal.dispose();
    _count.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsStreamProvider).value ?? const [];
    final count =
        int.tryParse(PersianDigits.toLatin(_count.text)) ??
        widget.draft.installmentCount;
    final principal = _parsedPrincipal ?? widget.draft.principalRial;
    final installment = count > 0
        ? LoanCalculator.baseInstallment(
            principal: principal,
            interest: widget.draft.interestRial,
            installmentCount: count,
          )
        : Rial.zero;

    return _BaseEditor(
      title: 'ویرایش وام',
      saveLabel: widget.saveLabel,
      onSave: () {
        final parsedCount = int.tryParse(PersianDigits.toLatin(_count.text));
        if (_title.text.trim().isEmpty) {
          _snack(context, 'عنوان وام را وارد کن.');
          return;
        }
        if (_parsedPrincipal == null || _parsedPrincipal! <= Rial.zero) {
          _snack(context, 'مبلغ وام معتبر نیست.');
          return;
        }
        if (parsedCount == null || parsedCount < 1 || parsedCount > 360) {
          _snack(context, 'تعداد اقساط باید بین ۱ تا ۳۶۰ باشد.');
          return;
        }
        final dueDates = List<CalendarDate>.generate(
          parsedCount,
          (index) => _firstDue.addJalaliMonths(index),
        );
        String? name;
        if (_accountId != null) {
          name = accounts
              .where((item) => item.account.id == _accountId)
              .map((item) => item.account.accountName)
              .firstOrNull;
        }
        final draft = widget.draft.copyWith(
          loanTitle: _title.text.trim(),
          principalRial: _parsedPrincipal,
          installmentCount: parsedCount,
          accountId: _accountId,
          accountName: name,
          startDate: _start,
          dueDates: dueDates,
          description: _description.text.trim(),
        );
        Navigator.of(context).pop(draft.toPayload());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'عنوان وام'),
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _principal,
            unit: _unit,
            label: 'مبلغ اصل وام',
            onUnitChanged: (unit) => setState(() {
              _unit = unit;
              _principal.text = _rawAmount(_parsedPrincipal ?? Rial.zero, unit);
            }),
            onChanged: (value) => setState(() => _parsedPrincipal = value),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _count,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'تعداد اقساط'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.daram.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.calculator,
                  size: 18,
                  color: context.daram.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  'مبلغ هر قسط: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                AmountText(
                  installment,
                  style: Theme.of(context).textTheme.titleSmall,
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
              for (final item in accounts)
                DropdownMenuItem<String?>(
                  value: item.account.id,
                  child: Text(item.account.accountName),
                ),
            ],
            onChanged: (value) => setState(() => _accountId = value),
          ),
          const SizedBox(height: 14),
          JalaliDateField(
            value: _start,
            label: 'تاریخ دریافت وام',
            onChanged: (value) => setState(() => _start = value),
          ),
          const SizedBox(height: 14),
          JalaliDateField(
            value: _firstDue,
            label: 'سررسید اولین قسط',
            onChanged: (value) => setState(() => _firstDue = value),
          ),
          const SizedBox(height: 8),
          Text(
            'تاریخ اقساط بعدی به‌صورت ماهانه از اولین قسط ساخته می‌شود.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: context.daram.textMuted),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(labelText: 'توضیح (اختیاری)'),
          ),
        ],
      ),
    );
  }
}

class _InstallmentEditor extends ConsumerStatefulWidget {
  const _InstallmentEditor({
    required this.draft,
    required this.unit,
    required this.saveLabel,
  });

  final InstallmentPaymentDraft draft;
  final CurrencyUnit unit;
  final String saveLabel;

  @override
  ConsumerState<_InstallmentEditor> createState() => _InstallmentEditorState();
}

class _InstallmentEditorState extends ConsumerState<_InstallmentEditor> {
  late TextEditingController _amount;
  late CalendarDate _date;
  CurrencyUnit _unit = CurrencyUnit.toman;
  Rial? _parsed;

  @override
  void initState() {
    super.initState();
    _unit = widget.unit;
    _amount = TextEditingController(
      text: _rawAmount(widget.draft.paidAmountRial, _unit),
    );
    _date = widget.draft.paymentDate;
    _parsed = widget.draft.paidAmountRial;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BaseEditor(
      title: 'ویرایش پرداخت قسط',
      saveLabel: widget.saveLabel,
      onSave: () {
        final amount = _parsed;
        if (amount == null || amount <= Rial.zero) {
          _snack(context, 'مبلغ پرداخت معتبر نیست.');
          return;
        }
        final draft = widget.draft.copyWith(
          paidAmountRial: amount,
          paymentDate: _date,
        );
        Navigator.of(context).pop(draft.toPayload());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'قسط ${widget.draft.installmentNumber} — ${widget.draft.loanTitle}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 14),
          AmountField(
            controller: _amount,
            unit: _unit,
            label: 'مبلغ پرداختی',
            onUnitChanged: (unit) => setState(() {
              _unit = unit;
              _amount.text = _rawAmount(_parsed ?? Rial.zero, unit);
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
    );
  }
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.categories,
    required this.selected,
    required this.type,
    required this.onChanged,
  });

  final List<Category> categories;
  final Category? selected;
  final TransactionType type;
  final ValueChanged<Category?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await _showCategoryPicker(
          context,
          categories: categories,
          selectedId: selected?.id,
          type: type,
        );
        if (picked == null) return;
        onChanged(picked.category);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'دسته‌بندی',
          suffixIcon: Icon(LucideIcons.chevronDown, size: 18),
        ),
        child: Row(
          children: [
            CategoryAvatar(
              icon: selected?.icon ?? 'tag',
              colorHex: selected?.colorHex ?? '#94A3B8',
              size: 30,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selected?.name ?? 'بدون دسته‌بندی',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected == null ? colors.textMuted : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CategoryPick {
  const _CategoryPick(this.category);

  final Category? category;
}

Future<_CategoryPick?> _showCategoryPicker(
  BuildContext context, {
  required List<Category> categories,
  required String? selectedId,
  required TransactionType type,
}) {
  return showModalBottomSheet<_CategoryPick>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: context.daram.surface,
    builder: (_) => _CategoryPickerSheet(
      categories: categories,
      selectedId: selectedId,
      type: type,
    ),
  );
}

class _CategoryPickerSheet extends StatefulWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
    required this.type,
  });

  final List<Category> categories;
  final String? selectedId;
  final TransactionType type;

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String value) => value
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll('\u200c', ' ')
      .toLowerCase()
      .trim();

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final query = _normalize(_search.text);
    final filtered = widget.categories
        .where((category) => _normalize(category.name).contains(query))
        .toList();
    final typeLabel = widget.type == TransactionType.expense
        ? 'هزینه'
        : 'درآمد';

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: (screenHeight - keyboard) * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 10, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'انتخاب دسته‌بندی',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '$typeLabel · ${PersianDigits.toPersian('${widget.categories.length}')} دسته',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SoftIconButton(
                    icon: LucideIcons.x,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'جست‌وجوی دسته‌بندی…',
                  prefixIcon: const Icon(LucideIcons.search, size: 18),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(LucideIcons.x, size: 16),
                        ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _CategoryTile(
                    name: 'بدون دسته‌بندی',
                    icon: 'tag',
                    colorHex: '#94A3B8',
                    selected: widget.selectedId == null,
                    onTap: () =>
                        Navigator.of(context).pop(const _CategoryPick(null)),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            LucideIcons.searchX,
                            size: 30,
                            color: colors.textMuted,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'دسته‌ای با این نام پیدا نشد.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final category in filtered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CategoryTile(
                          name: category.name,
                          icon: category.icon,
                          colorHex: category.colorHex,
                          selected: category.id == widget.selectedId,
                          onTap: () =>
                              Navigator.of(context)
                                  .pop(_CategoryPick(category)),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String icon;
  final String colorHex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return Material(
      color: selected ? colors.accentSoft : colors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? colors.accent : colors.border),
          ),
          child: Row(
            children: [
              CategoryAvatar(icon: icon, colorHex: colorHex, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (selected)
                Icon(LucideIcons.check, size: 17, color: colors.accent),
            ],
          ),
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
