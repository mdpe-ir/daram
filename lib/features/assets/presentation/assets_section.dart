import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/app_providers.dart';
import '../../../app/design_system/crypto_picker.dart';
import '../../../app/design_system/currency_picker.dart';
import '../../../app/design_system/daram_inputs.dart';
import '../../../app/design_system/daram_widgets.dart';
import '../../../app/theme/daram_colors.dart';
import '../../../core/constants/crypto_assets.dart';
import '../../../core/constants/world_currencies.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/bidi_text.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../../records/presentation/record_editor.dart';
import '../domain/asset_quantity.dart';

final _assetsProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(assetRepositoryProvider).watch(),
);

class AssetsSection extends ConsumerWidget {
  const AssetsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = DaramFormat.of(context);
    return ref
        .watch(_assetsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => EmptyState(
            icon: LucideIcons.circleAlert,
            title: 'خواندن دارایی‌ها انجام نشد.',
            action: TextButton(
              onPressed: () => ref.invalidate(_assetsProvider),
              child: const Text('تلاش دوباره'),
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return EmptyState(
                icon: LucideIcons.gem,
                title: 'دارایی‌ای ثبت نشده است',
                message: 'طلا، نقره، ارز یا رمزارز را با مقدار و نرخ دلخواه اضافه کن.',
                action: FilledButton.icon(
                  onPressed: () => showAssetEditor(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
                  label: const Text('افزودن دارایی'),
                ),
              );
            }
            final valued = rows.where((row) => row.rateRial != null).length;
            final total = formatRecordTotal(
              format,
              rows.map(_value).whereType<Rial>(),
            );
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              itemCount: rows.length + 1,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: index == 0
                    ? DaramCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('ارزش تخمینی دارایی‌های نرخ‌دار'),
                            const SizedBox(height: 4),
                            Text(
                              valued == 0 ? 'هنوز نرخی ثبت نشده است' : total,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (valued > 0 && valued < rows.length)
                              Text(
                                '${_digits(format, '${rows.length - valued}')} دارایی بدون نرخ',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      )
                    : _AssetCard(row: rows[index - 1]),
              ),
            );
          },
        );
  }
}

Rial? _value(AssetHoldingRow row) {
  final rate = row.rateRial;
  return rate == null
      ? null
      : AssetQuantity.fromMicros(row.quantityMicros).valueAt(Rial(rate));
}

String _digits(DaramFormat format, String value) =>
    format.persianDigits ? PersianDigits.toPersian(value) : value;

String _quoteTime(DaramFormat format, DateTime timestamp) {
  final tehran = timestamp.toUtc().add(const Duration(hours: 3, minutes: 30));
  final time =
      '${tehran.hour.toString().padLeft(2, '0')}:${tehran.minute.toString().padLeft(2, '0')}';
  return '${format.dates.date(CalendarDate.fromDateTime(tehran))}، '
      '${isolateLtr(_digits(format, time))} تهران';
}

String _marketLabel(AssetKind kind) => switch (kind) {
  AssetKind.gold => 'نرخ زنده بازار · طلای ۱۸ عیار',
  AssetKind.silver => 'نرخ زنده بازار · نقرهٔ خالص',
  AssetKind.currency || AssetKind.crypto => 'نرخ زنده بازار',
};

/// Small leading mark for a holding: kind icon for bullion, the flag or coin
/// icon otherwise.
class _AssetKindMark extends StatelessWidget {
  const _AssetKindMark({required this.kind, this.code});

  final AssetKind kind;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final colors = context.daram;
    return switch (kind) {
      AssetKind.gold || AssetKind.silver => Icon(
        kind == AssetKind.gold ? LucideIcons.coins : LucideIcons.gem,
        color: colors.accent,
        size: 22,
      ),
      AssetKind.currency => CurrencyBadge(
        currency: currencyOrCode(code ?? ''),
        size: 22,
      ),
      AssetKind.crypto => CryptoBadge(
        coin: cryptoOrSymbol(code ?? ''),
        size: 22,
      ),
    };
  }
}

class _AssetCard extends ConsumerWidget {
  const _AssetCard({required this.row});

