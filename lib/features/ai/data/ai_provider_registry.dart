import 'package:dio/dio.dart';

import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';
import 'anthropic_provider.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';

/// Selects the concrete provider for the user's configuration.
class AIProviderRegistry {
  AIProviderRegistry(Dio dio)
    : _openAI = OpenAICompatibleProvider(dio),
      _anthropic = AnthropicProvider(dio),
      _gemini = GeminiProvider(dio);

  final OpenAICompatibleProvider _openAI;
  final AnthropicProvider _anthropic;
  final GeminiProvider _gemini;

  AIProvider forKind(AIProviderKind kind) => switch (kind) {
    AIProviderKind.openAICompatible => _openAI,
    AIProviderKind.anthropic => _anthropic,
    AIProviderKind.gemini => _gemini,
  };
}
