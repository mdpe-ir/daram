import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/time/calendar_date.dart';
import '../../../data/database/app_database.dart';
import '../../chat/domain/drafts.dart';
import '../../transactions/data/transaction_repository.dart';
import '../domain/sms_message.dart';

class SmsReviewRepository {
  SmsReviewRepository(this._db, this._transactions);

  final AppDatabase _db;
  final TransactionRepository _transactions;

  static const openStatuses = {'pending', 'needsReview', 'possibleDuplicate'};

  static String patternKey(String sender, String template) =>
      const Uuid().v5(Namespace.url.value, jsonEncode([sender, template]));

  static String recurringKey(
    String pattern,
    String accountId,
    TransactionType type,
    int amount,
  ) => 'recurring:$pattern:$accountId:${type.name}:$amount';

  Future<Set<(String, int, TransactionType, int)>> manualTransactionKeys(
    DateTime since,
  ) async {
    final date = CalendarDate.fromDateTime(since.toLocal()).stored;
    final rows =
        await (_db.select(_db.transactions)..where(
              (row) =>
                  row.transactionDate.isBiggerOrEqualValue(date) &
                  (row.operationId.isNull() |
                      row.operationId.like('sms:%').not()),
            ))
            .get();
    return {
      for (final row in rows)
        (
          row.accountId,
          row.transactionDate.millisecondsSinceEpoch,
          row.type,
          row.amountRial,
        ),
    };
  }

  Future<List<SmsSenderLink>> links() => _db.select(_db.smsSenderLinks).get();

  Future<Set<String>> dismissedSenders() async => {
    for (final row in await _db.select(_db.smsSenderDismissals).get())
      row.sender,
  };

  Future<void> dismissSender(String sender) async {
    await _db
        .into(_db.smsSenderDismissals)
        .insertOnConflictUpdate(SmsSenderDismissal(sender: sender));
  }

  Future<void> setSenders(
    String accountId,
    Set<String> senders, {
    required bool includeHistory,
  }) => _db.transaction(() async {
    final existing = await (_db.select(
      _db.smsSenderLinks,
    )..where((link) => link.accountId.equals(accountId))).get();
    final removed = existing
        .map((link) => link.sender)
        .toSet()
        .difference(senders);
    if (removed.isNotEmpty) {
      await (_db.delete(_db.smsSenderLinks)..where(
            (link) =>
                link.accountId.equals(accountId) & link.sender.isIn(removed),
          ))
          .go();
      // Unlinking removes outstanding drafts for this account. Resolved SMS
      // markers survive so a later re-link cannot import them twice.
      final drafts = await _openSuggestions().get();
      final ids = drafts
          .where(
            (row) =>
                removed.contains(row.sender) &&
                draftOf(row).accountId == accountId,
          )
          .map((row) => row.id)
          .toList();
      if (ids.isNotEmpty) {
        await (_db.delete(
          _db.smsSuggestions,
        )..where((row) => row.id.isIn(ids))).go();
      }
    }

    final previous = {for (final link in existing) link.sender: link};
    final now = DateTime.now().toUtc();
    final since = includeHistory ? now.subtract(const Duration(days: 30)) : now;
    for (final sender in senders) {
      final link = previous[sender];
      if (link != null &&
          (!includeHistory || !since.isBefore(link.importFrom))) {
        continue;
      }
      await _db
          .into(_db.smsSenderLinks)
          .insertOnConflictUpdate(
            SmsSenderLinksCompanion.insert(
              sender: sender,
              accountId: accountId,
              importFrom: since,
            ),
          );
    }
  });

  SimpleSelectStatement<$SmsSuggestionsTable, SmsSuggestionRow>
  _openSuggestions() => _db.select(_db.smsSuggestions)
    ..where((row) => row.status.isIn(openStatuses))
    ..orderBy([(row) => OrderingTerm.desc(row.receivedAt)]);

  Stream<List<SmsSuggestionRow>> watchOpen() => _openSuggestions().watch();

  Future<List<SmsSuggestionRow>> open() => _openSuggestions().get();

