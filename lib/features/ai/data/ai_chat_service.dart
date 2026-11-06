import 'dart:convert';

import '../../../core/domain/enums.dart';
import '../../../core/money/currency.dart';
import '../../chat/domain/chat_models.dart';
import '../domain/ai_models.dart';
import '../domain/tool.dart';
import 'ai_provider_registry.dart';
import 'tool_executor.dart';
import 'tool_registry.dart';

/// Events produced while running one assistant turn.
sealed class ChatRunEvent {
  const ChatRunEvent();
}

class ChatRunText extends ChatRunEvent {
  const ChatRunText(this.text);
  final String text;
}

class ChatRunCompleted extends ChatRunEvent {
  const ChatRunCompleted({
    required this.text,
    required this.actions,
    required this.reports,
  });

  final String text;
  final List<PendingAction> actions;
  final List<Map<String, Object?>> reports;
}

class ChatRunFailed extends ChatRunEvent {
  const ChatRunFailed(this.message);
  final String message;
}

/// Orchestrates the model ↔ tool loop.
///
/// The model can be given native tool calling or a strict JSON envelope. In
/// both cases the tools are executed through [ToolExecutor], which only creates
/// drafts; this service never persists financial data.
class AIChatService {
  AIChatService({
    required AIProviderRegistry providers,
    required ToolRegistry tools,
    required ToolExecutor executor,
  }) : _providers = providers,
       _tools = tools,
       _executor = executor;

  final AIProviderRegistry _providers;
  final ToolRegistry _tools;
  final ToolExecutor _executor;

  static const int _maxToolRounds = 3;
  static const int _maxHistoryMessages = 24;

  Stream<ChatRunEvent> run({
    required AIConfig config,
    required String systemPrompt,
    required List<ChatMessage> history,
    required String userMessage,
    required String sessionId,
    required CurrencyUnit defaultCurrency,
  }) async* {
    final configurationError = config.validate();
    if (configurationError != null) {
      yield ChatRunFailed(configurationError);
      return;
    }

    final messages = <AIMessage>[
      AIMessage.system(systemPrompt),
      ..._historyMessages(history),
      AIMessage.user(userMessage),
    ];

    if (config.toolMode == AIToolMode.json) {
      yield* _runJsonMode(
        config: config,
        messages: messages,
        sessionId: sessionId,
        defaultCurrency: defaultCurrency,
      );
      return;
    }

    yield* _runNativeMode(
      config: config,
      messages: messages,
      sessionId: sessionId,
      defaultCurrency: defaultCurrency,
    );
  }

  Stream<ChatRunEvent> _runNativeMode({
    required AIConfig config,
    required List<AIMessage> messages,
    required String sessionId,
    required CurrencyUnit defaultCurrency,
  }) async* {
    final provider = _providers.forKind(config.provider);
    final allText = StringBuffer();
    final actions = <PendingAction>[];
    final reports = <Map<String, Object?>>[];
    final seenPayloads = <String>{};

    for (var round = 0; round < _maxToolRounds; round++) {
      final roundText = StringBuffer();
      var toolCalls = <ToolCall>[];
      var failed = false;

      await for (final event in provider.streamChat(
        config: config,
        messages: messages,
        tools: _tools.definitions,
      )) {
        switch (event) {
          case AIStreamText(:final text):
            roundText.write(text);
            yield ChatRunText(text);
          case AIStreamToolCalls(:final calls):
            toolCalls = calls;
          case AIStreamError(:final message):
            yield ChatRunFailed(message);
            failed = true;
          case AIStreamDone():
            break;
        }
        if (failed) return;
      }

      final roundContent = roundText.toString().trim();
      if (roundContent.isNotEmpty) {
        if (allText.isNotEmpty) allText.write('\n\n');
        allText.write(roundContent);
      }
      if (toolCalls.isEmpty) {
        yield ChatRunCompleted(
          text: allText.toString().trim(),
          actions: actions,
          reports: reports,
        );
        return;
      }

      final resultMessages = <AIMessage>[];
      for (final call in toolCalls) {
        final execution = await _executor.execute(
          call,
          sessionId: sessionId,
          defaultCurrency: defaultCurrency,
        );
        if (execution.pendingAction != null) {
          final action = execution.pendingAction!;
          final key = '${action.actionType}:${jsonEncode(action.payload)}';
          if (seenPayloads.add(key)) actions.add(action);
        }
        if (execution.report != null) reports.add(execution.report!);
        resultMessages.add(
          AIMessage.toolResult(
            toolCallId: call.id,
            name: call.name,
            content: execution.content,
          ),
        );
      }

      messages
        ..add(AIMessage.assistant(roundContent, toolCalls: toolCalls))
        ..addAll(resultMessages);
    }

    yield ChatRunCompleted(
      text: allText.toString().trim(),
      actions: actions,
      reports: reports,
    );
  }

