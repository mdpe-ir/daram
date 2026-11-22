import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';

class Obligation {
  const Obligation({
    required this.id,
    required this.counterparty,
    required this.isReceivable,
    required this.amount,
    required this.paid,
    this.dueDate,
    this.note,
  });

  final String id;
  final String counterparty;
  final bool isReceivable;
  final Rial amount;
  final Rial paid;
  final CalendarDate? dueDate;
  final String? note;

  Rial get remaining => amount - paid;
}
