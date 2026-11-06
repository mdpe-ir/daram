import 'package:meta/meta.dart';

import '../../../core/domain/enums.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../accounts/domain/account.dart';
import '../../loans/domain/loan.dart';
import '../../transactions/domain/transaction_record.dart';

/// Income/expense totals for a period, computed locally from the ledger-backed
/// transactions table.
@immutable
final class PeriodSummary {
  const PeriodSummary({
    required this.income,
    required this.expense,
    required this.transactionCount,
  });

  const PeriodSummary.empty()
    : income = Rial.zero,
      expense = Rial.zero,
      transactionCount = 0;

  final Rial income;
  final Rial expense;
  final int transactionCount;

  Rial get net => income - expense;
}

/// One slice of the category breakdown.
@immutable
final class CategoryBreakdownItem {
  const CategoryBreakdownItem({
    required this.categoryId,
    required this.name,
    required this.colorHex,
    required this.icon,
    required this.amount,
    required this.share,
    required this.count,
  });

  final String? categoryId;
  final String name;
  final String colorHex;
  final String icon;
  final Rial amount;

  /// Fraction of the total in the 0..1 range.
  final double share;
  final int count;
}

/// A month in the trend chart.
@immutable
final class MonthlyPoint {
  const MonthlyPoint({
    required this.jalaliYear,
    required this.jalaliMonth,
    required this.label,
    required this.income,
    required this.expense,
  });

  final int jalaliYear;
  final int jalaliMonth;
  final String label;
  final Rial income;
  final Rial expense;
}

/// Everything the dashboard needs, calculated from the local database.
@immutable
final class DashboardSnapshot {
  const DashboardSnapshot({
    required this.totalBalance,
    required this.accounts,
    required this.summary,
    required this.monthly,
    required this.categoryBreakdown,
    required this.recentTransactions,
    required this.upcomingInstallments,
    required this.loans,
    required this.range,
  });

  final Rial totalBalance;
  final List<AccountWithBalance> accounts;
  final PeriodSummary summary;
  final List<MonthlyPoint> monthly;
  final List<CategoryBreakdownItem> categoryBreakdown;
  final List<TransactionRecord> recentTransactions;
  final List<Installment> upcomingInstallments;
  final List<Loan> loans;
  final DateRange range;
}

/// Data backing a financial report, both in chat and in the reports screen.
@immutable
final class ReportData {
  const ReportData({
    required this.range,
    required this.summary,
    required this.categories,
    required this.transactions,
    required this.accounts,
    this.accountId,
    this.categoryId,
    this.transactionType,
    this.grouping = 'category',
  });

  final DateRange range;
  final PeriodSummary summary;
  final List<CategoryBreakdownItem> categories;
  final List<TransactionRecord> transactions;
  final List<AccountWithBalance> accounts;
  final String? accountId;
  final String? categoryId;
  final TransactionType? transactionType;
  final String grouping;

  bool get isEmpty => summary.transactionCount == 0;
}