  Stream<ChatRunEvent> _runJsonMode({
    required AIConfig config,
    required List<AIMessage> messages,
    required String sessionId,
    required CurrencyUnit defaultCurrency,
  }) async* {
    final provider = _providers.forKind(config.provider);
    var attempt = 0;
    var envelope = <String, Object?>{};

    while (attempt < 2) {
      final buffer = StringBuffer();
      var failed = false;
      await for (final event in provider.streamChat(
        config: config,
        messages: messages,
        tools: _tools.definitions,
      )) {
        switch (event) {
          case AIStreamText(:final text):
            buffer.write(text);
          case AIStreamToolCalls():
            break;
          case AIStreamError(:final message):
            yield ChatRunFailed(message);
            failed = true;
          case AIStreamDone():
            break;
        }
        if (failed) return;
      }

      final parsed = _parseEnvelope(buffer.toString());
      if (parsed != null) {
        envelope = parsed;
        break;
      }
      attempt++;
      if (attempt >= 2) {
        yield const ChatRunFailed(
          'پاسخ مدل قابل خواندن نبود. لطفاً دوباره تلاش کن یا مدل دیگری انتخاب کن.',
        );
        return;
      }
      messages
        ..add(AIMessage.assistant(buffer.toString()))
        ..add(
          const AIMessage.user(
            'پاسخ قبلی JSON معتبر نبود. فقط یک شیء JSON با کلیدهای message و actions برگردان؛ بدون متن اضافه و بدون ```.',
          ),
        );
    }

    final text = (envelope['message'] ?? '').toString().trim();
    final rawActions = envelope['actions'] ?? envelope['tool_calls'];
    final actions = <PendingAction>[];
    final reports = <Map<String, Object?>>[];
    final calls = <ToolCall>[];

    if (rawActions is List) {
      for (var i = 0; i < rawActions.length; i++) {
        final raw = rawActions[i];
        if (raw is! Map) continue;
        final name = (raw['tool'] ?? raw['name'])?.toString();
        if (name == null || DaramTool.fromName(name) == null) continue;
        final arguments = raw['arguments'] ?? raw['args'];
        calls.add(
          ToolCall(
            id: 'json_call_$i',
            name: name,
            arguments: arguments is Map
                ? arguments.map((key, value) => MapEntry('$key', value))
                : const {},
            rawArguments: arguments is Map ? jsonEncode(arguments) : '{}',
          ),
        );
      }
    }

    for (final call in calls) {
      final execution = await _executor.execute(
        call,
        sessionId: sessionId,
        defaultCurrency: defaultCurrency,
      );
      if (execution.pendingAction != null) {
        actions.add(execution.pendingAction!);
      }
      if (execution.report != null) reports.add(execution.report!);
    }

    yield ChatRunCompleted(
      text: text.isEmpty ? 'پیش‌نویس آماده شد؛ لطفاً بررسی و تأیید کن.' : text,
      actions: actions,
      reports: reports,
    );
  }

  List<AIMessage> _historyMessages(List<ChatMessage> history) {
    final recent = history.length > _maxHistoryMessages
        ? history.sublist(history.length - _maxHistoryMessages)
        : history;
    return [
      for (final message in recent)
        if (message.content.trim().isNotEmpty)
          if (message.role == ChatRole.user)
            AIMessage.user(message.content)
          else if (message.role == ChatRole.assistant &&
              message.type != ChatMessageType.error)
            AIMessage.assistant(message.content),
    ];
  }

  Map<String, Object?>? _parseEnvelope(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return null;
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(text);
    if (fence != null) text = fence.group(1)!.trim();
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end <= start) return null;
    try {
      final decoded = jsonDecode(text.substring(start, end + 1));
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
