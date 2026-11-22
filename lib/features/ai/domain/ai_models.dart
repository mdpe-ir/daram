import 'package:meta/meta.dart';

/// Supported AI wire formats.
enum AIProviderKind {
  openAICompatible(
    label: 'سازگار با OpenAI',
    defaultBaseUrl: 'https://api.openai.com/v1',
    defaultModel: 'gpt-4o-mini',
    supportsNativeTools: true,
  ),
  anthropic(
    label: 'Anthropic (Claude)',
    defaultBaseUrl: 'https://api.anthropic.com',
    defaultModel: 'claude-sonnet-4-5',
    supportsNativeTools: true,
  ),
  gemini(
    label: 'Google Gemini',
    defaultBaseUrl: 'https://generativelanguage.googleapis.com',
    defaultModel: 'gemini-2.5-flash',
    supportsNativeTools: true,
  ),
  openCode(
    label: 'OpenCode',
    defaultBaseUrl: 'https://opencode.ai/inference/openai/v1',
    defaultModel: 'glm-5.3',
    supportsNativeTools: true,
  ),
  openCodeGo(
    label: 'OpenCode Go',
    defaultBaseUrl: 'https://opencode.ai/inference/go/openai/v1',
    defaultModel: 'kimi-k3',
    supportsNativeTools: true,
  );

  const AIProviderKind({
    required this.label,
    required this.defaultBaseUrl,
    required this.defaultModel,
    required this.supportsNativeTools,
  });

  final String label;
  final String defaultBaseUrl;
  final String defaultModel;
  final bool supportsNativeTools;

  /// Both OpenCode plans share the OpenAI-compatible gateway shape and require
  /// the `x-opencode-session` header.
  bool get isOpenCode =>
      this == AIProviderKind.openCode || this == AIProviderKind.openCodeGo;

  /// OpenCode owns the endpoint and the model catalog, so the settings screen
  /// only needs the key (and an optional model choice) from the user.
  bool get usesManagedEndpoint => isOpenCode;

  static AIProviderKind fromStorage(String value) =>
      AIProviderKind.values.firstWhere(
        (kind) => kind.name == value,
        orElse: () => AIProviderKind.openAICompatible,
      );
}

/// How tool calls are requested from the model.
enum AIToolMode {
  native('فراخوانی ابزار'),
  json('خروجی JSON');

  const AIToolMode(this.labelFa);

  final String labelFa;

  static AIToolMode fromStorage(String value) => AIToolMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AIToolMode.native,
  );
}

/// User-supplied provider configuration (BYOK).
@immutable
final class AIConfig {
  const AIConfig({
    required this.provider,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
    this.timeoutSeconds = 90,
    this.toolMode = AIToolMode.native,
    this.maxTokens = 2048,
    this.temperature = 0.3,
  });

  final AIProviderKind provider;
  final String baseUrl;
  final String model;
  final String apiKey;
  final int timeoutSeconds;
  final AIToolMode toolMode;
  final int maxTokens;
  final double temperature;

  bool get isConfigured =>
      apiKey.trim().isNotEmpty &&
      baseUrl.trim().isNotEmpty &&
      model.trim().isNotEmpty;

  AIConfig copyWith({
    AIProviderKind? provider,
    String? baseUrl,
    String? model,
    String? apiKey,
    int? timeoutSeconds,
    AIToolMode? toolMode,
    int? maxTokens,
    double? temperature,
  }) => AIConfig(
    provider: provider ?? this.provider,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    apiKey: apiKey ?? this.apiKey,
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    toolMode: toolMode ?? this.toolMode,
    maxTokens: maxTokens ?? this.maxTokens,
    temperature: temperature ?? this.temperature,
  );

