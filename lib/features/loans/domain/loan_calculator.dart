import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import 'loan.dart';

/// Deterministic loan schedule calculations.
///
/// The assistant may explain a schedule but never computes it: this class is
/// the only place where installments are split. Remainders (when the principal
/// is not divisible by the installment count) are assigned to the last
/// installment instead of being silently rounded away.
class LoanCalculator {
  const LoanCalculator._();

  static const int maxInstallments = 360;

  /// Builds a schedule of [installmentCount] installments.
  ///
  /// [dueDates] must contain exactly one date per installment. When it is
  /// omitted, due dates are generated monthly from [startDate] — callers must
  /// only rely on that for user-visible, editable defaults.
  static List<InstallmentDraft> buildSchedule({
    required Rial principal,
    required int installmentCount,
    required CalendarDate startDate,
    Rial interest = Rial.zero,
    List<CalendarDate> dueDates = const [],
  }) {
    if (principal <= Rial.zero) {
      throw const ValidationException('مبلغ وام باید بزرگ‌تر از صفر باشد.');
    }
    if (installmentCount < 1 || installmentCount > maxInstallments) {
      throw const ValidationException('تعداد اقساط باید بین ۱ تا ۳۶۰ باشد.');
    }
    if (interest < Rial.zero) {
      throw const ValidationException('سود وام نمی‌تواند منفی باشد.');
    }
    if (dueDates.isNotEmpty && dueDates.length != installmentCount) {
      throw const ValidationException(
        'تعداد تاریخ‌های سررسید با تعداد اقساط برابر نیست.',
      );
    }

    final dates = dueDates.isNotEmpty
        ? dueDates
        : List<CalendarDate>.generate(
            installmentCount,
            (index) => startDate.addJalaliMonths(index + 1),
          );

    for (var i = 1; i < dates.length; i++) {
      if (!dates[i].isAfter(dates[i - 1])) {
        throw const ValidationException('تاریخ سررسید اقساط باید صعودی باشد.');
      }
    }

    final principalBase = principal.value ~/ installmentCount;
    final principalRemainder = principal.value % installmentCount;
    final interestBase = interest.value ~/ installmentCount;
    final interestRemainder = interest.value % installmentCount;

    return List<InstallmentDraft>.generate(installmentCount, (index) {
      final isLast = index == installmentCount - 1;
      final principalPart = principalBase + (isLast ? principalRemainder : 0);
      final interestPart = interestBase + (isLast ? interestRemainder : 0);
      return InstallmentDraft(
        number: index + 1,
        dueDate: dates[index].stored,
        principalRial: Rial(principalPart),
        interestRial: Rial(interestPart),
        amountRial: Rial(principalPart + interestPart),
      );
    });
  }

  /// The base installment amount shown on the loan card.
  static Rial baseInstallment({
    required Rial principal,
    required Rial interest,
    required int installmentCount,
  }) {
    if (installmentCount < 1) return Rial.zero;
    return Rial((principal.value + interest.value) ~/ installmentCount);
  }

  /// Outstanding principal: principal minus the principal parts already paid.
  static Rial outstanding({
    required Rial principal,
    required Iterable<Rial> paidPrincipalParts,
  }) {
    final paid = Rial.sum(paidPrincipalParts);
    final remaining = principal - paid;
    return remaining.isNegative ? Rial.zero : remaining;
  }
}
