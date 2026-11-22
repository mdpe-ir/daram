import 'package:daram/core/errors/app_exception.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/core/time/calendar_date.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/obligations/data/obligation_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'records only valid payments and derives the remaining balance',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final repository = ObligationRepository(db);
      const day = CalendarDate(2026, 11, 19);
      await repository.save(
        counterparty: 'رضا',
        isReceivable: true,
        amount: Rial(10000),
        dueDate: day,
      );
      final row = (await repository.watch().first).single;
      expect(row.dueDate, day);
      expect(row.remaining, Rial(10000));

      await repository.addPayment(row.id, Rial(3000), day);
      expect((await repository.watch().first).single.remaining, Rial(7000));
      await expectLater(
        repository.addPayment(row.id, Rial(7001), day),
        throwsA(isA<ValidationException>()),
      );
      await expectLater(
        repository.save(
          id: row.id,
          counterparty: row.counterparty,
          isReceivable: true,
          amount: Rial(2999),
        ),
        throwsA(isA<ValidationException>()),
      );

      await repository.addPayment(row.id, Rial(7000), day);
      expect((await repository.watch().first).single.remaining, Rial.zero);
      final payments = await repository.watchPayments(row.id).first;
      final last = payments.singleWhere(
        (payment) => payment.amountRial == 7000,
      );
      await repository.deletePayment(last.id);
      expect((await repository.watch().first).single.remaining, Rial(7000));
      await repository.delete(row.id);
      expect(await repository.watchPayments(row.id).first, isEmpty);
      expect(await db.select(db.ledgerEntries).get(), isEmpty);
    },
  );

  test('serializes competing payments against the same balance', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    final repository = ObligationRepository(db);
    await repository.save(
      counterparty: 'رضا',
      isReceivable: false,
      amount: Rial(10000),
    );
    final id = (await repository.watch().first).single.id;
    Future<bool> pay() async {
      try {
        await repository.addPayment(id, Rial(7000), CalendarDate.today());
        return true;
      } on ValidationException {
        return false;
      }
    }

    expect(await Future.wait([pay(), pay()]), unorderedEquals([true, false]));
    expect((await repository.watch().first).single.remaining, Rial(3000));
  });
}
