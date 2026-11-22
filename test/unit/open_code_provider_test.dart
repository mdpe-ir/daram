import 'dart:typed_data';

import 'package:daram/features/ai/data/openai_provider.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      'data: [DONE]\n\n',
      200,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test(
    'OpenCode requests carry the API key and stable session header',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final provider = OpenAICompatibleProvider(dio);
      const config = AIConfig(
        provider: AIProviderKind.openCodeGo,
        baseUrl: 'https://opencode.ai/inference/go/openai/v1',
        model: 'kimi-k3',
        apiKey: 'oc_sk_test',
      );

      await provider
          .streamChat(
            config: config,
            messages: const [AIMessage.user('سلام')],
            tools: const [],
            sessionId: 'chat-123',
          )
          .toList();

      final headers = {
        for (final entry in adapter.request!.headers.entries)
          entry.key.toLowerCase(): entry.value,
      };
      expect(headers['x-opencode-session'], 'ses_chat-123');
      expect(headers['authorization'], 'Bearer oc_sk_test');
      expect(
        adapter.request!.uri.toString(),
        'https://opencode.ai/inference/go/openai/v1/chat/completions',
      );
    },
  );

  test(
    'other OpenAI-compatible providers do not send the OpenCode header',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final provider = OpenAICompatibleProvider(dio);
      const config = AIConfig(
        provider: AIProviderKind.openAICompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini',
        apiKey: 'sk-test',
      );

      await provider
          .streamChat(
            config: config,
            messages: const [AIMessage.user('سلام')],
            tools: const [],
            sessionId: 'chat-123',
          )
          .toList();

      final headers = {
        for (final entry in adapter.request!.headers.entries)
          entry.key.toLowerCase(): entry.value,
      };
      expect(headers.containsKey('x-opencode-session'), isFalse);
    },
  );
}
