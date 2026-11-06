import 'dart:convert';

import 'package:meta/meta.dart';

import '../../../core/domain/enums.dart';

/// Decodes a JSON object stored in a text column, tolerating bad data.
Map<String, Object?> decodeMetadata(String? json) {
  if (json == null || json.isEmpty) return const <String, Object?>{};
  try {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, Object?>) return decoded;
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }
  } on FormatException {
    // Corrupt metadata must never crash the app; it is treated as empty.
  }
  return const <String, Object?>{};
}

/// Encodes a metadata map for storage.
String encodeMetadata(Map<String, Object?> data) => jsonEncode(data);

/// A persisted conversation.
@immutable
final class ChatSession {
  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messageCount = 0,
    this.preview,
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final String? preview;

  ChatSession copyWith({String? title, DateTime? updatedAt}) => ChatSession(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    messageCount: messageCount,
    preview: preview,
  );
}

/// A message shown in the conversation.
@immutable
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.type,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final ChatRole role;
  final String content;
  final ChatMessageType type;
  final Map<String, Object?> metadata;
  final DateTime createdAt;

  bool get isUser => role == ChatRole.user;
  bool get isAssistant => role == ChatRole.assistant;

  /// Ids of pending actions attached to this message.
  List<String> get pendingActionIds {
    final value = metadata['pendingActionIds'];
    if (value is List) return value.map((item) => '$item').toList();
    return const <String>[];
  }

  ChatMessage copyWith({
    String? content,
    ChatMessageType? type,
    Map<String, Object?>? metadata,
  }) => ChatMessage(
    id: id,
    sessionId: sessionId,
    role: role,
    content: content ?? this.content,
    type: type ?? this.type,
    metadata: metadata ?? this.metadata,
    createdAt: createdAt,
  );
}

/// A financial draft produced by an AI tool call.
///
/// The AI never writes to the financial tables directly. Each tool call
/// becomes one of these, and the user must explicitly confirm it.
@immutable
final class PendingAction {
  const PendingAction({
    required this.id,
    required this.sessionId,
    required this.actionType,
    required this.payload,
    required this.status,
    required this.operationId,
    required this.createdAt,
    this.messageId,
    this.errorMessage,
    this.resolvedAt,
  });

  final String id;
  final String sessionId;
  final String? messageId;

  /// Tool name such as `add_transaction`.
  final String actionType;

  /// Validated tool arguments (canonical: amounts in Rial, dates as ISO).
  final Map<String, Object?> payload;

  final PendingActionStatus status;
  final String operationId;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  bool get isPending => status == PendingActionStatus.pending;
  bool get isConfirmed => status == PendingActionStatus.confirmed;

  PendingAction copyWith({
    Map<String, Object?>? payload,
    PendingActionStatus? status,
    String? errorMessage,
    DateTime? resolvedAt,
    String? messageId,
    String? sessionId,
  }) => PendingAction(
    id: id,
    sessionId: sessionId ?? this.sessionId,
    messageId: messageId ?? this.messageId,
    actionType: actionType,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    operationId: operationId,
    errorMessage: errorMessage ?? this.errorMessage,
    createdAt: createdAt,
    resolvedAt: resolvedAt ?? this.resolvedAt,
  );
}

/// An applied financial operation that can be undone.
@immutable
final class FinancialOperation {
  const FinancialOperation({
    required this.id,
    required this.kind,
    required this.entityId,
    required this.summary,
    required this.payload,
    required this.status,
    required this.createdAt,
    this.undoneAt,
  });

  final String id;
  final FinancialOperationKind kind;
  final String entityId;
  final String summary;
  final Map<String, Object?> payload;
  final String status;
  final DateTime createdAt;
  final DateTime? undoneAt;

  bool get isUndone => undoneAt != null || status == 'undone';
}
