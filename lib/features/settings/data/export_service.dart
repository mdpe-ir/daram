import 'dart:convert';

import 'package:arabic_reshaper/arabic_reshaper.dart';
import 'package:bidi/bidi.dart' as bidi;
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/currency.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/jalali_text.dart';
import '../../../data/database/app_database.dart';
import '../../assets/domain/asset_quantity.dart';
import '../../dashboard/data/analytics_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_record.dart';

/// Shapes Persian text for the PDF renderer, which does not run a full
/// OpenType shaper itself.
String shapePersian(String text) {
  if (text.isEmpty) return text;
  return String.fromCharCodes(
    bidi.logicalToVisual(ArabicReshaper.instance.reshape(text)),
  );
}

/// A PDF text run whose glyphs are already in visual order.
///
/// [shapePersian] applies bidi's logical-to-visual conversion, so the PDF
/// renderer must draw it left-to-right. Setting RTL here would reverse the
/// shaped string a second time and produce mirrored words (the old bug).
pw.Text pdfRtlText(
  String text, {
  double size = 10,
  bool isBold = false,
  PdfColor? color,
  pw.TextAlign align = pw.TextAlign.right,
}) {
  return pw.Text(
    shapePersian(text),
    textDirection: pw.TextDirection.ltr,
    textAlign: align,
    style: pw.TextStyle(
      fontSize: size,
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? PdfColors.grey900,
    ),
  );
}

/// Summary returned after a backup restore.
class BackupSummary {
  const BackupSummary({required this.exportedAt, required this.rowCounts});

  final DateTime? exportedAt;
  final Map<String, int> rowCounts;
}

/// CSV, PDF and full local backup export/import.
class ExportService {
  ExportService({
    required AppDatabase db,
    required TransactionRepository transactions,
    required AnalyticsRepository analytics,
  }) : _db = db,
       _transactions = transactions,
       _analytics = analytics;

  final AppDatabase _db;
  final TransactionRepository _transactions;
  final AnalyticsRepository _analytics;

  static const String backupFormat = 'daram-backup';
  static const int backupVersion = 1;

  static const List<String> tableOrder = <String>[
    'accounts',
    'categories',
    'transactions',
    'transfers',
    'ledger_entries',
    'loans',
    'installments',
    'chat_sessions',
    'chat_messages',
    'pending_actions',
    'financial_operations',
    ..._optionalBackupTables,
  ];

  static const _optionalBackupTables = [
    'sms_sender_links',
    'sms_suggestions',
    'sms_patterns',
    'sms_sender_dismissals',
    'obligations',
    'obligation_payments',
    'asset_holdings',
  ];

  static const Map<String, Set<String>> _allowedColumns = <String, Set<String>>{
    'accounts': {
      'id',
      'bank_id',
      'bank_name',
      'account_name',
      'account_type',
      'initial_balance_rial',
      'card_last_four',
      'description',
      'created_at',
      'archived_at',
    },
    'categories': {
      'id',
      'name',
      'type',
      'icon',
      'color_hex',
      'is_default',
      'sort_order',
      'created_at',
    },
    'transactions': {
      'id',
      'type',
      'amount_rial',
      'category_id',
      'account_id',
      'transaction_date',
      'description',
      'operation_id',
      'created_at',
      'updated_at',
    },
    'transfers': {
      'id',
      'source_account_id',
      'destination_account_id',
      'amount_rial',
      'fee_rial',
      'transfer_date',
      'description',
      'operation_id',
      'created_at',
    },
    'ledger_entries': {
      'id',
      'account_id',
      'delta_rial',
      'entry_date',
      'source_type',
      'source_id',
      'operation_id',
      'created_at',
    },
    'loans': {
      'id',
      'title',
      'principal_amount_rial',
      'interest_amount_rial',
      'installment_count',
      'installment_amount_rial',
      'account_id',
      'start_date',
      'status',
      'description',
      'operation_id',
      'created_at',
    },
    'installments': {
      'id',
      'loan_id',
      'installment_number',
      'due_date',
      'amount_rial',
      'principal_rial',
      'interest_rial',
      'status',
      'paid_amount_rial',
      'paid_at',
      'created_at',
    },
    'chat_sessions': {'id', 'title', 'created_at', 'updated_at'},
    'chat_messages': {
      'id',
      'session_id',
      'role',
      'content',
      'message_type',
      'metadata_json',
      'sequence',
      'created_at',
    },
    'pending_actions': {
      'id',
      'session_id',
      'message_id',
      'action_type',
      'payload_json',
      'status',
      'operation_id',
      'error_message',
      'created_at',
      'resolved_at',
    },
    'financial_operations': {
      'id',
      'kind',
      'entity_id',
      'summary',
      'payload_json',
      'status',
      'created_at',
      'undone_at',
    },
    'sms_sender_links': {'sender', 'account_id', 'import_from'},
    'sms_suggestions': {
      'id',
      'sender',
      'received_at',
      'template',
      'context_key',
      'context_message_id',
      'payload',
      'status',
    },
    'sms_patterns': {'key', 'rule'},
    'sms_sender_dismissals': {'sender'},
    'obligations': {
      'id',
      'counterparty',
      'is_receivable',
      'amount_rial',
      'due_date',
      'note',
      'created_at',
    },
    'obligation_payments': {'id', 'obligation_id', 'amount_rial', 'paid_on'},
    'asset_holdings': {
      'id',
      'name',
      'kind',
      'currency_code',
      'quantity_micros',
      'rate_rial',
      'rate_date',
      'is_market_rate',
      'created_at',
    },
  };

