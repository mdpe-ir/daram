import 'package:meta/meta.dart';

import '../../../core/domain/enums.dart';
import '../../../core/money/rial.dart';

/// A loan with a deterministic installment schedule.
@immutable
final class Loan {
  const Loan({
    required this.id,
    required this.title,
    required this.principalAmountRial,
    required this.installmentCount,
    required this.startDate,
    required this.status,
    required this.createdAt,
    this.installmentAmountRial = Rial.zero,
    this.interestAmountRial = Rial.zero,
    this.accountId,
    this.description,
    this.accountName,
    this.paidInstallments = 0,
    this.totalPaidRial = Rial.zero,
    this.outstandingRial = Rial.zero,
    this.nextDueDate,
  });

  final String id;
  final String title;
  final Rial principalAmountRial;
  final int installmentCount;
  final Rial installmentAmountRial;
  final Rial interestAmountRial;
  final String? accountId;
  final DateTime startDate;
  final LoanStatus status;
  final String? description;
  final DateTime createdAt;

  /// Denormalised / derived display fields.
  final String? accountName;
  final int paidInstallments;
  final Rial totalPaidRial;
  final Rial outstandingRial;
  final DateTime? nextDueDate;

  bool get isClosed => status == LoanStatus.closed;
  double get progress =>
      installmentCount == 0 ? 0 : paidInstallments / installmentCount;

  Loan copyWith({
    String? title,
    LoanStatus? status,
    String? description,
    Rial? outstandingRial,
    int? paidInstallments,
    DateTime? nextDueDate,
  }) {
    return Loan(
      id: id,
      title: title ?? this.title,
      principalAmountRial: principalAmountRial,
      installmentCount: installmentCount,
      installmentAmountRial: installmentAmountRial,
      interestAmountRial: interestAmountRial,
      accountId: accountId,
      startDate: startDate,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt,
      accountName: accountName,
      paidInstallments: paidInstallments ?? this.paidInstallments,
      totalPaidRial: totalPaidRial,
      outstandingRial: outstandingRial ?? this.outstandingRial,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }
}

/// One scheduled repayment.
@immutable
final class Installment {
  const Installment({
    required this.id,
    required this.loanId,
    required this.number,
    required this.dueDate,
    required this.amountRial,
    required this.principalRial,
    required this.interestRial,
    required this.status,
    this.paidAmountRial = Rial.zero,
    this.paidAt,
    this.loanTitle,
  });

  final String id;
  final String loanId;
  final int number;
  final DateTime dueDate;
  final Rial amountRial;
  final Rial principalRial;
  final Rial interestRial;
  final InstallmentStatus status;
  final Rial paidAmountRial;
  final DateTime? paidAt;
  final String? loanTitle;

  bool get isPaid => status == InstallmentStatus.paid;

  bool get isOverdue {
    if (isPaid) return false;
    final today = DateTime.now();
    final todayDate = DateTime.utc(today.year, today.month, today.day);
    return dueDate.toUtc().isBefore(todayDate);
  }
}

/// Description of a loan schedule before anything is persisted.
@immutable
final class InstallmentDraft {
  const InstallmentDraft({
    required this.number,
    required this.dueDate,
    required this.amountRial,
    required this.principalRial,
    required this.interestRial,
  });

  final int number;
  final DateTime dueDate;
  final Rial amountRial;
  final Rial principalRial;
  final Rial interestRial;
}
