import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/ai_models.dart';
import '../domain/ai_log.dart';
import '../domain/ai_provider.dart';
import 'ai_diagnostics.dart';
import 'ai_log_store.dart';
import 'sse.dart';

/// OpenAI-compatible chat completions with SSE streaming and native tools.
///
/// Supports custom base URLs (including proxies and local servers), custom
/// model names and configurable timeouts.
class OpenAICompatibleProvider implements AIProvider {
  OpenAICompatibleProvider(this._dio, {AILogStore? logs})
    : _logs = logs ?? AILogStore.silent();

  final Dio _dio;
  final AILogStore _logs;

  @override
  Stream<AIStreamEvent> streamChat({
    required AIConfig config,
    required List<AIMessage> messages,
    required List<ToolDefinition> tools,
    String? sessionId,
  }) {
    final controller = StreamController<AIStreamEvent>();
    final cancelToken = CancelToken();
    controller.onCancel = () {
      if (!cancelToken.isCancelled) cancelToken.cancel('cancelled');
    };

    Future<void>(() async {
      final watch = Stopwatch()..start();
      final endpoint = config.chatEndpoint();
      final providerLabel = config.provider.label;
      try {
        final body = <String, Object?>{
          'model': config.model,
          'messages': _wireMessages(messages),
          'stream': true,
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
        };
        if (tools.isNotEmpty) {
          body['tools'] = [
            for (final tool in tools)
              {
                'type': 'function',
                'function': {
                  'name': tool.name,
                  'description': tool.description,
                  'parameters': tool.parameters,
                },
              },
          ];
          body['tool_choice'] = 'auto';
        }

        final response = await _dio.post<ResponseBody>(
          endpoint,
          data: body,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: _headers(config, stream: true, sessionId: sessionId),
            receiveTimeout: Duration(seconds: config.timeoutSeconds),
            sendTimeout: const Duration(seconds: 30),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        _logs.info(
          'پاسخ سرویس‌دهنده (${response.statusCode})',
          area: AILogArea.network,
          provider: providerLabel,
          model: config.model,
          statusCode: response.statusCode,
          durationMs: watch.elapsedMilliseconds,
          detail: 'endpoint: $endpoint\nstream: true',
        );

        if (response.statusCode != 200) {
          final detail = await _readErrorBody(response.data);
          _logs.error(
            'سرویس‌دهنده درخواست را نپذیرفت (${response.statusCode})',
            area: AILogArea.network,
            provider: providerLabel,
            model: config.model,
            statusCode: response.statusCode,
            durationMs: watch.elapsedMilliseconds,
            detail: 'endpoint: $endpoint\n$detail',
          );
          controller.add(
            AIStreamError(
              persianAIError(detail, statusCode: response.statusCode),
            ),
          );
          await controller.close();
          return;
        }

        final accumulator = OpenAIToolCallAccumulator();
        String? finishReason;
        var sawError = false;

        await for (final event in SseReader.dataEvents(response.data!)) {
          if (event == '[DONE]') break;
          final decoded = _decode(event);
          if (decoded == null) continue;
          final error = decoded['error'];
          if (error is Map) {
            sawError = true;
            final message = _errorMessage(error);
            _logs.error(
              'خطای سرویس‌دهنده در جریان پاسخ',
              area: AILogArea.network,
              provider: providerLabel,
              model: config.model,
              statusCode: response.statusCode,
              durationMs: watch.elapsedMilliseconds,
              detail: 'endpoint: $endpoint\nmessage: $message',
            );
            controller.add(AIStreamError(message));
            break;
          }
          final choices = decoded['choices'];
          if (choices is! List || choices.isEmpty) continue;
          final choice = choices.first;
          if (choice is! Map) continue;
          final delta = choice['delta'];
          if (delta is Map) {
            final content = delta['content'];
            if (content is String && content.isNotEmpty) {
              controller.add(AIStreamText(content));
            }
            final toolCalls = delta['tool_calls'];
            if (toolCalls is List) accumulator.add(toolCalls);
          }
          final reason = choice['finish_reason'];
          if (reason is String) finishReason = reason;
        }

        if (!sawError) {
          final calls = accumulator.build();
          if (calls.isNotEmpty) controller.add(AIStreamToolCalls(calls));
          controller.add(AIStreamDone(finishReason: finishReason));
          _logs.info(
            'جریان پاسخ کامل شد',
            area: AILogArea.network,
            provider: providerLabel,
            model: config.model,
            statusCode: response.statusCode,
            durationMs: watch.elapsedMilliseconds,
            detail:
                'endpoint: $endpoint\nfinishReason: ${finishReason ?? '-'}\n'
                'toolCalls: ${calls.length}',
          );
        }
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) {
          _logs.info(
            'درخواست دستیار لغو شد',
            area: AILogArea.network,
            provider: providerLabel,
            model: config.model,
            durationMs: watch.elapsedMilliseconds,
            detail: 'endpoint: $endpoint',
          );
          return;
        }
        final status = error.response?.statusCode;
        _logs.error(
          'خطای شبکه: ${dioErrorTypeLabel(error.type)}',
          area: AILogArea.network,
          provider: providerLabel,
          model: config.model,
          statusCode: status,
          durationMs: watch.elapsedMilliseconds,
          detail: describeDioException(error),
        );
        controller.add(
          AIStreamError(persianAIError(error, statusCode: status)),
        );
      } on Object catch (error) {
        _logs.error(
          'خطا در پردازش پاسخ سرویس‌دهنده',
          area: AILogArea.network,
          provider: providerLabel,
          model: config.model,
          durationMs: watch.elapsedMilliseconds,
          detail: 'endpoint: $endpoint\n${error.toString()}',
        );
        controller.add(AIStreamError(persianAIError(error)));
      } finally {
        if (!controller.isClosed) await controller.close();
      }
    });

    return controller.stream;
  }