  /// CSV of all transactions in [range], with a BOM so Excel reads Persian.
  Future<Uint8List> transactionsCsv(
    DateRange range, {
    String? accountId,
    String? categoryId,
  }) async {
    final rows = await _transactions.list(
      TransactionFilter(
        start: range.startStored,
        end: range.end.stored,
        accountId: accountId,
        categoryId: categoryId,
        limit: 10000,
      ),
    );
    final formatter = MoneyFormatter(
      unit: CurrencyUnit.toman,
      usePersianDigits: false,
    );
    final data = <List<Object?>>[
      [
        'تاریخ شمسی',
        'تاریخ میلادی',
        'نوع',
        'مبلغ (ریال)',
        'مبلغ نمایشی',
        'دسته‌بندی',
        'حساب',
        'توضیح',
      ],
      for (final row in rows)
        [
          PersianDigits.toPersian(
            '${CalendarDate.fromStored(row.transactionDate).jalali.year}/'
            '${CalendarDate.fromStored(row.transactionDate).jalali.month}/'
            '${CalendarDate.fromStored(row.transactionDate).jalali.day}',
          ),
          CalendarDate.fromStored(row.transactionDate).toIso(),
          row.isIncome ? 'درآمد' : 'هزینه',
          row.amountRial.value,
          formatter.format(row.amountRial),
          row.categoryName ?? 'بدون دسته‌بندی',
          row.accountName ?? '',
          row.description ?? '',
        ],
    ];
    final csv = const CsvEncoder(addBom: true).convert(data);
    return Uint8List.fromList(utf8.encode(csv));
  }

  /// A polished A4 PDF report with shaped Persian text.
  Future<Uint8List> reportPdf(
    DateRange range, {
    String? accountId,
    String? categoryId,
  }) async {
    final report = await _analytics.buildReport(
      range: range,
      accountId: accountId,
      categoryId: categoryId,
    );
    final regularData = await rootBundle.load(
      'assets/fonts/Vazirmatn-Regular.ttf',
    );
    final boldData = await rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf');
    final regular = pw.Font.ttf(regularData);
    final bold = pw.Font.ttf(boldData);
    final money = MoneyFormatter(
      unit: CurrencyUnit.toman,
      usePersianDigits: true,
    );
    final jalali = CalendarDate.fromStored(DateTime.now());
    const dateText = JalaliText();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      title: 'گزارش دارام',
      author: 'DARAM',
    );