  final AssetHoldingRow row;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = DaramFormat.of(context);
    final quantity = AssetQuantity.fromMicros(row.quantityMicros);
    final code = row.currencyCode;
    final value = _value(row);
    final rateDate = row.rateDate;
    return DaramCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AssetKindMark(kind: row.kind, code: code),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  row.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              PopupMenuButton<bool>(
                icon: const Icon(LucideIcons.ellipsis),
                tooltip: 'گزینه‌های ${row.name}',
                onSelected: (edit) {
                  if (edit) {
                    showAssetEditor(context, row: row);
                  } else {
                    final repository = ref.read(assetRepositoryProvider);
                    confirmRecordDeletion(
                      context,
                      title: 'حذف دارایی',
                      message: '«${row.name}» حذف شود؟',
                      delete: () => repository.delete(row.id),
                    );
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: true, child: Text('ویرایش و نرخ')),
                  PopupMenuItem(value: false, child: Text('حذف')),
                ],
              ),
            ],
          ),
          Text(
            '${row.kind.label} · ${isolateLtr(_digits(format, quantity.decimal.replaceAll('.', '٫')))} '
            '${code == null ? 'گرم' : isolateLtr(code)}',
          ),
          const SizedBox(height: 4),
          if (value == null)
            TextButton(
              onPressed: () => showAssetEditor(context, row: row),
              child: const Text('افزودن نرخ'),
            )
          else ...[
            AmountText(value, style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${format.money.format(Rial(row.rateRial!))} '
              'برای هر ${code == null ? 'گرم' : 'واحد'}',
            ),
            if (rateDate != null)
              Text(
                row.isMarketRate
                    ? '${_marketLabel(row.kind)} · ${_quoteTime(format, rateDate)}'
                    : 'نرخ دستی · ${format.dates.date(CalendarDate.fromStored(rateDate))}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}

Future<void> showAssetEditor(BuildContext context, {AssetHoldingRow? row}) =>
    showRecordSheet(context, (_) => _AssetEditor(row: row));

class _AssetEditor extends ConsumerStatefulWidget {
  const _AssetEditor({this.row});

  final AssetHoldingRow? row;

  @override
  ConsumerState<_AssetEditor> createState() => _AssetEditorState();
}

class _AssetEditorState extends ConsumerState<_AssetEditor> {
  late final _name = TextEditingController(text: widget.row?.name);
  late final _quantity = TextEditingController(
    text: widget.row == null
        ? null
        : AssetQuantity.fromMicros(widget.row!.quantityMicros).decimal,
  );
  final _rateText = TextEditingController();

  late AssetKind _kind = widget.row?.kind ?? AssetKind.gold;
  late Rial? _rate = widget.row?.rateRial == null
      ? null
      : Rial(widget.row!.rateRial!);
  late DateTime? _rateDate = widget.row?.rateDate;
  late bool _market = widget.row?.isMarketRate ?? false;
  late String _currencyCode = widget.row?.kind == AssetKind.currency
      ? (widget.row?.currencyCode ?? '').trim().toUpperCase()
      : '';
  late String _cryptoCode = widget.row?.kind == AssetKind.crypto
      ? (widget.row?.currencyCode ?? '').trim().toUpperCase()
      : '';
  bool _initialized = false;
  bool _fetching = false;
  String? _quoteError;
  String? _quoteSource;

  /// The code saved for the current kind: an ISO currency code or a coin
  /// symbol. Both live in the same database column.
  String get _code => switch (_kind) {
    AssetKind.currency => _currencyCode,
    AssetKind.crypto => _cryptoCode,
    _ => '',
  };

  /// True while the name came from a picked currency or coin, so changing the
  /// pick can refresh it without losing a custom name. Rows saved with the
  /// generated name start in that state too.
  late bool _nameAutoFilled =
      widget.row != null &&
      (currencyByCode(widget.row!.currencyCode)?.nameFa == widget.row!.name ||
          cryptoBySymbol(widget.row!.currencyCode)?.nameFa == widget.row!.name);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final format = DaramFormat.of(context);
    if (_initialized) return;
    _initialized = true;
    if (_rate case final rate?) _rateText.text = format.money.formatPlain(rate);
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _rateText.dispose();
    super.dispose();
  }

  void _clearRate() {
    _rate = null;
    _rateDate = null;
    _market = false;
    _quoteError = null;
    _quoteSource = null;
    _rateText.clear();
  }

  /// Prefills the name with [suggestion] while it is empty or still the
  /// previous suggestion; a custom name always wins. `null` means the pick has
  /// no suggested name (a code typed outside the catalog).
  void _applySuggestedName(String? suggestion) {
    if (suggestion == null || suggestion.isEmpty) {
      if (_nameAutoFilled) {
        _name.clear();
        _nameAutoFilled = false;
      }
      return;
    }
    if (_name.text.trim().isEmpty || _nameAutoFilled) {
      _name.text = suggestion;
      _nameAutoFilled = true;
    }
  }

  void _selectCurrency(WorldCurrency currency) {
    if (currency.code == _currencyCode) return;
    setState(() {
      _currencyCode = currency.code;
      _applySuggestedName(
        currency.nameFa == currency.code ? null : currency.nameFa,
      );
      // A quote for the previous holding must not stay attached to this one.
      _clearRate();
    });
  }

  void _selectCrypto(CryptoAsset coin) {
    if (coin.symbol == _cryptoCode) return;
    setState(() {
      _cryptoCode = coin.symbol;
      _applySuggestedName(coin.nameFa == coin.symbol ? null : coin.nameFa);
      _clearRate();
    });
  }

  void _switchKind(AssetKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _clearRate();
      // The name was derived from the previous kind's code, so it should not
      // stay on a gold holding; returning brings the suggested name back.
      if (_nameAutoFilled) {
        _name.clear();
        _nameAutoFilled = false;
      }
      if (_name.text.trim().isEmpty) {
        _applySuggestedName(switch (kind) {
          AssetKind.currency => currencyByCode(_currencyCode)?.nameFa,
          AssetKind.crypto => cryptoBySymbol(_cryptoCode)?.nameFa,
          _ => null,
        });
      }
    });
  }

  /// True when DARAM's own market sources can quote the current holding.
  bool get _canFetch {
    if (_kind == AssetKind.gold || _kind == AssetKind.silver) return true;
    final code = _code.trim();
    if (code.isEmpty) return false;
    return ref.read(marketPriceServiceProvider).supports(_kind, code);
  }

  String get _fetchLabel {
    if (_fetching) return 'در حال دریافت نرخ…';
    return switch (_kind) {
      AssetKind.gold => 'دریافت نرخ طلای ۱۸ عیار از بازار',
      AssetKind.silver => 'دریافت نرخ نقرهٔ خالص از بازار',
      AssetKind.currency => 'دریافت نرخ ارز از بازار',
      AssetKind.crypto =>
        'دریافت نرخ ${cryptoBySymbol(_cryptoCode)?.nameFa ?? _cryptoCode} از بازار',
    };
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    if (_kind.hasCode && _code.trim().isEmpty) {
      setState(
        () => _quoteError = _kind == AssetKind.crypto
            ? 'اول رمزارز را انتخاب کن تا نرخش را بگیرم.'
            : 'اول ارز را انتخاب کن تا نرخش را بگیرم.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _fetching = true;
      _quoteError = null;
    });
    try {
      final quote = await ref
          .read(marketPriceServiceProvider)
          .quoteForAsset(_kind, code: _code);
      if (!mounted) return;
      final format = DaramFormat.of(context);
      setState(() {
        _market = true;
        _rate = quote.rate;
        _rateDate = quote.updatedAt;
        _quoteSource = quote.source;
        _rateText.text = format.money.formatPlain(quote.rate);
      });
    } on AppException catch (error) {
      _quoteError = error.message;
    } on Object {
      _quoteError = 'دریافت نرخ از منابع بازار انجام نشد. دوباره تلاش کن.';
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _save() async {
    if (_kind == AssetKind.currency &&
        !RegExp(r'^[A-Z]{3}$').hasMatch(_currencyCode)) {
      throw const ValidationException('ارز دارایی را از فهرست انتخاب کنید.');
    }
    if (_kind == AssetKind.crypto &&
        !RegExp(r'^[A-Z]{3,10}$').hasMatch(_cryptoCode)) {
      throw const ValidationException('رمزارز دارایی را انتخاب کنید.');
    }
    final amount = AssetQuantity.tryParse(_quantity.text);
    if (amount == null) {
      throw const ValidationException(
        'مقدار مثبت با حداکثر شش رقم اعشار وارد کنید.',
      );
    }
    if (_rateText.text.trim().isNotEmpty &&
        (_rate == null || _rate!.value <= 0)) {
      throw const ValidationException(
        'نرخ معتبر وارد کنید یا فیلد را خالی بگذارید.',
      );
    }
    final rate = _rateText.text.trim().isEmpty ? null : _rate;
    await ref
        .read(assetRepositoryProvider)
        .save(
          id: widget.row?.id,
          name: _name.text,
          kind: _kind,
          currencyCode: _code,
          quantity: amount,
          rate: rate,
          rateDate: rate == null ? null : _rateDate,
          isMarketRate: rate != null && _market,
        );
  }

  @override
  Widget build(BuildContext context) {
    final format = DaramFormat.of(context);
    return RecordEditor(
      title: widget.row == null ? 'ثبت دارایی' : 'ویرایش دارایی',
      onSave: _fetching ? null : _save,
      fields: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final kind in AssetKind.values)
                ChoiceChip(
                  label: Text(kind.label),
                  selected: _kind == kind,
                  onSelected: _fetching ? null : (_) => _switchKind(kind),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            maxLength: 100,
            onChanged: (_) => _nameAutoFilled = false,
            decoration: InputDecoration(
              labelText: 'نام دارایی',
              hintText: switch (_kind) {
                AssetKind.gold || AssetKind.silver => 'مثل طلای پس‌انداز',
                AssetKind.currency => 'مثل پس‌انداز دلاری',
                AssetKind.crypto => 'مثل بیت‌کوین پس‌انداز',
              },
              counterText: '',
            ),
          ),
          if (_kind == AssetKind.currency) ...[
            const SizedBox(height: 12),
            CurrencyPickerField(
              code: _currencyCode,
              enabled: !_fetching,
              onChanged: _selectCurrency,
            ),
          ],
          if (_kind == AssetKind.crypto) ...[
            const SizedBox(height: 12),
            CryptoPickerField(
              symbol: _cryptoCode,
              enabled: !_fetching,
              onChanged: _selectCrypto,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹,٬٫.]')),
              LengthLimitingTextInputFormatter(25),
            ],
            decoration: InputDecoration(
              labelText: switch (_kind) {
                AssetKind.gold || AssetKind.silver => 'وزن به گرم',
                AssetKind.currency => 'تعداد واحد ارز',
                AssetKind.crypto => 'مقدار رمزارز',
              },
            ),
          ),
          const SizedBox(height: 12),
          AbsorbPointer(
            absorbing: _fetching,
            child: AmountField(
              controller: _rateText,
              unit: format.unit,
              label: _kind.hasCode
                  ? 'نرخ هر واحد (اختیاری)'
                  : 'نرخ هر گرم (اختیاری)',
              onChanged: (rate) => setState(() {
                _rate = rate;
                if (_market || _rateDate == null) {
                  _rateDate = CalendarDate.today().stored;
                }
                _market = false;
                _quoteError = null;
              }),
            ),
          ),
          if (_rate != null && !_market) ...[
            const SizedBox(height: 8),
            JalaliDateField(
              value: CalendarDate.fromStored(_rateDate!),
              lastDate: CalendarDate.today(),
              label: 'تاریخ نرخ دستی',
              onChanged: (day) {
                if (mounted) setState(() => _rateDate = day.stored);
              },
            ),
          ],
          if (_market && _rateDate != null)
            Text(
              '${_quoteSource == null ? _marketLabel(_kind) : 'نرخ زنده بازار · $_quoteSource'}'
              ' · ${_quoteTime(format, _rateDate!)}',
            ),
          if (_quoteError case final error?)
            Text(error, style: TextStyle(color: context.daram.expense)),
          const SizedBox(height: 8),
          if (_canFetch)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: _fetching ? null : _fetch,
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: Text(_fetchLabel),
              ),
            )
          else
            Text(
              'نرخ زندهٔ این مورد در منابع بازار در دسترس نیست؛ نرخ را دستی وارد کن.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: context.daram.textMuted),
            ),
        ],
      ),
    );
  }
}
