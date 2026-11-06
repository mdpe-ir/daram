import 'package:drift/drift.dart';

import '../../../core/domain/enums.dart';

/// A conversation with DARAM.
@DataClassName('ChatSessionRow')
@TableIndex(name: 'idx_chat_sessions_updated', columns: {#updatedAt})
class ChatSessions extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A single persisted chat message.
@DataClassName('ChatMessageRow')
@TableIndex(
  name: 'idx_chat_messages_session',
  columns: {#sessionId, #createdAt},
)
class ChatMessages extends Table {
  TextColumn get id => text()();
  @ReferenceName('messages')
  TextColumn get sessionId => text().references(ChatSessions, #id)();
  TextColumn get role => textEnum<ChatRole>()();
  TextColumn get content => text()();
  TextColumn get messageType => textEnum<ChatMessageType>()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();

  /// Monotonic per-session ordering. SQLite/Dart timestamps are not precise
  /// enough to order rapid assistant/user messages deterministically.
  IntColumn get sequence => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Financial drafts proposed by the AI and awaiting explicit user approval.
@DataClassName('PendingActionRow')
@TableIndex(name: 'idx_pending_session', columns: {#sessionId})
@TableIndex(name: 'idx_pending_status', columns: {#status})
class PendingActions extends Table {
  TextColumn get id => text()();
  @ReferenceName('pendingActions')
  TextColumn get sessionId => text().references(ChatSessions, #id)();
  TextColumn get messageId => text().nullable()();
  TextColumn get actionType => text()();
  TextColumn get payloadJson => text()();
  TextColumn get status => textEnum<PendingActionStatus>()();
  TextColumn get operationId => text().unique()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Journal of applied financial operations, used for undo and audit.
@DataClassName('FinancialOperationRow')
@TableIndex(name: 'idx_operations_created', columns: {#createdAt})
class FinancialOperations extends Table {
  TextColumn get id => text()();
  TextColumn get kind => textEnum<FinancialOperationKind>()();
  TextColumn get entityId => text()();
  TextColumn get summary => text()();
  TextColumn get payloadJson => text().withDefault(const Constant('{}'))();
  TextColumn get status => text().withDefault(const Constant('applied'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get undoneAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
