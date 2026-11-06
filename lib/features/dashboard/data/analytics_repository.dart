import 'package:drift/drift.dart';

import '../../../core/domain/enums.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/jalali_text.dart';
import '../../../data/database/app_database.dart';
import '../../accounts/data/account_repository.dart';
import '../../loans/data/loan_repository.dart';
import '../../transactions/data/transaction_repository.dart';
import '../../transactions/domain/transaction_record.dart';
import '../domain/analytics.dart';

/// All financial analytics. Every number is computed from the local database;
/// the AI never supplies totals.
class AnalyticsRepository {
  AnalyticsRepository(
    this._db,
    this._accounts,
    this._transactions,
    this._loans,
  );

  final AppDatabase _db;
  final AccountRepository _accounts;
  final TransactionRepository _transactions;
  final LoanRepository _loans;

  Future<Rial> totalBalance() async {
    final row = await _db
        .customSelect(
          '''
      SELECT
        (SELECT COALESCE(SUM(initial_balance_rial), 0) FROM accounts WHERE archived_at IS NULL)
        +
        (SELECT COALESCE(SUM(l.delta_rial), 0)
           FROM ledger_entries l
           JOIN accounts a ON a.id = l.account_id
          WHERE a.archived_at IS NULL) AS total
      ''',
          readsFrom: {_db.accounts, _db.ledgerEntries},
        )
        .getSingle();
    return Rial(row.read<int>('total'));
  }

