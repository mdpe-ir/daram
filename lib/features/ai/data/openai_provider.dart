import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';
import 'sse.dart';

/// OpenAI-compatible chat completions with SSE streaming and native tools.
///
/// Supports custom base URLs (including proxies and local servers), custom
/// model names and configurable timeouts.
class OpenAICompatibleProvider implements AIProvider {
  OpenAICompatibleProvider(this._dio);

  final Dio _dio;

  @override
  Stream<AIStreamEvent> streamChat({
    required AIConfig config,
    required List<AIMessage> messages,
    required List<ToolDefinition> tools,
  }) {
    final controller = StreamController<AIStreamEvent>();
    final cancelToken = CancelToken();
    controller.onCancel = () {
      if (!cancelToken.isCancelled) cancelToken.cancel('cancelled');
    };

    Future<void>(() async {
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
          config.chatEndpoint(),
          data: body,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'Authorization': 'Bearer ${config.apiKey}',
              'Content-Type': 'application/json',
              'Accept': 'text/event-stream',
            },
            receiveTimeout: Duration(seconds: config.timeoutSeconds),
            sendTimeout: const Duration(seconds: 30),
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.statusCode != 200) {
          final detail = await _readErrorBody(response.data);
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
            controller.add(AIStreamError(_errorMessage(error)));
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
        }
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) return;
        final status = error.response?.statusCode;
        controller.add(
          AIStreamError(persianAIError(error, statusCode: status)),
        );
      } on Object catch (error) {
        controller.add(AIStreamError(persianAIError(error)));
      } finally {
        if (!controller.isClosed) await controller.close();
      }
    });

    return controller.stream;
  }

  @override
  Future<AIConnectionResult> testConnection(AIConfig config) async {
    try {
      final response = await _dio.post<dynamic>(
        config.chatEndpoint(),
        data: {
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'سلام'},
          ],
          'max_tokens': 5,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          receiveTimeout: Duration(seconds: config.timeoutSeconds),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (status) => status != null,
        ),
      );
      if (response.statusCode == 200) {
        return const AIConnectionResult.success(
          'اتصال برقرار است و مدل پاسخ داد.',
        );
      }
      return AIConnectionResult.failure(
        persianAIError(
          response.data ?? 'error',
          statusCode: response.statusCode,
        ),
      );
    } on DioException catch (error) {
      return AIConnectionResult.failure(
        persianAIError(error, statusCode: error.response?.statusCode),
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
