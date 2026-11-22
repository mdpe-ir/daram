import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/mappers.dart';
import '../domain/chat_models.dart';

/// Persists conversations, messages and financial drafts.
class ChatRepository {
  ChatRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  static const String defaultTitle = 'گفتگوی جدید';

  Future<List<ChatSession>> listSessions() async {
    final sessions = await (_db.select(
      _db.chatSessions,
    )..orderBy([(table) => OrderingTerm.desc(table.updatedAt)])).get();
    if (sessions.isEmpty) return const [];

    final messages = await (_db.select(
      _db.chatMessages,
    )..orderBy([(table) => OrderingTerm.asc(table.sequence)])).get();
    final counts = <String, int>{};
    final previews = <String, String>{};
    for (final message in messages) {
      counts[message.sessionId] = (counts[message.sessionId] ?? 0) + 1;
      if (message.role == ChatRole.user) {
        previews[message.sessionId] = message.content;
      }
    }
    return [
      for (final session in sessions)
        session.toDomain(
          messageCount: counts[session.id] ?? 0,
          preview: previews[session.id],
        ),
    ];
  }

  Stream<List<ChatSession>> watchSessions() {
    return _db
        .customSelect(
          'SELECT id FROM chat_sessions',
          readsFrom: {_db.chatSessions, _db.chatMessages},
        )
        .watch()
        .asyncMap((_) => listSessions());
  }