    pw.Widget rtlText(
      String text, {
      double size = 10,
      bool isBold = false,
      PdfColor? color,
      pw.TextAlign align = pw.TextAlign.right,
    }) => pdfRtlText(
      text,
      size: size,
      isBold: isBold,
      color: color,
      align: align,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 26,
                      height: 26,
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFF5B57E8),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'D',
                        style: pw.TextStyle(
                          font: bold,
                          color: PdfColors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    rtlText(
                      'دارام — دستیار مالی هوشمند',
                      size: 13,
                      isBold: true,
                    ),
                  ],
                ),
                rtlText('تولید در ${dateText.numeric(jalali)}'),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Divider(color: const PdfColor.fromInt(0xFFE3E7F0)),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            rtlText(
              'دارام — همه محاسبات از داده‌های محلی انجام شده است.',
              size: 8,
              color: PdfColors.grey500,
            ),
            pw.Text(
              '${context.pageNumber} / ${context.pagesCount}',
              textDirection: pw.TextDirection.ltr,
              textAlign: pw.TextAlign.left,
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
        build: (context) => [
          rtlText('گزارش مالی', size: 22, isBold: true),
          pw.SizedBox(height: 4),
          rtlText(
            'از ${dateText.numeric(CalendarDate.fromStored(range.start.stored))}'
            ' تا ${dateText.numeric(CalendarDate.fromStored(range.end.stored))}',
            size: 10,
            color: PdfColors.grey600,
          ),
          pw.SizedBox(height: 18),
          pw.Row(
            children: [
              _pdfStat(
                'درآمد',
                money.format(report.summary.income),
                const PdfColor.fromInt(0xFF0E9F6E),
                rtlText,
              ),
              pw.SizedBox(width: 8),
              _pdfStat(
                'هزینه',
                money.format(report.summary.expense),
                const PdfColor.fromInt(0xFFE23D5A),
                rtlText,
              ),
              pw.SizedBox(width: 8),
              _pdfStat(
                'خالص',
                money.format(report.summary.net),
                const PdfColor.fromInt(0xFF5B57E8),
                rtlText,
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          rtlText('هزینه بر اساس دسته‌بندی', size: 13, isBold: true),
          pw.SizedBox(height: 8),
          if (report.categories.isEmpty)
            rtlText(
              'در این بازه هزینه‌ای ثبت نشده است.',
              color: PdfColors.grey600,
            )
          else
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: const PdfColor.fromInt(0xFFEDF0F5),
                  width: 0.6,
                ),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF4F6FB),
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: rtlText('سهم', size: 9, isBold: true),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: rtlText('مبلغ', size: 9, isBold: true),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: rtlText('دسته‌بندی', size: 9, isBold: true),
                    ),
                  ],
                ),
                for (final item in report.categories.take(12))
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: rtlText(
                          PersianDigits.toPersian(
                            '${(item.share * 100).round()}٪',
                          ),
                          size: 9,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: rtlText(money.format(item.amount), size: 9),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: rtlText(item.name, size: 9),
                      ),
                    ],
                  ),
              ],
            ),
          pw.SizedBox(height: 20),
          rtlText('تراکنش‌ها', size: 13, isBold: true),
          pw.SizedBox(height: 8),
          if (report.transactions.isEmpty)
            rtlText('تراکنشی در این بازه وجود ندارد.', color: PdfColors.grey600)
          else
            pw.Table(
              border: pw.TableBorder(
                horizontalInside: pw.BorderSide(
                  color: const PdfColor.fromInt(0xFFEDF0F5),
                  width: 0.6,
                ),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(2.2),
                4: pw.FlexColumnWidth(1),
                5: pw.FlexColumnWidth(1.3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF4F6FB),
                  ),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: rtlText('توضیح', size: 8, isBold: true),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: rtlText('مبلغ', size: 8, isBold: true),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: rtlText('حساب', size: 8, isBold: true),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: rtlText('دسته‌بندی', size: 8, isBold: true),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: rtlText('نوع', size: 8, isBold: true),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: rtlText('تاریخ', size: 8, isBold: true),
                    ),
                  ],
                ),
                for (final row in report.transactions.take(60))
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: rtlText(row.description ?? '—', size: 8),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: rtlText(
                          money.format(row.amountRial),
                          size: 8,
                          isBold: true,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: rtlText(row.accountName ?? '—', size: 8),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: rtlText(row.categoryName ?? '—', size: 8),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: rtlText(row.type.labelFa, size: 8),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: rtlText(
                          dateText.numeric(
                            CalendarDate.fromStored(row.transactionDate),
                          ),
                          size: 8,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  pw.Widget _pdfStat(
    String label,
    String value,
    PdfColor color,
    pw.Widget Function(
      String text, {
      double size,
      bool isBold,
      PdfColor? color,
      pw.TextAlign align,
    })
    rtlText,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFF7F7FE),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            rtlText(label, size: 8, color: PdfColors.grey600),
            pw.SizedBox(height: 3),
            rtlText(value, size: 11, isBold: true, color: color),
          ],
        ),
      ),
    );
  }

  /// Full JSON backup of every table, with raw storage values.
  Future<Uint8List> backupJson() async {
    final tables = await _db.transaction(() async {
      final data = <String, List<Map<String, dynamic>>>{};
      for (final table in tableOrder) {
        final rows = await _db.customSelect('SELECT * FROM $table').get();
        data[table] = rows.map((row) => row.data).toList();
      }
      return data;
    });
    final payload = {
      'format': backupFormat,
      'version': backupVersion,
      'app': 'DARAM',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'tables': tables,
    };
    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
  }

  /// Validates and restores a backup in one transaction. Any problem leaves the
  /// existing local data untouched.
  Future<BackupSummary> restore(Uint8List bytes) async {
    Map<String, Object?> decoded;
    try {
      final value = jsonDecode(utf8.decode(bytes));
      if (value is! Map) throw const FormatException();
      decoded = value.map((key, value) => MapEntry('$key', value));
    } on Object {
      throw const ValidationException('فایل پشتیبان معتبر نیست.');
    }

    if (decoded['format'] != backupFormat) {
      throw const ValidationException('این فایل مربوط به دارام نیست.');
    }
    if (decoded['version'] != backupVersion) {
      throw const ValidationException('نسخه فایل پشتیبان پشتیبانی نمی‌شود.');
    }
    final rawTables = decoded['tables'];
    if (rawTables is! Map) {
      throw const ValidationException('فایل پشتیبان جدولی ندارد.');
    }

    final tables = <String, List<Map<String, Object?>>>{};
    for (final table in tableOrder) {
      final raw =
          rawTables[table] ??
          (_optionalBackupTables.contains(table) ? const [] : null);
      if (raw is! List) {
        throw ValidationException('جدول «$table» در فایل پشتیبان نیست.');
      }
      final rows = <Map<String, Object?>>[];
      for (final row in raw) {
        if (row is! Map) {
          throw const ValidationException('ساختار فایل پشتیبان معتبر نیست.');
        }
        final map = row.map((key, value) => MapEntry('$key', value));
        final allowed = _allowedColumns[table]!;
        for (final key in map.keys) {
          if (!allowed.contains(key)) {
            throw ValidationException('ستون ناشناخته «$key» در جدول «$table».');
          }
        }
        for (final value in map.values) {
          if (value != null &&
              value is! String &&
              value is! num &&
              value is! bool) {
            throw const ValidationException('مقدار نامعتبر در فایل پشتیبان.');
          }
        }
        rows.add(map);
      }
      tables[table] = rows;
    }

    _validateReferences(tables);
    _validatePortfolio(tables);

    await _db.transaction(() async {
      for (final table in tableOrder.reversed) {
        await _db.customStatement('DELETE FROM $table');
      }
      for (final table in tableOrder) {
        final rows = tables[table]!;
        final columns = _allowedColumns[table]!.toList();
        for (final row in rows) {
          final present = columns.where(row.containsKey).toList();
          final placeholders = List<String>.filled(
            present.length,
            '?',
          ).join(', ');
          await _db.customStatement(
            'INSERT INTO $table (${present.join(', ')}) VALUES ($placeholders)',
            present.map((column) => row[column]).toList(),
          );
        }
      }
    });

    _db.markTablesUpdated(_db.allTables);
    return BackupSummary(
      exportedAt: DateTime.tryParse('${decoded['exported_at'] ?? ''}'),
      rowCounts: {
        for (final entry in tables.entries) entry.key: entry.value.length,
      },
    );
  }

  void _validateReferences(Map<String, List<Map<String, Object?>>> tables) {
    Set<String> ids(String table) =>
        tables[table]!.map((row) => '${row['id']}').toSet();

    final accountIds = ids('accounts');
    final categoryIds = ids('categories');
    final loanIds = ids('loans');
    final sessionIds = ids('chat_sessions');

    for (final row in tables['transactions']!) {
      if (!accountIds.contains('${row['account_id']}')) {
        throw const ValidationException(
          'تراکنشی به حسابی ناموجود اشاره می‌کند.',
        );
      }
      final category = row['category_id'];
      if (category != null && !categoryIds.contains('$category')) {
        throw const ValidationException(
          'تراکنشی به دسته‌بندی ناموجود اشاره می‌کند.',
        );
      }
      final amount = row['amount_rial'];
      if (amount is! int || amount <= 0) {
        throw const ValidationException(
          'مبلغ یک تراکنش در فایل پشتیبان معتبر نیست.',
        );
      }
    }
    for (final row in tables['transfers']!) {
      if (!accountIds.contains('${row['source_account_id']}') ||
          !accountIds.contains('${row['destination_account_id']}')) {
        throw const ValidationException(
          'انتقالی به حسابی ناموجود اشاره می‌کند.',
        );
      }
    }
    for (final row in tables['ledger_entries']!) {
      if (!accountIds.contains('${row['account_id']}')) {
        throw const ValidationException(
          'گردش حساب به حسابی ناموجود اشاره می‌کند.',
        );
      }
    }
    for (final row in tables['installments']!) {
      if (!loanIds.contains('${row['loan_id']}')) {
        throw const ValidationException('قسطی به وامی ناموجود اشاره می‌کند.');
      }
    }
    for (final row in tables['chat_messages']!) {
      if (!sessionIds.contains('${row['session_id']}')) {
        throw const ValidationException(
          'پیامی به گفتگویی ناموجود اشاره می‌کند.',
        );
      }
    }
    for (final row in tables['pending_actions']!) {
      if (!sessionIds.contains('${row['session_id']}')) {
        throw const ValidationException(
          'پیش‌نویسی به گفتگویی ناموجود اشاره می‌کند.',
        );
      }
    }
  }

  void _validatePortfolio(Map<String, List<Map<String, Object?>>> tables) {
    int positiveInt(Object? value, int max) {
      if (value is! int || value <= 0 || value > max) {
        throw const ValidationException(
          'مقدار مالی در فایل پشتیبان معتبر نیست.',
        );
      }
      return value;
    }

    final remaining = <String, int>{
      for (final row in tables['obligations']!)
        '${row['id']}': positiveInt(row['amount_rial'], Rial.maxAbsoluteValue),
    };
    for (final row in tables['obligation_payments']!) {
      final id = '${row['obligation_id']}';
      final balance = remaining[id];
      final amount = positiveInt(row['amount_rial'], Rial.maxAbsoluteValue);
      if (balance == null || amount > balance) {
        throw const ValidationException(
          'پرداختی در فایل پشتیبان با مانده سازگار نیست.',
        );
      }
      remaining[id] = balance - amount;
    }

    for (final row in tables['asset_holdings']!) {
      final quantity = AssetQuantity.fromMicros(
        positiveInt(row['quantity_micros'], AssetQuantity.maxMicros),
      );
      if (row['rate_rial'] case final rate?) {
        quantity.valueAt(Rial(positiveInt(rate, Rial.maxAbsoluteValue)));
      }
    }
  }

  /// Shows a save dialog and writes [bytes]. Returns the saved location, if any.
  Future<Uri?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) {
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
      dialogTitle: 'ذخیره فایل دارام',
    );
  }

  /// Lets the user pick a `.json` backup file and returns its bytes.
  Future<Uint8List?> pickBackupFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return null;
    return files.first.readAsBytes();
  }

  /// Reads a stored amount from a raw backup row for tests and diagnostics.
  Rial? amountOf(Map<String, Object?> row, String key) {
    final value = row[key];
    return value is int ? Rial(value) : null;
  }

  /// Builds a raw table snapshot (used by diagnostics and tests).
  Future<Map<String, int>> tableCounts() async {
    final counts = <String, int>{};
    for (final table in tableOrder) {
      final row = await _db
          .customSelect('SELECT COUNT(*) AS count FROM $table')
          .getSingle();
      counts[table] = row.read<int>('count');
    }
    return counts;
  }
}