  /// Headers shared by the streaming and connection-test requests.
  Map<String, String> _headers(
    AIConfig config, {
    required bool stream,
    String? sessionId,
  }) {
    final headers = <String, String>{
      'Authorization': 'Bearer ${config.apiKey}',
      'Content-Type': 'application/json',
      if (stream) 'Accept': 'text/event-stream',
    };
    if (config.provider.isOpenCode) {
      // OpenCode routes/caches by conversation when this header is stable.
      final raw = sessionId?.trim();
      final id = raw == null || raw.isEmpty ? 'daram' : raw;
      headers['x-opencode-session'] = id.startsWith('ses_') ? id : 'ses_$id';
    }
    return headers;
  }

  @override
  Future<AIConnectionResult> testConnection(AIConfig config) async {
    final watch = Stopwatch()..start();
    final endpoint = config.chatEndpoint();
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: {
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'سلام'},
          ],
          'max_tokens': 5,
        },
        options: Options(
          headers: _headers(config, stream: false),
          receiveTimeout: Duration(seconds: config.timeoutSeconds),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null,
        ),
      );
      if (response.statusCode == 200) {
        _logs.info(
          'تست اتصال موفق بود',
          area: AILogArea.network,
          provider: config.provider.label,
          model: config.model,
          statusCode: response.statusCode,
          durationMs: watch.elapsedMilliseconds,
          detail: 'endpoint: $endpoint',
        );
        return const AIConnectionResult.success(
          'اتصال برقرار است و مدل پاسخ داد.',
        );
      }
      final message = persianAIError(
        response.data ?? 'error',
        statusCode: response.statusCode,
      );
      _logs.warning(
        'تست اتصال ناموفق بود (${response.statusCode})',
        area: AILogArea.network,
        provider: config.provider.label,
        model: config.model,
        statusCode: response.statusCode,
        durationMs: watch.elapsedMilliseconds,
        detail: 'endpoint: $endpoint\n$message',
      );
      return AIConnectionResult.failure(message);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      _logs.error(
        'تست اتصال ناموفق بود: ${dioErrorTypeLabel(error.type)}',
        area: AILogArea.network,
        provider: config.provider.label,
        model: config.model,
        statusCode: status,
        durationMs: watch.elapsedMilliseconds,
        detail: describeDioException(error),
      );
      return AIConnectionResult.failure(
        persianAIError(error, statusCode: status),
      );
    }
  }

  List<Map<String, Object?>> _wireMessages(List<AIMessage> messages) {
    return [
      for (final message in messages)
        {
          'role': switch (message.role) {
            AIRole.system => 'system',
            AIRole.user => 'user',
            AIRole.assistant => 'assistant',
            AIRole.tool => 'tool',
          },
          'content': message.content,
          if (message.role == AIRole.assistant && message.toolCalls.isNotEmpty)
            'tool_calls': [
              for (final call in message.toolCalls)
                {
                  'id': call.id,
                  'type': 'function',
                  'function': {
                    'name': call.name,
                    'arguments': call.rawArguments.isEmpty
                        ? jsonEncode(call.arguments)
                        : call.rawArguments,
                  },
                },
            ],
          if (message.role == AIRole.tool) 'tool_call_id': message.toolCallId,
          if (message.role == AIRole.tool && message.name != null)
            'name': message.name,
        },
    ];
  }

  Future<String> _readErrorBody(ResponseBody? body) async {
    if (body == null) return 'unknown';
    try {
      final bytes = await body.stream.fold<List<int>>(
        <int>[],
        (previous, chunk) => previous..addAll(chunk),
      );
      final text = utf8.decode(bytes, allowMalformed: true);
      final decoded = _decode(text);
      if (decoded != null) {
        final error = decoded['error'];
        if (error is Map) return _errorMessage(error);
        if (error is String) return error;
      }
      return text.length > 300 ? text.substring(0, 300) : text;
    } on Object {
      return 'unknown';
    }
  }

  Map<String, Object?>? _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  String _errorMessage(Map error) {
    final message = error['message'];
    return message is String ? message : 'خطای نامشخص سرویس‌دهنده';
  }
}
