import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/formatting/persian_formatting.dart';
import '../../../core/money/rial.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/mappers.dart';
import '../../accounts/domain/account.dart';
import '../domain/transaction_record.dart';
import 'operation_repository.dart';

/// Reads and writes transfers.
///
/// A transfer moves money between two owned accounts and must never change
/// income or expense totals. Fees are recorded as a separate expense.
class TransferRepository {
  TransferRepository(this._db, this._operations);

  final AppDatabase _db;
  final OperationRepository _operations;
  static const _uuid = Uuid();

  Future<TransferRecord> create({
    required String sourceAccountId,
    required String destinationAccountId,
    required Rial amount,
    required CalendarDate date,
    required String operationId,
    Rial fee = Rial.zero,
    String? description,
    String? id,
  }) async {
    if (amount <= Rial.zero) {
      throw const ValidationException('مبلغ انتقال باید بزرگ‌تر از صفر باشد.');
    }
    if (fee < Rial.zero) {
      throw const ValidationException('کارمزد نمی‌تواند منفی باشد.');
    }
    if (sourceAccountId == destinationAccountId) {
      throw const ValidationException('حساب مبدأ و مقصد باید متفاوت باشند.');
    }
    final source = await _account(sourceAccountId);
    final destination = await _account(destinationAccountId);
    final transferId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();

    return _db.transaction(() async {
      final existing = await _operations.find(operationId);
      if (existing != null) {
        final record = await findById(existing.entityId);
        if (record != null) return record;
      }

      await _db
          .into(_db.transfers)
          .insert(
            TransfersCompanion.insert(
              id: transferId,
              sourceAccountId: sourceAccountId,
              destinationAccountId: destinationAccountId,
              amountRial: amount.value,
              feeRial: Value(fee.value),
              transferDate: date.stored,
              description: Value(description?.trim()),
              operationId: operationId,
              createdAt: now,
            ),
          );

      // The source loses the amount plus the fee; the destination gains exactly
      // the transferred amount, so the fee is not double counted.
      await _db.batch((batch) {
        batch.insert(
          _db.ledgerEntries,
          LedgerEntriesCompanion.insert(
            accountId: sourceAccountId,
            deltaRial: -(amount.value + fee.value),
            entryDate: date.stored,
            sourceType: LedgerSource.transferOut,
            sourceId: transferId,
            operationId: operationId,
            createdAt: now,
          ),
        );
        batch.insert(
          _db.ledgerEntries,
          LedgerEntriesCompanion.insert(
            accountId: destinationAccountId,
            deltaRial: amount.value,
            entryDate: date.stored,
            sourceType: LedgerSource.transferIn,
            sourceId: transferId,
            operationId: operationId,
            createdAt: now,
          ),
        );
      });

      if (fee > Rial.zero) {
        // A fee is a real expense, but its ledger movement is already included
        // in the transfer-out entry above, so no second ledger row is written.
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: '${transferId}_fee',
                type: TransactionType.expense,
                amountRial: fee.value,
                categoryId: const Value('cat_other_expense'),
                accountId: sourceAccountId,
                transactionDate: date.stored,
                description: Value(
                  'کارمزد انتقال${description == null ? '' : ' — $description'}',
                ),
                operationId: '$operationId:fee',
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      await _operations.record(
        operationId: operationId,
        kind: FinancialOperationKind.addTransfer,
        entityId: transferId,
        summary:
            'انتقال ${MoneyFormatter().format(amount)} از ${source.accountName} به ${destination.accountName}',
        payload: {
          'transferId': transferId,
          'sourceAccountId': sourceAccountId,
          'destinationAccountId': destinationAccountId,
          'amountRial': amount.value,
          'feeRial': fee.value,
          'date': date.toIso(),
        },
      );

      return TransferRecord(
        id: transferId,
        sourceAccountId: sourceAccountId,
        destinationAccountId: destinationAccountId,
        amountRial: amount,
        feeRial: fee,
        transferDate: date.stored,
        description: description?.trim(),
        createdAt: now,
        sourceAccountName: source.accountName,
        destinationAccountName: destination.accountName,
      );
    });
  }

  /// Edits a transfer and rewrites both ledger movements atomically.
  ///
  /// Any fee row is recreated so the source account movement and the recorded
  /// expense stay consistent. Only fields that are provided change.
  Future<void> update({
    required String id,
    String? sourceAccountId,
    String? destinationAccountId,
    Rial? amount,
    Rial? fee,
    CalendarDate? date,
    String? description,
    bool clearDescription = false,
  }) async {
    final row = await (_db.select(
      _db.transfers,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundException('انتقال پیدا نشد.');

    final newSourceId = sourceAccountId ?? row.sourceAccountId;
    final newDestinationId = destinationAccountId ?? row.destinationAccountId;
    final newAmount = amount ?? Rial(row.amountRial);
    final newFee = fee ?? Rial(row.feeRial);
    final newDate = date ?? CalendarDate.fromStored(row.transferDate);
    final newDescription = clearDescription
        ? null
        : (description?.trim() ?? row.description);

    if (newAmount <= Rial.zero) {
      throw const ValidationException('مبلغ انتقال باید بزرگ‌تر از صفر باشد.');
    }
    if (newFee < Rial.zero) {
      throw const ValidationException('کارمزد نمی‌تواند منفی باشد.');
    }
    if (newSourceId == newDestinationId) {
      throw const ValidationException('حساب مبدأ و مقصد باید متفاوت باشند.');
    }
    // Validate both accounts exist and are not archived before writing.
    await _account(newSourceId);
    await _account(newDestinationId);
    final now = DateTime.now().toUtc();

    await _db.transaction(() async {
      await (_db.delete(_db.ledgerEntries)..where(
            (table) =>
                table.sourceId.equals(id) &
                (table.sourceType.equalsValue(LedgerSource.transferOut) |
                    table.sourceType.equalsValue(LedgerSource.transferIn)),
          ))
          .go();
      await (_db.delete(
        _db.transactions,
      )..where((table) => table.id.equals('${id}_fee'))).go();

      await (_db.update(
        _db.transfers,
      )..where((table) => table.id.equals(id))).write(
        TransfersCompanion(
          sourceAccountId: Value(newSourceId),
          destinationAccountId: Value(newDestinationId),
          amountRial: Value(newAmount.value),
          feeRial: Value(newFee.value),
          transferDate: Value(newDate.stored),
          description: Value(newDescription),
        ),
      );

      await _db.batch((batch) {
        batch.insert(
          _db.ledgerEntries,
          LedgerEntriesCompanion.insert(
            accountId: newSourceId,
            deltaRial: -(newAmount.value + newFee.value),
            entryDate: newDate.stored,
            sourceType: LedgerSource.transferOut,
            sourceId: id,
            operationId: row.operationId,
            createdAt: now,
          ),
        );
        batch.insert(
          _db.ledgerEntries,
          LedgerEntriesCompanion.insert(
            accountId: newDestinationId,
            deltaRial: newAmount.value,
            entryDate: newDate.stored,
            sourceType: LedgerSource.transferIn,
            sourceId: id,
            operationId: row.operationId,
            createdAt: now,
          ),
        );
      });

      if (newFee > Rial.zero) {
        await _db
            .into(_db.transactions)
            .insert(
              TransactionsCompanion.insert(
                id: '${id}_fee',
                type: TransactionType.expense,
                amountRial: newFee.value,
                categoryId: const Value('cat_other_expense'),
                accountId: newSourceId,
                transactionDate: newDate.stored,
                description: Value(
                  'کارمزد انتقال${newDescription == null ? '' : ' — $newDescription'}',
                ),
                operationId: '${row.operationId}:fee',
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }

  Future<TransferRecord?> findById(String id) async {
    final source = _db.alias(_db.accounts, 'source_account');
    final destination = _db.alias(_db.accounts, 'destination_account');
    final query = _db.select(_db.transfers).join([
      innerJoin(source, source.id.equalsExp(_db.transfers.sourceAccountId)),
      innerJoin(
        destination,
        destination.id.equalsExp(_db.transfers.destinationAccountId),
      ),
    ])..where(_db.transfers.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _map(row, source, destination);
  }

  Future<List<TransferRecord>> list({int limit = 100}) async {
    final source = _db.alias(_db.accounts, 'source_account');
    final destination = _db.alias(_db.accounts, 'destination_account');
    final query =
        _db.select(_db.transfers).join([
            innerJoin(
              source,
              source.id.equalsExp(_db.transfers.sourceAccountId),
            ),
            innerJoin(
              destination,
              destination.id.equalsExp(_db.transfers.destinationAccountId),
            ),
          ])
          ..orderBy([OrderingTerm.desc(_db.transfers.transferDate)])
          ..limit(limit);
    final rows = await query.get();
    return rows.map((row) => _map(row, source, destination)).toList();
  }

  Stream<List<TransferRecord>> watch({int limit = 100}) {
    final source = _db.alias(_db.accounts, 'source_account');
    final destination = _db.alias(_db.accounts, 'destination_account');
    final query =
        _db.select(_db.transfers).join([
            innerJoin(
              source,
              source.id.equalsExp(_db.transfers.sourceAccountId),
            ),
            innerJoin(
              destination,
              destination.id.equalsExp(_db.transfers.destinationAccountId),
            ),
          ])
          ..orderBy([OrderingTerm.desc(_db.transfers.transferDate)])
          ..limit(limit);
    return query.watch().map(
      (rows) => rows.map((row) => _map(row, source, destination)).toList(),
    );
  }

  Future<void> delete(String id) async {
    final transfer = await findById(id);
    if (transfer == null) throw const NotFoundException('انتقال پیدا نشد.');
    await _db.transaction(() async {
      await (_db.delete(
        _db.ledgerEntries,
      )..where((table) => table.sourceId.equals(id))).go();
      await (_db.delete(
        _db.transactions,
      )..where((table) => table.id.equals('${id}_fee'))).go();
      await (_db.delete(
        _db.transfers,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  TransferRecord _map(
    TypedResult row,
    $AccountsTable sourceTable,
    $AccountsTable destinationTable,
  ) {
    final transfer = row.readTable(_db.transfers);
    final source = row.readTable(sourceTable);
    final destination = row.readTable(destinationTable);
    return transfer.toDomain(
      sourceAccountName: source.accountName,
      destinationAccountName: destination.accountName,
    );
  }

  Future<Account> _account(String id) async {
    final row = await (_db.select(
      _db.accounts,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (row == null) throw const NotFoundException('حساب انتخاب‌شده پیدا نشد.');
    if (row.archivedAt != null) {
      throw const ValidationException('حساب انتخاب‌شده بایگانی شده است.');
    }
    return row.toDomain();
  }
}
