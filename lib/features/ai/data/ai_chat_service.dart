import 'dart:convert';

import '../../../core/domain/enums.dart';
import '../../../core/money/currency.dart';
import '../../chat/domain/chat_models.dart';
import '../domain/ai_log.dart';
import '../domain/ai_models.dart';
import '../domain/tool.dart';
import 'ai_log_store.dart';
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
    this.smsSuggestionIds = const <String>[],
  });

  final String text;
  final List<PendingAction> actions;
  final List<Map<String, Object?>> reports;

  /// SMS suggestions shown during this turn, rendered as cards in chat.
  final List<String> smsSuggestionIds;
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
    AILogStore? logs,
  }) : _providers = providers,
       _tools = tools,
       _executor = executor,
       _logs = logs ?? AILogStore.silent();

  final AIProviderRegistry _providers;
  final ToolRegistry _tools;
  final ToolExecutor _executor;
  final AILogStore _logs;

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
    _logs.info(
      'شروع درخواست دستیار',
      area: AILogArea.chat,
      provider: config.provider.label,
      model: config.model,
      detail:
          'endpoint: ${config.chatEndpoint()}\n'
          'mode: ${config.toolMode.name}\n'
          'history: ${history.length}\n'
          'userChars: ${userMessage.length}\n'
          'tools: ${_tools.definitions.length}',
    );
    final configurationError = config.validate();
    if (configurationError != null) {
      _logs.error(
        'تنظیمات دستیار کامل نیست',
        area: AILogArea.chat,
        provider: config.provider.label,
        model: config.model,
        detail: configurationError,
      );
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
    final smsIds = <String>{};
    final previousCounts = <String, int>{};
    final runWatch = Stopwatch()..start();

    for (var round = 0; round < _maxToolRounds; round++) {
      final roundWatch = Stopwatch()..start();
      final roundText = StringBuffer();
      final toolCalls = <ToolCall>[];
      String? failure;
      String? roundFinishReason;

      await for (final event in provider.streamChat(
        config: config,
        messages: messages,
        tools: _tools.definitions,
        sessionId: sessionId,
      )) {
        switch (event) {
          case AIStreamText(:final text):
            roundText.write(text);
            yield ChatRunText(text);
          case AIStreamToolCalls(:final calls):
            for (final call in calls) {
              if (!toolCalls.any((seen) => seen.id == call.id)) {
                toolCalls.add(call);
              }
            }
          case AIStreamError(:final message):
            failure = message;
            break;
          case AIStreamDone(:final finishReason):
            roundFinishReason = finishReason;
            break;
        }
        if (failure != null) break;
      }
      if (failure != null) {
        _logs.error(
          'دور ${round + 1} دستیار ناموفق بود',
          area: AILogArea.chat,
          provider: config.provider.label,
          model: config.model,
          durationMs: roundWatch.elapsedMilliseconds,
          detail: 'round: ${round + 1}\nmessage: $failure',
        );
        if (actions.isEmpty && reports.isEmpty) {
          yield ChatRunFailed(failure);
        } else {
          yield ChatRunCompleted(
            text: 'موارد آماده را بررسی کن. تکمیل پاسخ به مشکل خورد. $failure',
            actions: actions,
            reports: reports,
            smsSuggestionIds: smsIds.toList(),
          );
        }
        return;
      }

      final roundContent = roundText.toString().trim();
      _logs.info(
        'پاسخ دور ${round + 1} دریافت شد',
        area: AILogArea.chat,
        provider: config.provider.label,
        model: config.model,
        durationMs: roundWatch.elapsedMilliseconds,
        detail:
            'chars: ${roundContent.length}\n'
            'finishReason: ${roundFinishReason ?? '-'}\n'
            'toolCalls: ${toolCalls.length}',
      );
      if (roundContent.isNotEmpty) {
        if (allText.isNotEmpty) allText.write('\n\n');
        allText.write(roundContent);
      }
      if (toolCalls.isEmpty) {
        _logTurnResult(
          config: config,
          text: allText.toString().trim(),
          actionCount: actions.length,
          reportCount: reports.length,
          rounds: round + 1,
          durationMs: runWatch.elapsedMilliseconds,
        );
        yield ChatRunCompleted(
          text: allText.toString().trim(),
          actions: actions,
          reports: reports,
          smsSuggestionIds: smsIds.toList(),
        );
        return;
      }

      final resultMessages = <AIMessage>[];
      final roundCounts = <String, int>{};
      for (final call in toolCalls) {
        final toolWatch = Stopwatch()..start();
        final execution = await _executor.execute(
          call,
          sessionId: sessionId,
          defaultCurrency: defaultCurrency,
        );
        _logs.record(
          level: execution.ok ? AILogLevel.info : AILogLevel.warning,
          area: AILogArea.tool,
          title: 'اجرای ابزار ${call.name}',
          provider: config.provider.label,
          model: config.model,
          durationMs: toolWatch.elapsedMilliseconds,
          detail:
              'ok: ${execution.ok}\n${truncateText(execution.content, 500)}',
        );
        if (execution.pendingAction != null) {
          final action = execution.pendingAction!;
          final key = '${action.actionType}:${jsonEncode(action.payload)}';
          final occurrence = roundCounts.update(
            key,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
          if (occurrence > (previousCounts[key] ?? 0)) actions.add(action);
        }
        if (execution.report != null) reports.add(execution.report!);
        smsIds.addAll(execution.smsSuggestionIds);
        resultMessages.add(
          AIMessage.toolResult(
            toolCallId: call.id,
            name: call.name,
            content: execution.content,
          ),
        );
      }

      for (final entry in roundCounts.entries) {
        if (entry.value > (previousCounts[entry.key] ?? 0)) {
          previousCounts[entry.key] = entry.value;
        }
      }
      messages
        ..add(AIMessage.assistant(roundContent, toolCalls: toolCalls))
        ..addAll(resultMessages);
    }

    _logs.warning(
      'حداکثر دور ابزار رسید',
      area: AILogArea.chat,
      provider: config.provider.label,
      model: config.model,
      durationMs: runWatch.elapsedMilliseconds,
      detail: 'rounds: $_maxToolRounds\nactions: ${actions.length}',
    );
    _logTurnResult(
      config: config,
      text: allText.toString().trim(),
      actionCount: actions.length,
      reportCount: reports.length,
      rounds: _maxToolRounds,
      durationMs: runWatch.elapsedMilliseconds,
    );
    yield ChatRunCompleted(
      text: allText.toString().trim(),
      actions: actions,
      reports: reports,
      smsSuggestionIds: smsIds.toList(),
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
    final runWatch = Stopwatch()..start();

    while (attempt < 2) {
      final buffer = StringBuffer();
      var failed = false;
      await for (final event in provider.streamChat(
        config: config,
        messages: messages,
        tools: _tools.definitions,
        sessionId: sessionId,
      )) {
        switch (event) {
          case AIStreamText(:final text):
            buffer.write(text);
          case AIStreamToolCalls():
            break;
          case AIStreamError(:final message):
            _logs.error(
              'پاسخ JSON ناموفق بود',
              area: AILogArea.chat,
              provider: config.provider.label,
              model: config.model,
              durationMs: runWatch.elapsedMilliseconds,
              detail: 'attempt: ${attempt + 1}\nmessage: $message',
            );
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
      _logs.warning(
        'خروجی مدل JSON معتبر نبود',
        area: AILogArea.chat,
        provider: config.provider.label,
        model: config.model,
        durationMs: runWatch.elapsedMilliseconds,
        detail: truncateText(buffer.toString(), 600),
      );
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
    final smsIds = <String>{};
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
      final toolWatch = Stopwatch()..start();
      final execution = await _executor.execute(
        call,
        sessionId: sessionId,
        defaultCurrency: defaultCurrency,
      );
      _logs.record(
        level: execution.ok ? AILogLevel.info : AILogLevel.warning,
        area: AILogArea.tool,
        title: 'اجرای ابزار ${call.name}',
        provider: config.provider.label,
        model: config.model,
        durationMs: toolWatch.elapsedMilliseconds,
        detail: 'ok: ${execution.ok}\n${truncateText(execution.content, 500)}',
      );
      if (execution.pendingAction != null) {
        actions.add(execution.pendingAction!);
      }
      if (execution.report != null) reports.add(execution.report!);
      smsIds.addAll(execution.smsSuggestionIds);
    }

    _logTurnResult(
      config: config,
      text: text,
      actionCount: actions.length,
      reportCount: reports.length,
      rounds: attempt + 1,
      durationMs: runWatch.elapsedMilliseconds,
    );
    yield ChatRunCompleted(
      text: text.isEmpty ? 'پیش‌نویس آماده شد؛ لطفاً بررسی و تأیید کن.' : text,
      actions: actions,
      reports: reports,
      smsSuggestionIds: smsIds.toList(),
    );
  }

  void _logTurnResult({
    required AIConfig config,
    required String text,
    required int actionCount,
    required int reportCount,
    required int rounds,
    required int durationMs,
  }) {
    final detail =
        'chars: ${text.trim().length}\n'
        'rounds: $rounds\n'
        'actions: $actionCount\n'
        'reports: $reportCount';
    if (text.trim().isEmpty) {
      _logs.warning(
        'مدل پاسخ متنی نداد',
        area: AILogArea.chat,
        provider: config.provider.label,
        model: config.model,
        durationMs: durationMs,
        detail: detail,
      );
      return;
    }
    _logs.info(
      'پاسخ دستیار آماده شد',
      area: AILogArea.chat,
      provider: config.provider.label,
      model: config.model,
      durationMs: durationMs,
      detail: detail,
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
