import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';
import 'sse.dart';

/// Native Anthropic Messages API integration with SSE streaming and tools.
class AnthropicProvider implements AIProvider {
  AnthropicProvider(this._dio);

  final Dio _dio;
  static const _apiVersion = '2023-06-01';

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
          'max_tokens': config.maxTokens,
          'temperature': config.temperature,
          'stream': true,
          'messages': _wireMessages(messages),
        };
        final system = messages
            .where((message) => message.role == AIRole.system)
            .map((message) => message.content)
            .where((content) => content.trim().isNotEmpty)
            .join('\n\n');
        if (system.isNotEmpty) body['system'] = system;
        if (tools.isNotEmpty) {
          body['tools'] = [
            for (final tool in tools)
              {
                'name': tool.name,
                'description': tool.description,
                'input_schema': tool.parameters,
              },
          ];
        }

        final response = await _dio.post<ResponseBody>(
          config.chatEndpoint(),
          data: body,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'x-api-key': config.apiKey,
              'anthropic-version': _apiVersion,
              'Content-Type': 'application/json',
              'Accept': 'text/event-stream',
              if (kIsWeb) 'anthropic-dangerous-direct-browser-access': 'true',
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
          return;
        }

        final calls = <ToolCall>[];
        String? currentToolId;
        String? currentToolName;
        final arguments = StringBuffer();
        var sawError = false;

        await for (final event in SseReader.dataEvents(response.data!)) {
          final decoded = _decode(event);
          if (decoded == null) continue;
          final type = decoded['type'];
          switch (type) {
            case 'content_block_start':
              final block = decoded['content_block'];
              if (block is Map && block['type'] == 'tool_use') {
                currentToolId = block['id'] as String?;
                currentToolName = block['name'] as String?;
                arguments.clear();
              }
            case 'content_block_delta':
              final delta = decoded['delta'];
              if (delta is Map) {
                if (delta['type'] == 'text_delta') {
                  final text = delta['text'];
                  if (text is String && text.isNotEmpty) {
                    controller.add(AIStreamText(text));
                  }
                } else if (delta['type'] == 'input_json_delta') {
                  final partial = delta['partial_json'];
                  if (partial is String) arguments.write(partial);
                }
              }
            case 'content_block_stop':
              if (currentToolName != null) {
                calls.add(
                  ToolCall(
                    id: currentToolId ?? 'tool_${calls.length}',
                    name: currentToolName,
                    arguments: _decodeArgs(arguments.toString()),
                    rawArguments: arguments.toString(),
                  ),
                );
                currentToolId = null;
                currentToolName = null;
                arguments.clear();
              }
            case 'message_stop':
              if (calls.isNotEmpty) controller.add(AIStreamToolCalls(calls));
              controller.add(const AIStreamDone(finishReason: 'stop'));
              sawError = true; // stop processing further events
            case 'error':
              final error = decoded['error'];
              controller.add(
                AIStreamError(
                  error is Map && error['message'] is String
                      ? error['message'] as String
                      : 'خطای سرویس Anthropic',
                ),
              );
              sawError = true;
          }
          if (sawError) break;
        }
        if (!sawError && calls.isNotEmpty) {
          controller.add(AIStreamToolCalls(calls));
          controller.add(const AIStreamDone());
        }
      } on DioException catch (error) {
        if (CancelToken.isCancel(error)) return;
        controller.add(
          AIStreamError(
            persianAIError(error, statusCode: error.response?.statusCode),
          ),
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
          'max_tokens': 5,
          'messages': [
            {'role': 'user', 'content': 'سلام'},
          ],
        },
        options: Options(
          headers: {
            'x-api-key': config.apiKey,
            'anthropic-version': _apiVersion,
            'Content-Type': 'application/json',
            if (kIsWeb) 'anthropic-dangerous-direct-browser-access': 'true',
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
    final result = <Map<String, Object?>>[];
    final buffer = <Map<String, Object?>>[];

    void flushToolResults() {
      if (buffer.isEmpty) return;
      result.add({
        'role': 'user',
        'content': List<Map<String, Object?>>.from(buffer),
      });
      buffer.clear();
    }

    for (final message in messages) {
      if (message.role == AIRole.system) continue;
      if (message.role == AIRole.tool) {
        buffer.add({
          'type': 'tool_result',
          'tool_use_id': message.toolCallId,
          'content': message.content,
        });
        continue;
      }
      flushToolResults();
      if (message.role == AIRole.user) {
        result.add({
          'role': 'user',
          'content': [
            {'type': 'text', 'text': message.content},
          ],
        });
      } else if (message.role == AIRole.assistant) {
        final blocks = <Map<String, Object?>>[];
        if (message.content.trim().isNotEmpty) {
          blocks.add({'type': 'text', 'text': message.content});
        }
        for (final call in message.toolCalls) {
          blocks.add({
            'type': 'tool_use',
            'id': call.id,
            'name': call.name,
            'input': call.arguments,
          });
        }
        if (blocks.isNotEmpty) {
          result.add({'role': 'assistant', 'content': blocks});
        }
      }
    }
    flushToolResults();
    return result;
  }

  Future<String> _readErrorBody(ResponseBody? body) async {
    if (body == null) return 'unknown';
    try {
      final bytes = await body.stream.fold<List<int>>(
        <int>[],
        (previous, chunk) => previous..addAll(chunk),
      );
      return utf8.decode(bytes, allowMalformed: true);
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

  Map<String, Object?> _decodeArgs(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } on FormatException {
      return const {};
    }
    return const {};
  }
}
