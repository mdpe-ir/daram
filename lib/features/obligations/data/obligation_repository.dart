import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../domain/obligation.dart';

class ObligationRepository {
  ObligationRepository(this._db);

  final AppDatabase _db;

  JoinedSelectStatement<HasResultSet, dynamic> _withPaid() {
    final obligations = _db.obligations;
    final payments = _db.obligationPayments;
    return _db.select(obligations).join([
      leftOuterJoin(
        payments,
        payments.obligationId.equalsExp(obligations.id),
        useColumns: false,
      ),
    ])..groupBy([obligations.id]);
  }

  late final Expression<int> _paid = _db.obligationPayments.amountRial.sum();

  Obligation _map(TypedResult result) {
    final row = result.readTable(_db.obligations);
    return Obligation(
      id: row.id,
      counterparty: row.counterparty,
      isReceivable: row.isReceivable,
      amount: Rial(row.amountRial),
      paid: Rial(result.read(_paid) ?? 0),
      dueDate: row.dueDate == null
          ? null
          : CalendarDate.fromStored(row.dueDate!),
      note: row.note,
    );
  }

  Stream<List<Obligation>> watch() =>
      (_withPaid()
            ..addColumns([_paid])
            ..orderBy([
              OrderingTerm.desc(_db.obligations.createdAt),
              OrderingTerm.asc(_db.obligations.id),
            ]))
          .watch()
          .map((rows) => rows.map(_map).toList());

  /// Snapshot of every obligation, used by the assistant tools.
  Future<List<Obligation>> list() async {
    final rows =
        await (_withPaid()
              ..addColumns([_paid])
              ..orderBy([
                OrderingTerm.desc(_db.obligations.createdAt),
                OrderingTerm.asc(_db.obligations.id),
              ]))
            .get();
    return rows.map(_map).toList();
  }

  Future<Obligation?> findById(String id) async {
    final result =
        await (_withPaid()
              ..addColumns([_paid])
              ..where(_db.obligations.id.equals(id)))
            .getSingleOrNull();
    return result == null ? null : _map(result);
  }

  Future<Obligation> _get(String id) async {
    final result =
        await (_withPaid()
              ..addColumns([_paid])
              ..where(_db.obligations.id.equals(id)))
            .getSingleOrNull();
    if (result == null) {
      throw const NotFoundException('این مورد پیدا نشد.');
    }
    return _map(result);
  }

  Stream<List<ObligationPaymentRow>> watchPayments(String id) =>
      (_db.select(_db.obligationPayments)
            ..where((row) => row.obligationId.equals(id))
            ..orderBy([
              (row) => OrderingTerm.desc(row.paidOn),
              (row) => OrderingTerm.asc(row.id),
            ]))
          .watch();

  Future<void> save({
    String? id,
    required String counterparty,
    required bool isReceivable,
    required Rial amount,
    CalendarDate? dueDate,
    String? note,
  }) => _db.transaction(() async {
    final name = counterparty.trim();
    if (name.isEmpty || name.length > 100) {
      throw const ValidationException('نام طرف حساب را وارد کنید.');
    }
    if (amount.value <= 0) {
      throw const ValidationException('مبلغ باید بیشتر از صفر باشد.');
    }
    if (id != null) {
      final existing = await _get(id);
      if (amount < existing.paid) {
        throw const ValidationException('مبلغ از مجموع پرداخت‌ها کمتر است.');
      }
    }

    final values = ObligationsCompanion(
      counterparty: Value(name),
      isReceivable: Value(isReceivable),
      amountRial: Value(amount.value),
      dueDate: Value(dueDate?.stored),
      note: Value(note == null || note.trim().isEmpty ? null : note.trim()),
    );
    if (id == null) {
      await _db
          .into(_db.obligations)
          .insert(
            values.copyWith(
              id: Value(const Uuid().v4()),
              createdAt: Value(DateTime.now().toUtc()),
            ),
          );
    } else {
      await (_db.update(
        _db.obligations,
      )..where((row) => row.id.equals(id))).write(values);
    }
  });

  Future<void> addPayment(String id, Rial amount, CalendarDate date) =>
      _db.transaction(() async {
        final obligation = await _get(id);
        if (amount.value <= 0 || amount > obligation.remaining) {
          throw const ValidationException(
            'مبلغ پرداخت باید مثبت و حداکثر برابر مانده باشد.',
          );
        }
        await _db
            .into(_db.obligationPayments)
            .insert(
              ObligationPaymentsCompanion.insert(
                id: const Uuid().v4(),
                obligationId: id,
                amountRial: amount.value,
                paidOn: date.stored,
              ),
            );
      });

  Future<void> deletePayment(String id) async {
    await (_db.delete(
      _db.obligationPayments,
    )..where((row) => row.id.equals(id))).go();
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.obligations)..where((row) => row.id.equals(id))).go();
  }
}
