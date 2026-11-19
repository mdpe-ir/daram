import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'database_platform_web.dart'
    if (dart.library.io) 'database_platform_io.dart';

import '../../core/domain/enums.dart';
import 'tables/chat_tables.dart';
import 'tables/financial_tables.dart';
import 'tables/sms_tables.dart';

part 'app_database.g.dart';

/// DARAM's local SQLite database.
///
/// All money is stored as integer Rial, all dates as UTC values, and every
/// balance movement goes through [LedgerEntries]. The app is local-first: no
/// backend, no account, no cloud.
@DriftDatabase(
  tables: [
    Accounts,
    Categories,
    Transactions,
    Transfers,
    LedgerEntries,
    Loans,
    Installments,
    ChatSessions,
    ChatMessages,
    PendingActions,
    FinancialOperations,
    SmsSenderLinks,
    SmsSuggestions,
    SmsPatterns,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens the local database.
  ///
  /// Native platforms use a SQLite file; the web uses drift's WASM runtime
  /// with IndexedDB/OPFS persistence. `web/sqlite3.wasm` and
  /// `web/drift_worker.js` are bundled for the browser build.
  factory AppDatabase.production() => AppDatabase(
    driftDatabase(
      name: 'daram',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
        onResult: (result) {
          if (!kReleaseMode) {
            debugPrint(
              'DARAM drift web implementation: ${result.chosenImplementation} '
              'missing: ${result.missingFeatures}',
            );
          }
        },
      ),
    ),
  );

  /// In-memory database used by tests on native platforms.
  factory AppDatabase.memory() => AppDatabase(createMemoryExecutor());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(chatMessages, chatMessages.sequence);
      }
      if (from < 3) {
        await migrator.createTable(smsSenderLinks);
        await migrator.createTable(smsSuggestions);
        await migrator.createTable(smsPatterns);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
