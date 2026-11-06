import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/formatting/persian_formatting.dart';
import '../../core/money/currency.dart';
import '../../core/money/rial.dart';
import '../../core/time/calendar_date.dart';
import '../theme/daram_colors.dart';
import 'daram_widgets.dart';

const _persianWeekdaysShort = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

/// A numeric input that accepts Persian/Arabic/Latin digits and returns Rial.
class AmountField extends StatefulWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.unit,
    this.onChanged,
    this.onUnitChanged,
    this.label = 'مبلغ',
    this.allowZero = false,
    this.autofocus = false,
    this.validator,
  });

  final TextEditingController controller;
  final CurrencyUnit unit;
  final ValueChanged<Rial?>? onChanged;
  final ValueChanged<CurrencyUnit>? onUnitChanged;
  final String label;
  final bool allowZero;
  final bool autofocus;
  final String? Function(Rial?)? validator;

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  String? _error;

  Rial? _parse(String raw) {
    final normalized = PersianDigits.toLatin(raw)
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll(' ', '')
        .trim();
    if (normalized.isEmpty) return null;
    try {
      if (widget.unit == CurrencyUnit.toman) {
        if (normalized.contains('.')) return Rial.fromTomanExact(normalized);
        final toman = int.tryParse(normalized);
        if (toman == null) return null;
        return Rial.fromToman(toman);
      }
      if (normalized.contains('.')) return null;
      final rial = int.tryParse(normalized);
      if (rial == null) return null;
      return Rial(rial);
    } on MoneyException {
      return null;
    }
  }

  void _notify() {
    final parsed = _parse(widget.controller.text);
    final validation = widget.validator?.call(parsed);
    setState(() => _error = validation);
    widget.onChanged?.call(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final parsed = _parse(widget.controller.text);
    final formatter = MoneyFormatter(
      unit: CurrencyUnit.rial,
      usePersianDigits: false,
    );
    final helper = parsed == null
        ? 'مبلغ را با ارقام فارسی یا انگلیسی وارد کنید.'
        : widget.unit == CurrencyUnit.toman
        ? 'معادل ${formatter.format(parsed)}'
        : 'معادل ${MoneyFormatter(unit: CurrencyUnit.toman, usePersianDigits: false).format(parsed)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                autofocus: widget.autofocus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹,٬٫.]')),
                  LengthLimitingTextInputFormatter(18),
                ],
                onChanged: (_) => _notify(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: '۰',
                  helperText: _error ?? helper,
                  helperStyle: TextStyle(
                    color: _error == null ? colors.textMuted : colors.expense,
                  ),
                  suffixText: widget.unit.label,
                ),
              ),
            ),
          ],
        ),
        if (widget.onUnitChanged != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              for (final unit in CurrencyUnit.values)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(unit.label),
                    selected: widget.unit == unit,
                    onSelected: (_) => widget.onUnitChanged!(unit),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Tappable Jalali date field with a built-in picker.
class JalaliDateField extends StatelessWidget {
  const JalaliDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'تاریخ',
    this.firstDate,
    this.lastDate,
  });

  final CalendarDate value;
  final ValueChanged<CalendarDate> onChanged;
  final String label;
  final CalendarDate? firstDate;
  final CalendarDate? lastDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final format = DaramFormatScope.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showJalaliDatePicker(
          context,
          initial: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(LucideIcons.calendarDays, size: 18),
        ),
        child: Text(
          format.dates.dateWithWeekday(value),
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: colors.textPrimary),
        ),
      ),
    );
  }
}

/// Opens a Jalali calendar picker and returns the chosen date.
Future<CalendarDate?> showJalaliDatePicker(
  BuildContext context, {
  CalendarDate? initial,
  CalendarDate? firstDate,
  CalendarDate? lastDate,
}) {
  return showDialog<CalendarDate>(
    context: context,
    builder: (context) => _JalaliPickerDialog(
      initial: initial ?? CalendarDate.today(),
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _JalaliPickerDialog extends StatefulWidget {
  const _JalaliPickerDialog({
    required this.initial,
    this.firstDate,
    this.lastDate,
  });

  final CalendarDate initial;
  final CalendarDate? firstDate;
  final CalendarDate? lastDate;

  @override
  State<_JalaliPickerDialog> createState() => _JalaliPickerDialogState();
}

class _JalaliPickerDialogState extends State<_JalaliPickerDialog> {
  late CalendarDate _selected;
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    final jalali = _selected.jalali;
    _year = jalali.year;
    _month = jalali.month;
  }

  void _shiftMonth(int delta) {
    setState(() {
      final date = CalendarDate.fromJalali(
        _year,
        _month,
        1,
      ).addJalaliMonths(delta);
      _year = date.jalali.year;
      _month = date.jalali.month;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    final firstOfMonth = CalendarDate.fromJalali(_year, _month, 1);
    final daysInMonth = firstOfMonth.endOfJalaliMonth.jalali.day;
    final leading = (firstOfMonth.isoWeekday + 1) % 7;
    final today = CalendarDate.today();
    final format = DaramFormatScope.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _shiftMonth(1),
                  icon: const Icon(LucideIcons.chevronRight, size: 20),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${jalaliMonthName(_month)} $_year',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'تقویم شمسی',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _shiftMonth(-1),
                  icon: const Icon(LucideIcons.chevronLeft, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final day in _persianWeekdaysShort)
                  Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leading + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisExtent: 44,
              ),
              itemBuilder: (context, index) {
                if (index < leading) return const SizedBox.shrink();
                final day = index - leading + 1;
                final date = CalendarDate.fromJalali(_year, _month, day);
                final disabled =
                    (widget.firstDate != null &&
                        date.isBefore(widget.firstDate!)) ||
                    (widget.lastDate != null && date.isAfter(widget.lastDate!));
                final selected = date == _selected;
                final isToday = date == today;
                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: disabled
                        ? null
                        : () => setState(() {
                            _selected = date;
                          }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected ? colors.accent : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isToday && !selected
                            ? Border.all(
                                color: colors.accent.withValues(alpha: 0.5),
                              )
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        PersianDigits.toPersian('$day'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: disabled
                              ? colors.textMuted.withValues(alpha: 0.4)
                              : selected
                              ? colors.onAccent
                              : colors.textPrimary,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _selected = today;
                    _year = today.jalali.year;
                    _month = today.jalali.month;
                  }),
                  child: const Text('امروز'),
                ),
                const Spacer(),
                Text(
                  format.dates.date(_selected),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.textMuted),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  child: const Text('انتخاب'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String jalaliMonthName(int month) {
  const names = [
    'فروردین',
    'اردیبهشت',
    'خرداد',
    'تیر',
    'مرداد',
    'شهریور',
    'مهر',
    'آبان',
    'آذر',
    'دی',
    'بهمن',
    'اسفند',
  ];
  return names[(month - 1).clamp(0, 11)];
}
