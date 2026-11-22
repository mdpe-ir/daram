import 'package:dio/dio.dart';

import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';
import 'ai_log_store.dart';
import 'anthropic_provider.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';

/// Selects the concrete provider for the user's configuration.
class AIProviderRegistry {
  AIProviderRegistry(Dio dio, {AILogStore? logs})
    : _openAI = OpenAICompatibleProvider(dio, logs: logs),
      _anthropic = AnthropicProvider(dio, logs: logs),
      _gemini = GeminiProvider(dio, logs: logs);

  final OpenAICompatibleProvider _openAI;
  final AnthropicProvider _anthropic;
  final GeminiProvider _gemini;

  AIProvider forKind(AIProviderKind kind) => switch (kind) {
    AIProviderKind.openAICompatible ||
    AIProviderKind.openCode ||
    AIProviderKind.openCodeGo => _openAI,
    AIProviderKind.anthropic => _anthropic,
    AIProviderKind.gemini => _gemini,
  };
}
