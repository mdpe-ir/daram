import 'package:meta/meta.dart';

import '../../../core/domain/enums.dart';
import '../../../core/money/rial.dart';

/// A recorded income or expense, tied to an account and optionally a category.
@immutable
final class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.type,
    required this.amountRial,
    required this.accountId,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.description,
    this.operationId,
    this.accountName,
    this.categoryName,
    this.categoryColorHex,
    this.categoryIcon,
  });

  final String id;
  final TransactionType type;
  final Rial amountRial;
  final String? categoryId;
  final String accountId;
  final DateTime transactionDate;
  final String? description;
  final String? operationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Denormalised display fields filled by list queries.
  final String? accountName;
  final String? categoryName;
  final String? categoryColorHex;
  final String? categoryIcon;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  TransactionRecord copyWith({
    TransactionType? type,
    Rial? amountRial,
    String? categoryId,
    String? accountId,
    DateTime? transactionDate,
    String? description,
    DateTime? updatedAt,
  }) {
    return TransactionRecord(
      id: id,
      type: type ?? this.type,
      amountRial: amountRial ?? this.amountRial,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      transactionDate: transactionDate ?? this.transactionDate,
      description: description ?? this.description,
      operationId: operationId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      accountName: accountName,
      categoryName: categoryName,
      categoryColorHex: categoryColorHex,
      categoryIcon: categoryIcon,
    );
  }
}

/// A movement between two accounts owned by the user.
///
/// Transfers never change income or expense totals; only balances.
@immutable
final class TransferRecord {
  const TransferRecord({
    required this.id,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.amountRial,
    required this.transferDate,
    required this.feeRial,
    required this.createdAt,
    this.description,
    this.sourceAccountName,
    this.destinationAccountName,
  });

  final String id;
  final String sourceAccountId;
  final String destinationAccountId;
  final Rial amountRial;
  final Rial feeRial;
  final DateTime transferDate;
  final String? description;
  final DateTime createdAt;
  final String? sourceAccountName;
  final String? destinationAccountName;

  Rial get totalDebit => amountRial + feeRial;
}

/// Search/filter criteria for the transactions screen and tool queries.
@immutable
final class TransactionFilter {
  const TransactionFilter({
    this.start,
    this.end,
    this.type,
    this.accountId,
    this.categoryId,
    this.searchQuery,
    this.limit,
    this.offset,
  });

  final DateTime? start;
  final DateTime? end;
  final TransactionType? type;
  final String? accountId;
  final String? categoryId;
  final String? searchQuery;
  final int? limit;
  final int? offset;

  TransactionFilter copyWith({
    DateTime? start,
    DateTime? end,
    TransactionType? type,
    String? accountId,
    String? categoryId,
    String? searchQuery,
    int? limit,
    int? offset,
  }) {
    return TransactionFilter(
      start: start ?? this.start,
      end: end ?? this.end,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}
