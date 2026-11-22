import 'dart:convert';

import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/errors/app_exception.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/accounts/data/account_repository.dart';
import 'package:daram/features/assets/data/asset_repository.dart';
import 'package:daram/features/assets/domain/asset_quantity.dart';
import 'package:daram/features/categories/data/category_repository.dart';
import 'package:daram/features/dashboard/data/analytics_repository.dart';
import 'package:daram/features/loans/data/loan_repository.dart';
import 'package:daram/features/obligations/data/obligation_repository.dart';
import 'package:daram/features/settings/data/export_service.dart';
import 'package:daram/features/transactions/data/operation_repository.dart';
import 'package:daram/features/transactions/data/transaction_repository.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AccountRepository accounts;
  late ExportService exporter;

  setUp(() async {
    db = AppDatabase.memory();
    final operations = OperationRepository(db);
    final categories = CategoryRepository(db);
    await categories.ensureDefaults();
    accounts = AccountRepository(db, operations);
    final transactions = TransactionRepository(db, operations);
    final loans = LoanRepository(db, operations);
    final account = await accounts.create(
      bankId: 'mellat',
      bankName: 'بانک ملت',
      accountName: 'حساب ملت',
      accountType: AccountType.bank,
      initialBalance: Rial.fromToman(1000000),
      operationId: 'op-account',
    );
    await transactions.create(
      type: TransactionType.expense,
      amount: Rial.fromToman(250000),
      accountId: account.id,
      categoryId: 'cat_food',
      date: CalendarDate(2026, 11, 6),
      description: 'ناهار',
      operationId: 'op-expense',
    );
    exporter = ExportService(
      db: db,
      transactions: transactions,
      analytics: AnalyticsRepository(db, accounts, transactions, loans),
    );
  });

  tearDown(() async => db.close());

  final range = DateRange(
    CalendarDate(2026, 11, 1),
    CalendarDate(2026, 11, 30),
  );

  test('CSV export contains Persian headers and exact rial amounts', () async {
    final bytes = await exporter.transactionsCsv(range);
    final text = utf8.decode(bytes);
    expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
    expect(text, contains('تاریخ شمسی'));
    expect(text, contains('ناهار'));
    expect(text, contains('2500000'));
  });

  test('PDF text is shaped to visual order and drawn LTR', () {
    final text = pdfRtlText('دارام — دستیار مالی هوشمند');
    expect(text.textDirection, pw.TextDirection.ltr);
    final span = text.text as pw.TextSpan;
    expect(span.text, shapePersian('دارام — دستیار مالی هوشمند'));
    expect(span.text, isNot('دارام — دستیار مالی هوشمند'));
  });

  test('PDF export produces a real PDF document', () async {
    final bytes = await exporter.reportPdf(range);
    expect(bytes.length, greaterThan(2000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('backup round-trip restores all tables', () async {
    final obligations = ObligationRepository(db);
    final assets = AssetRepository(db);
    await obligations.save(
      counterparty: 'رضا',
      isReceivable: false,
      amount: Rial(300000),
    );
    final debt = (await obligations.watch().first).single;
    await obligations.addPayment(debt.id, Rial(50000), range.start);
    await assets.save(
      name: 'طلای پس‌انداز',
      kind: AssetKind.gold,
      quantity: AssetQuantity.tryParse('۲٫۲۵')!,
      rate: Rial(100000),
      rateDate: range.start.stored,
      isMarketRate: true,
    );
    await db
        .into(db.smsSenderDismissals)
        .insert(const SmsSenderDismissal(sender: '1001'));
    final bytes = await exporter.backupJson();
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    expect(decoded['format'], 'daram-backup');
    expect(decoded['version'], 1);
    final tables = decoded['tables']! as Map<String, Object?>;
    expect(tables['accounts'], hasLength(1));
    expect(tables['transactions'], hasLength(1));

    await accounts.create(
      bankId: 'blue',
      bankName: 'بلو بانک',
      accountName: 'حساب موقت',
      accountType: AccountType.bank,
      initialBalance: Rial.zero,
      operationId: 'op-temp',
    );
    expect(await accounts.list(), hasLength(2));

    await obligations.delete(debt.id);
    await assets.delete((await assets.watch().first).single.id);
    await db.delete(db.smsSenderDismissals).go();
    final summary = await exporter.restore(bytes);
    expect(summary.rowCounts['accounts'], 1);
    expect(await accounts.list(), hasLength(1));
    final rows = await db.select(db.transactions).get();
    expect(rows.single.description, 'ناهار');
    expect((await obligations.watch().first).single.remaining, Rial(250000));
    final asset = (await assets.watch().first).single;
    expect(asset.isMarketRate, isTrue);
    expect(
      AssetQuantity.fromMicros(asset.quantityMicros)
          .valueAt(Rial(asset.rateRial!)),
      Rial(225000),
    );
    expect(
      (await db.select(db.smsSenderDismissals).get()).single.sender,
      '1001',
    );

    tables.remove('obligations');
    tables.remove('obligation_payments');
    tables.remove('asset_holdings');
    tables.remove('sms_sender_dismissals');
    await exporter.restore(utf8.encode(jsonEncode(decoded)));
    expect(await obligations.watch().first, isEmpty);
    expect(await assets.watch().first, isEmpty);
    expect(await accounts.list(), hasLength(1));
  });

  test('invalid backups never touch existing data', () async {
    expect(
      () => exporter.restore(utf8.encode('{"format":"other"}')),
      throwsA(isA<ValidationException>()),
    );
    expect(await accounts.list(), hasLength(1));

    expect(
      () => exporter.restore(
        utf8.encode('{"format":"daram-backup","version":1,"tables":{}}'),
      ),
      throwsA(isA<ValidationException>()),
    );
    expect(await accounts.list(), hasLength(1));
    expect(await db.select(db.transactions).get(), hasLength(1));
  });

  test('table counts reflect the local database', () async {
    final counts = await exporter.tableCounts();
    expect(counts['accounts'], 1);
    expect(counts['transactions'], 1);
    expect(counts['ledger_entries'], 1);
  });
}