  Future<List<SmsSuggestionRow>> suggestionsSince(DateTime since) =>
      (_db.select(
        _db.smsSuggestions,
      )..where((row) => row.receivedAt.isBiggerOrEqualValue(since))).get();

  /// Finds a suggestion regardless of its status (used by chat cards).
  Future<SmsSuggestionRow?> find(String id) => (_db.select(
    _db.smsSuggestions,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  /// Watches one suggestion so cards in chat reflect confirm/dismiss instantly.
  Stream<SmsSuggestionRow?> watch(String id) => (_db.select(
    _db.smsSuggestions,
  )..where((row) => row.id.equals(id))).watchSingleOrNull();

  static TransactionDraft draftOf(SmsSuggestionRow row) =>
      TransactionDraft.fromPayload(
        jsonDecode(row.payload) as Map<String, Object?>,
      );

  /// Whether a suggestion has every field needed for a one-tap confirmation.
  static bool isReady(
    SmsSuggestionRow row, {
    required Set<String> accountIds,
    required Set<String> categoryIds,
  }) {
    if (row.status != 'pending') return false;
    final draft = draftOf(row);
    return draft.accountId.isNotEmpty &&
        !draft.amountRial.isZero &&
        accountIds.contains(draft.accountId) &&
        (draft.categoryId == null || categoryIds.contains(draft.categoryId));
  }

  /// Applies edits to the draft behind an SMS suggestion without confirming it.
  ///
  /// A suggestion that only lacked an amount or account moves back to
  /// `pending` once both are present, so the user can confirm it normally. The
  /// duplicate warning is cleared by an explicit edit, matching the SMS screen's
  /// edit-and-confirm flow.
  Future<void> updateDraft(String id, TransactionDraft draft) =>
      _db.transaction(() async {
        final row = await _getOpen(id);
        if (row == null) {
          throw const NotFoundException(
            'این پیشنهاد پیامکی دیگر در انتظار بازبینی نیست.',
          );
        }
        final ready = draft.accountId.isNotEmpty && !draft.amountRial.isZero;
        final promotable =
            row.status == 'needsReview' || row.status == 'possibleDuplicate';
        await (_db.update(
          _db.smsSuggestions,
        )..where((item) => item.id.equals(id))).write(
          SmsSuggestionsCompanion(
            payload: Value(jsonEncode(draft.toPayload())),
            status: promotable && ready
                ? const Value('pending')
                : const Value.absent(),
            editedAt: Value(DateTime.now().toUtc()),
          ),
        );
      });

  Future<Map<String, Map<String, Object?>>> patterns() async => {
    for (final row in await _db.select(_db.smsPatterns).get())
      row.key: jsonDecode(row.rule) as Map<String, Object?>,
  };

  Future<void> _remember(String key, Map<String, Object?> value) => _db
      .into(_db.smsPatterns)
      .insertOnConflictUpdate(
        SmsPatternsCompanion.insert(key: key, rule: jsonEncode(value)),
      );

  Future<void> saveScan({
    required List<SmsSuggestionRow> suggestions,
    required Map<String, SmsRule> inferred,
    required List<SmsSenderLink> scannedLinks,
  }) => _db.transaction(() async {
    final currentLinks = await links();
    final live = {
      for (final link in currentLinks)
        (link.sender, link.accountId, link.importFrom),
    };
    final original = {
      for (final link in scannedLinks)
        (link.sender, link.accountId, link.importFrom),
    };
    if (live.length != original.length || !live.containsAll(original)) return;

    for (final entry in inferred.entries) {
      await _db
          .into(_db.smsPatterns)
          .insert(
            SmsPatternsCompanion.insert(
              key: entry.key,
              rule: jsonEncode(entry.value.toJson()),
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }
    final incoming = {
      for (final suggestion in suggestions) suggestion.id: suggestion,
    };
    for (final suggestion in suggestions) {
      final existing = await (_db.select(
        _db.smsSuggestions,
      )..where((row) => row.id.equals(suggestion.id))).getSingleOrNull();
      if (existing != null && !openStatuses.contains(existing.status)) {
        continue;
      }
      if (existing != null && existing.editedAt != null) {
        // The user or assistant already edited this draft. A later inbox scan
        // must not silently revert the category/description/amount they saw.
        continue;
      }
      if (suggestion.contextMessageId != null) {
        final used =
            await (_db.select(_db.smsSuggestions)..where(
                  (row) =>
                      row.contextMessageId.equals(suggestion.contextMessageId!),
                ))
                .getSingleOrNull();
        if (used != null && used.id != suggestion.id) {
          final updated = incoming[used.id];
          if (!openStatuses.contains(used.status) ||
              updated == null ||
              updated.contextMessageId == used.contextMessageId) {
            continue;
          }
          await _setStatus(used, used.status, releaseContext: true);
        }
      }
      if (existing != suggestion) {
        await _db
            .into(_db.smsSuggestions)
            .insertOnConflictUpdate(suggestion.toCompanion(false));
      }
    }
  });

  Future<void> confirm(String id, {TransactionDraft? edited}) =>
      _db.transaction(() async {
        final row = await _getOpen(id);
        if (row == null) return;
        final original = draftOf(row);
        final draft = edited ?? original;
        if ((row.status != 'pending' && edited == null) ||
            draft.accountId.isEmpty ||
            draft.amountRial.isZero) {
          throw const ValidationException('مبلغ و حساب این پیامک را بررسی کن.');
        }
        await _transactions.create(
          type: draft.type,
          amount: draft.amountRial,
          accountId: draft.accountId,
          date: draft.date,
          operationId: 'sms:$id',
          categoryId: draft.categoryId,
          description: draft.description,
        );
        await _setStatus(row, 'confirmed');
        if (original.type != draft.type &&
            original.amountRial == draft.amountRial) {
          final key = patternKey(row.sender, row.template);
          await _remember('direction:$key', {'type': draft.type.name});
        }
        final contextKey = row.contextKey;
        if (contextKey != null) {
          await _remember('context:$contextKey:${draft.type.name}', {
            'categoryId': draft.categoryId,
            'description': draft.description,
          });
        }
        if (contextKey == null &&
            edited != null &&
            draft.accountId == original.accountId &&
            draft.amountRial == original.amountRial &&
            draft.type == original.type &&
            (draft.categoryId != original.categoryId ||
                draft.description != original.description)) {
          final key = recurringKey(
            patternKey(row.sender, row.template),
            draft.accountId,
            draft.type,
            draft.amountRial.value,
          );
          final old = await (_db.select(
            _db.smsPatterns,
          )..where((item) => item.key.equals(key))).getSingleOrNull();
          final value = old == null
              ? null
              : jsonDecode(old.rule) as Map<String, Object?>;
          final matching =
              value?['categoryId'] == draft.categoryId &&
              value?['description'] == draft.description;
          await _remember(key, {
            'categoryId': draft.categoryId,
            'description': draft.description,
            'count': matching ? (value?['count'] as int? ?? 0) + 1 : 1,
          });
        }
      });

  Future<void> dismiss(String id, {bool ignorePattern = false}) =>
      _db.transaction(() async {
        final row = await _getOpen(id);
        if (row == null) return;
        await _setStatus(row, 'dismissed', releaseContext: true);
        if (!ignorePattern) return;
        final key = patternKey(row.sender, row.template);
        await _remember('ignore:$key', const {'ignore': true});
        await (_db.update(_db.smsSuggestions)..where(
              (other) =>
                  other.sender.equals(row.sender) &
                  other.template.equals(row.template) &
                  other.status.isIn(openStatuses),
            ))
            .write(
              const SmsSuggestionsCompanion(
                status: Value('dismissed'),
                contextMessageId: Value(null),
              ),
            );
      });

  Future<SmsSuggestionRow?> _getOpen(String id) =>
      (_openSuggestions()..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<void> _setStatus(
    SmsSuggestionRow row,
    String status, {
    bool releaseContext = false,
  }) =>
      (_db.update(
        _db.smsSuggestions,
      )..where((item) => item.id.equals(row.id))).write(
        SmsSuggestionsCompanion(
          status: Value(status),
          contextMessageId: releaseContext
              ? const Value(null)
              : const Value.absent(),
        ),
      );
}
