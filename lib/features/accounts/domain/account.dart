import 'package:meta/meta.dart';

import '../../../core/domain/enums.dart';
import '../../../core/money/rial.dart';

/// A user-owned account.
@immutable
final class Account {
  const Account({
    required this.id,
    required this.bankId,
    required this.bankName,
    required this.accountName,
    required this.accountType,
    required this.initialBalanceRial,
    required this.createdAt,
    this.cardLastFour,
    this.description,
    this.archivedAt,
  });

  final String id;
  final String bankId;
  final String bankName;
  final String accountName;
  final AccountType accountType;
  final Rial initialBalanceRial;
  final String? cardLastFour;
  final String? description;
  final DateTime createdAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  Account copyWith({
    String? bankId,
    String? bankName,
    String? accountName,
    AccountType? accountType,
    Rial? initialBalanceRial,
    String? cardLastFour,
    String? description,
    DateTime? archivedAt,
  }) {
    return Account(
      id: id,
      bankId: bankId ?? this.bankId,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountType: accountType ?? this.accountType,
      initialBalanceRial: initialBalanceRial ?? this.initialBalanceRial,
      cardLastFour: cardLastFour ?? this.cardLastFour,
      description: description ?? this.description,
      createdAt: createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}

/// Account with its current balance derived from the ledger.
@immutable
final class AccountWithBalance {
  const AccountWithBalance({required this.account, required this.balance});

  final Account account;
  final Rial balance;
}