  Future<ChatSession?> findSession(String id) async {
    final row = await (_db.select(
      _db.chatSessions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<ChatSession> createSession({String? title, String? id}) async {
    final now = DateTime.now().toUtc();
    final sessionId = id ?? _uuid.v4();
    final sessionTitle = (title?.trim().isNotEmpty ?? false)
        ? title!.trim()
        : defaultTitle;
    await _db
        .into(_db.chatSessions)
        .insert(
          ChatSessionsCompanion.insert(
            id: sessionId,
            title: sessionTitle,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return ChatSession(
      id: sessionId,
      title: sessionTitle,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> renameSession(String id, String title) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw const ValidationException('عنوان گفتگو نمی‌تواند خالی باشد.');
    }
    await (_db.update(
      _db.chatSessions,
    )..where((table) => table.id.equals(id))).write(
      ChatSessionsCompanion(
        title: Value(trimmed),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> touchSession(String id) async {
    await (_db.update(_db.chatSessions)..where((table) => table.id.equals(id)))
        .write(ChatSessionsCompanion(updatedAt: Value(DateTime.now().toUtc())));
  }

  Future<void> deleteSession(String id) async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.pendingActions,
      )..where((table) => table.sessionId.equals(id))).go();
      await (_db.delete(
        _db.chatMessages,
      )..where((table) => table.sessionId.equals(id))).go();
      await (_db.delete(
        _db.chatSessions,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<List<ChatMessage>> messages(String sessionId) async {
    final rows =
        await (_db.select(_db.chatMessages)
              ..where((table) => table.sessionId.equals(sessionId))
              ..orderBy([
                (table) => OrderingTerm.asc(table.sequence),
                (table) => OrderingTerm.asc(table.createdAt),
              ]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Stream<List<ChatMessage>> watchMessages(String sessionId) {
    return (_db.select(_db.chatMessages)
          ..where((table) => table.sessionId.equals(sessionId))
          ..orderBy([
            (table) => OrderingTerm.asc(table.sequence),
            (table) => OrderingTerm.asc(table.createdAt),
          ]))
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  Future<ChatMessage> addMessage({
    required String sessionId,
    required ChatRole role,
    required String content,
    required ChatMessageType type,
    Map<String, Object?> metadata = const {},
    String? id,
  }) async {
    final now = DateTime.now().toUtc();
    final message = ChatMessage(
      id: id ?? _uuid.v4(),
      sessionId: sessionId,
      role: role,
      content: content,
      type: type,
      metadata: metadata,
      createdAt: now,
    );
    await _db.transaction(() async {
      final maxSequence = await _db
          .customSelect(
            'SELECT COALESCE(MAX(sequence), 0) AS max_sequence '
            'FROM chat_messages WHERE session_id = ?',
            variables: [Variable.withString(sessionId)],
            readsFrom: {_db.chatMessages},
          )
          .getSingle();
      final sequence = maxSequence.read<int>('max_sequence') + 1;
      await _db
          .into(_db.chatMessages)
          .insert(
            ChatMessagesCompanion.insert(
              id: message.id,
              sessionId: sessionId,
              role: role,
              content: content,
              messageType: type,
              metadataJson: Value(jsonEncode(metadata)),
              sequence: Value(sequence),
              createdAt: now,
            ),
          );
      await touchSession(sessionId);
    });
    return message;
  }

  Future<void> updateMessage(
    String id, {
    String? content,
    ChatMessageType? type,
    Map<String, Object?>? metadata,
  }) async {
    await (_db.update(
      _db.chatMessages,
    )..where((table) => table.id.equals(id))).write(
      ChatMessagesCompanion(
        content: content == null ? const Value.absent() : Value(content),
        messageType: type == null ? const Value.absent() : Value(type),
        metadataJson: metadata == null
            ? const Value.absent()
            : Value(jsonEncode(metadata)),
      ),
    );
  }

  Future<void> deleteMessage(String id) async {
    await (_db.delete(
      _db.chatMessages,
    )..where((table) => table.id.equals(id))).go();
  }

  Future<void> addAssistantReply({
    required String sessionId,
    required String content,
    required ChatMessageType type,
    required Map<String, Object?> metadata,
    required List<PendingAction> actions,
  }) => _db.transaction(() async {
    final message = await addMessage(
      sessionId: sessionId,
      role: ChatRole.assistant,
      content: content,
      type: type,
      metadata: metadata,
    );
    await addPendingActions([
      for (final action in actions)
        action.copyWith(messageId: message.id, sessionId: sessionId),
    ]);
  });

  Future<void> addPendingActions(List<PendingAction> actions) async {
    if (actions.isEmpty) return;
    await _db.batch((batch) {
      batch.insertAll(_db.pendingActions, [
        for (final action in actions)
          PendingActionsCompanion.insert(
            id: action.id,
            sessionId: action.sessionId,
            messageId: Value(action.messageId),
            actionType: action.actionType,
            payloadJson: jsonEncode(action.payload),
            status: action.status,
            operationId: action.operationId,
            createdAt: action.createdAt,
          ),
      ]);
    });
  }

  Future<PendingAction?> findPendingAction(String id) async {
    final row = await (_db.select(
      _db.pendingActions,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row?.toDomain();
  }

  Future<List<PendingAction>> pendingActionsForMessage(String messageId) async {
    final rows =
        await (_db.select(_db.pendingActions)
              ..where((table) => table.messageId.equals(messageId))
              ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  Future<List<PendingAction>> pendingActionsForSession(String sessionId) async {
    final rows =
        await (_db.select(_db.pendingActions)
              ..where((table) => table.sessionId.equals(sessionId))
              ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]))
            .get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Whether an assistant message in [sessionId] already showed [suggestionId]
  /// to the user. SMS decisions are only allowed after that.
  Future<bool> hasPresentedSmsSuggestion({
    required String sessionId,
    required String suggestionId,
  }) async {
    final rows =
        await (_db.select(_db.chatMessages)..where(
              (table) =>
                  table.sessionId.equals(sessionId) &
                  table.role.equalsValue(ChatRole.assistant),
            ))
            .get();
    for (final row in rows) {
      final ids = decodeMetadata(row.metadataJson)['smsSuggestionIds'];
      if (ids is List && ids.any((item) => '$item' == suggestionId)) {
        return true;
      }
    }
    return false;
  }

  Future<void> updatePendingAction(PendingAction action) async {
    await (_db.update(
      _db.pendingActions,
    )..where((table) => table.id.equals(action.id))).write(
      PendingActionsCompanion(
        payloadJson: Value(jsonEncode(action.payload)),
        status: Value(action.status),
        errorMessage: Value(action.errorMessage),
        resolvedAt: Value(action.resolvedAt),
      ),
    );
  }
}