  /// Validates the configuration and returns a Persian error message.
  String? validate() {
    if (apiKey.trim().isEmpty) return 'کلید API وارد نشده است.';
    if (model.trim().isEmpty) return 'نام مدل را وارد کنید.';
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        !uri.hasScheme ||
        !uri.isScheme('http') && !uri.isScheme('https')) {
      return 'آدرس سرویس (Base URL) معتبر نیست.';
    }
    if (timeoutSeconds < 10 || timeoutSeconds > 300) {
      return 'زمان انتظار باید بین ۱۰ تا ۳۰۰ ثانیه باشد.';
    }
    return null;
  }

  /// The endpoint used for chat completions, with no duplicated path segments.
  String chatEndpoint() => _join(baseUrl, _chatPath);

  String modelsEndpoint() => switch (provider) {
    AIProviderKind.openCode => 'https://opencode.ai/inference/v1/models',
    AIProviderKind.openCodeGo => 'https://opencode.ai/inference/go/v1/models',
    _ => _join(baseUrl, _modelsPath),
  };

  String get _chatPath => switch (provider) {
    AIProviderKind.openAICompatible ||
    AIProviderKind.openCode ||
    AIProviderKind.openCodeGo => 'chat/completions',
    AIProviderKind.anthropic => 'v1/messages',
    AIProviderKind.gemini => 'v1beta/models/$model:streamGenerateContent',
  };

  String get _modelsPath => switch (provider) {
    AIProviderKind.openAICompatible => 'models',
    AIProviderKind.anthropic => 'v1/models',
    AIProviderKind.gemini => 'v1beta/models',
    AIProviderKind.openCode || AIProviderKind.openCodeGo => 'models',
  };

  static String _join(String baseUrl, String path) {
    var base = baseUrl.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    // A user may paste the full endpoint instead of the base URL.
    if (base.endsWith('/$path')) return base;
    // Never duplicate a version segment the user already included.
    var cleanPath = path;
    for (final version in const ['v1beta', 'v1']) {
      if (base.endsWith('/$version') && cleanPath.startsWith('$version/')) {
        cleanPath = cleanPath.substring(version.length + 1);
      }
    }
    return '$base/$cleanPath';
  }
}

/// Roles understood by the provider layer.
enum AIRole { system, user, assistant, tool }

/// A provider-agnostic message.
@immutable
final class AIMessage {
  const AIMessage({
    required this.role,
    required this.content,
    this.toolCalls = const [],
    this.toolCallId,
    this.name,
  });

  const AIMessage.system(String content)
    : this(role: AIRole.system, content: content);

  const AIMessage.user(String content)
    : this(role: AIRole.user, content: content);

  const AIMessage.assistant(
    String content, {
    List<ToolCall> toolCalls = const [],
  }) : this(role: AIRole.assistant, content: content, toolCalls: toolCalls);

  const AIMessage.toolResult({
    required this.toolCallId,
    required this.name,
    required this.content,
  }) : role = AIRole.tool,
       toolCalls = const [];

  final AIRole role;
  final String content;
  final List<ToolCall> toolCalls;
  final String? toolCallId;
  final String? name;
}

/// A fully assembled tool call.
@immutable
final class ToolCall {
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
    this.rawArguments = '',
  });

  final String id;
  final String name;
  final Map<String, Object?> arguments;
  final String rawArguments;
}

/// A tool exposed to the model, with a strict JSON schema.
@immutable
final class ToolDefinition {
  const ToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });

  final String name;
  final String description;
  final Map<String, Object?> parameters;
}

/// Events emitted by [AIProvider.streamChat].
sealed class AIStreamEvent {
  const AIStreamEvent();
}

class AIStreamText extends AIStreamEvent {
  const AIStreamText(this.text);
  final String text;
}

class AIStreamToolCalls extends AIStreamEvent {
  const AIStreamToolCalls(this.calls);
  final List<ToolCall> calls;
}

class AIStreamDone extends AIStreamEvent {
  const AIStreamDone({this.finishReason});
  final String? finishReason;
}

class AIStreamError extends AIStreamEvent {
  const AIStreamError(this.message, {this.code});
  final String message;
  final String? code;
}

/// Result of the "test connection" action.
@immutable
final class AIConnectionResult {
  const AIConnectionResult.success(this.message) : ok = true;
  const AIConnectionResult.failure(this.message) : ok = false;

  final bool ok;
  final String message;
}