  Future<PeriodSummary> summary(DateRange range, {String? accountId}) async {
    final variables = <Variable<Object>>[
      Variable.withDateTime(range.startStored),
      Variable.withDateTime(range.endExclusiveStored),
      if (accountId != null) Variable.withString(accountId),
    ];
    final row = await _db
        .customSelect(
          '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_rial ELSE 0 END), 0) AS income,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_rial ELSE 0 END), 0) AS expense,
        COUNT(*) AS count
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      ${accountId != null ? 'AND account_id = ?' : ''}
      ''',
          variables: variables,
          readsFrom: {_db.transactions},
        )
        .getSingle();
    return PeriodSummary(
      income: Rial(row.read<int>('income')),
      expense: Rial(row.read<int>('expense')),
      transactionCount: row.read<int>('count'),
    );
  }

  Future<List<CategoryBreakdownItem>> categoryBreakdown(
    DateRange range, {
    required TransactionType type,
    String? accountId,
    String? categoryId,
  }) async {
    final variables = <Variable<Object>>[
      Variable.withString(type.name),
      Variable.withDateTime(range.startStored),
      Variable.withDateTime(range.endExclusiveStored),
      if (accountId != null) Variable.withString(accountId),
      if (categoryId != null) Variable.withString(categoryId),
    ];
    final rows = await _db
        .customSelect(
          '''
      SELECT
        c.id AS category_id,
        COALESCE(c.name, 'بدون دسته‌بندی') AS category_name,
        COALESCE(c.color_hex, '#94A3B8') AS color_hex,
        COALESCE(c.icon, 'circle-ellipsis') AS icon,
        SUM(t.amount_rial) AS total,
        COUNT(*) AS count
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.type = ? AND t.transaction_date >= ? AND t.transaction_date < ?
      ${accountId != null ? 'AND t.account_id = ?' : ''}
      ${categoryId != null ? 'AND t.category_id = ?' : ''}
      GROUP BY c.id
      ORDER BY total DESC
      ''',
          variables: variables,
          readsFrom: {_db.transactions, _db.categories},
        )
        .get();
    final total = rows.fold<int>(0, (sum, row) => sum + row.read<int>('total'));
    return [
      for (final row in rows)
        CategoryBreakdownItem(
          categoryId: row.read<String?>('category_id'),
          name: row.read<String>('category_name'),
          colorHex: row.read<String>('color_hex'),
          icon: row.read<String>('icon'),
          amount: Rial(row.read<int>('total')),
          share: total == 0 ? 0 : row.read<int>('total') / total,
          count: row.read<int>('count'),
        ),
    ];
  }

  Future<List<MonthlyPoint>> monthly({
    int months = 6,
    CalendarDate? today,
  }) async {
    final reference = today ?? CalendarDate.today();
    final currentMonthStart = reference.startOfJalaliMonth;
    final firstMonthStart = currentMonthStart.addJalaliMonths(-(months - 1));
    final end = currentMonthStart.startOfNextJalaliMonth;

    final rows = await _db
        .customSelect(
          '''
      SELECT transaction_date, type, amount_rial
      FROM transactions
      WHERE transaction_date >= ? AND transaction_date < ?
      ''',
          variables: [
            Variable.withDateTime(firstMonthStart.stored),
            Variable.withDateTime(end.stored),
          ],
          readsFrom: {_db.transactions},
        )
        .get();

    final buckets = <String, ({int income, int expense})>{};
    for (final row in rows) {
      final date = CalendarDate.fromStored(
        row.read<DateTime>('transaction_date'),
      );
      final jalali = date.jalali;
      final key = '${jalali.year}-${jalali.month}';
      final current = buckets[key] ?? (income: 0, expense: 0);
      final amount = row.read<int>('amount_rial');
      if (row.read<String>('type') == 'income') {
        buckets[key] = (
          income: current.income + amount,
          expense: current.expense,
        );
      } else {
        buckets[key] = (
          income: current.income,
          expense: current.expense + amount,
        );
      }
    }

    return [
      for (var i = 0; i < months; i++)
        () {
          final monthStart = firstMonthStart.addJalaliMonths(i);
          final jalali = monthStart.jalali;
          final bucket = buckets['${jalali.year}-${jalali.month}'];
          return MonthlyPoint(
            jalaliYear: jalali.year,
            jalaliMonth: jalali.month,
            label: jalaliMonthNames[jalali.month - 1],
            income: Rial(bucket?.income ?? 0),
            expense: Rial(bucket?.expense ?? 0),
          );
        }(),
    ];
  }

  Future<DashboardSnapshot> dashboard({DateRange? range}) async {
    final today = CalendarDate.today();
    final selectedRange =
        range ??
        DateRange(
          CalendarDate.fromJalali(today.jalali.year, today.jalali.month, 1),
          today,
        );

    final accounts = await _accounts.listWithBalances();
    final summary = await this.summary(selectedRange);
    final monthlyPoints = await monthly();
    final breakdown = await categoryBreakdown(
      selectedRange,
      type: TransactionType.expense,
    );
    final recent = await _transactions.recent(limit: 5);
    final installments = await _loans.upcoming(limit: 5);
    final loans = await _loans.list();
    final balance = Rial.sum(accounts.map((account) => account.balance));

    return DashboardSnapshot(
      totalBalance: balance,
      accounts: accounts,
      summary: summary,
      monthly: monthlyPoints,
      categoryBreakdown: breakdown,
      recentTransactions: recent,
      upcomingInstallments: installments,
      loans: loans,
      range: selectedRange,
    );
  }

  Stream<DashboardSnapshot> watchDashboard({DateRange? range}) {
    return _db
        .customSelect(
          'SELECT id FROM transactions',
          readsFrom: {
            _db.transactions,
            _db.accounts,
            _db.ledgerEntries,
            _db.installments,
            _db.loans,
            _db.categories,
          },
        )
        .watch()
        .asyncMap((_) => dashboard(range: range));
  }

  Future<ReportData> buildReport({
    required DateRange range,
    TransactionType? type,
    String? accountId,
    String? categoryId,
    String grouping = 'category',
  }) async {
    final summary = await this.summary(range, accountId: accountId);
    final breakdownType = type ?? TransactionType.expense;
    final categories = await categoryBreakdown(
      range,
      type: breakdownType,
      accountId: accountId,
      categoryId: categoryId,
    );
    final transactions = await _transactions.list(
      TransactionFilter(
        start: range.startStored,
        end: range.end.stored,
        type: type,
        accountId: accountId,
        categoryId: categoryId,
      ),
    );
    final accounts = await _accounts.listWithBalances();
    return ReportData(
      range: range,
      summary: summary,
      categories: categories,
      transactions: transactions,
      accounts: accounts,
      accountId: accountId,
      categoryId: categoryId,
      transactionType: type,
      grouping: grouping,
    );
  }
}
