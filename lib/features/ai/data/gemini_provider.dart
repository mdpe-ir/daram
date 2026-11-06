import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';
import 'sse.dart';

/// Native Gemini (Google AI Studio) integration with SSE streaming and
/// function declarations.
class GeminiProvider implements AIProvider {
  GeminiProvider(this._dio);

  final Dio _dio;

  String _streamEndpoint(AIConfig config) => '${config.chatEndpoint()}?alt=sse';

  String _generateEndpoint(AIConfig config) {
    final endpoint = config.chatEndpoint();
    return endpoint.replaceFirst(':streamGenerateContent', ':generateContent');
  }

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
        final system = messages
            .where((message) => message.role == AIRole.system)
            .map((message) => message.content)
            .where((content) => content.trim().isNotEmpty)
            .join('\n\n');
        final body = <String, Object?>{
          'contents': _contents(messages),
          if (system.isNotEmpty)
            'systemInstruction': {
              'parts': [
                {'text': system},
              ],
            },
          'generationConfig': {
            'temperature': config.temperature,
            'maxOutputTokens': config.maxTokens,
          },
          if (tools.isNotEmpty)
            'tools': [
              {
                'functionDeclarations': [
                  for (final tool in tools)
                    {
                      'name': tool.name,
                      'description': tool.description,
                      'parameters': _geminiSchema(tool.parameters),
                    },
                ],
              },
            ],
        };

        final response = await _dio.post<ResponseBody>(
          _streamEndpoint(config),
          data: body,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              'x-goog-api-key': config.apiKey,
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
          return;
        }

        final calls = <ToolCall>[];

        await for (final event in SseReader.dataEvents(response.data!)) {
          final decoded = _decode(event);
          if (decoded == null) continue;
          final candidates = decoded['candidates'];
          if (candidates is! List || candidates.isEmpty) {
            final promptFeedback = decoded['promptFeedback'];
            if (promptFeedback is Map &&
                promptFeedback['blockReason'] != null) {
              controller.add(
                AIStreamError(
                  'درخواست توسط سرویس‌دهنده به دلیل سیاست محتوا مسدود شد.',
                ),
              );
              break;
            }
            continue;
          }
          final candidate = candidates.first;
          if (candidate is! Map) continue;
          final content = candidate['content'];
          if (content is Map) {
            final parts = content['parts'];
            if (parts is List) {
              for (final part in parts) {
                if (part is! Map) continue;
                final text = part['text'];
                if (text is String && text.isNotEmpty) {
                  controller.add(AIStreamText(text));
                }
                final functionCall = part['functionCall'];
                if (functionCall is Map) {
                  final name = functionCall['name'];
                  if (name is String) {
                    final args = functionCall['args'];
                    calls.add(
                      ToolCall(
                        id: 'call_${calls.length}',
                        name: name,
                        arguments: args is Map
                            ? args.map((key, value) => MapEntry('$key', value))
                            : const {},
                        rawArguments: jsonEncode(args ?? const {}),
                      ),
                    );
                  }
                }
              }
            }
          }
        }

        if (calls.isNotEmpty) controller.add(AIStreamToolCalls(calls));
        controller.add(const AIStreamDone());
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
        _generateEndpoint(config),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': 'سلام'},
              ],
            },
          ],
        },
        options: Options(
          headers: {
            'x-goog-api-key': config.apiKey,
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

  List<Map<String, Object?>> _contents(List<AIMessage> messages) {
    final contents = <Map<String, Object?>>[];
    for (final message in messages) {
      if (message.role == AIRole.system) continue;
      switch (message.role) {
        case AIRole.user:
          contents.add({
            'role': 'user',
            'parts': [
              {'text': message.content},
            ],
          });
        case AIRole.assistant:
          final parts = <Map<String, Object?>>[];
          if (message.content.trim().isNotEmpty) {
            parts.add({'text': message.content});
          }
          for (final call in message.toolCalls) {
            parts.add({
              'functionCall': {'name': call.name, 'args': call.arguments},
            });
          }
          if (parts.isNotEmpty) contents.add({'role': 'model', 'parts': parts});
        case AIRole.tool:
          contents.add({
            'role': 'user',
            'parts': [
              {
                'functionResponse': {
                  'name': message.name ?? 'tool',
                  'response': {'result': message.content},
                },
              },
            ],
          });
        case AIRole.system:
          break;
      }
    }
    return contents;
  }

  /// Gemini expects an OpenAPI subset with upper-case primitive types.
  Map<String, Object?> _geminiSchema(Map<String, Object?> schema) {
    final result = <String, Object?>{};
    for (final entry in schema.entries) {
      if (entry.key == 'additionalProperties' || entry.key == r'$schema') {
        continue;
      }
      final value = entry.value;
      if (entry.key == 'type' && value is String) {
        result['type'] = value.toUpperCase();
      } else if (value is Map<String, Object?>) {
        result[entry.key] = _geminiSchema(value);
      } else if (value is Map) {
        result[entry.key] = _geminiSchema(
          value.map((key, item) => MapEntry('$key', item)),
        );
      } else if (value is List) {
        result[entry.key] = [
          for (final item in value)
            if (item is Map<String, Object?>)
              _geminiSchema(item)
            else if (item is Map)
              _geminiSchema(item.map((key, sub) => MapEntry('$key', sub)))
            else
              item,
        ];
      } else {
        result[entry.key] = value;
      }
    }
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
}
