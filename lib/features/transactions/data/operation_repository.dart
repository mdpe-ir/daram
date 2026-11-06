import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/domain/enums.dart';
import '../../chat/domain/chat_models.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/mappers.dart';

/// Append-only journal of financial operations.
///
/// The journal is what makes idempotent writes and undo possible: every write
/// records one row keyed by the operation id before it is considered applied.
class OperationRepository {
  OperationRepository(this._db);

  final AppDatabase _db;

  /// Returns the journal entry for [operationId], if the operation already ran.
  Future<FinancialOperation?> find(String operationId) async {
    final row = await (_db.select(
      _db.financialOperations,
    )..where((table) => table.id.equals(operationId))).getSingleOrNull();
    return row?.toDomain();
  }

  /// Records an applied operation inside the caller's transaction.
  Future<void> record({
    required String operationId,
    required FinancialOperationKind kind,
    required String entityId,
    required String summary,
    Map<String, Object?> payload = const {},
  }) async {
    await _db
        .into(_db.financialOperations)
        .insert(
          FinancialOperationsCompanion.insert(
            id: operationId,
            kind: kind,
            entityId: entityId,
            summary: summary,
            payloadJson: Value(jsonEncode(payload)),
            createdAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Marks an operation as undone so it cannot be undone twice.
  Future<void> markUndone(String operationId) async {
    await (_db.update(
      _db.financialOperations,
    )..where((table) => table.id.equals(operationId))).write(
      FinancialOperationsCompanion(
        status: const Value('undone'),
        undoneAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Recent operations for the history view.
  Future<List<FinancialOperation>> recent({int limit = 30}) async {
    final rows =
        await (_db.select(_db.financialOperations)
              ..orderBy([(table) => OrderingTerm.desc(table.createdAt)])
              ..limit(limit))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<List<FinancialOperation>> all() async {
    final rows = await (_db.select(
      _db.financialOperations,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).get();
    return rows.map((row) => row.toDomain()).toList();
  }
}
