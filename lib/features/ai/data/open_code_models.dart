import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/ai_models.dart';
import '../domain/ai_provider.dart';

/// One entry from the live OpenCode model catalogs.
@immutable
final class AIModelOption {
  const AIModelOption({
    required this.id,
    required this.name,
    this.supportsTools,
    this.contextWindow,
  });

  final String id;
  final String name;
  final bool? supportsTools;
  final int? contextWindow;
}

/// Reads `https://opencode.ai/inference/v1/models` (OpenCode) or the Go
/// catalog. The public list works without a key; with a key it is filtered to
/// the models that workspace can actually call.
class OpenCodeModels {
  OpenCodeModels(this._dio);

  final Dio _dio;

  Future<List<AIModelOption>> list(AIConfig config) async {
    final key = config.apiKey.trim();
    try {
      final response = await _dio.get<dynamic>(
        config.modelsEndpoint(),
        options: Options(
          headers: {
            'Accept': 'application/json',
            if (key.isNotEmpty) 'Authorization': 'Bearer $key',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
          validateStatus: (status) => status != null,
        ),
      );
      if (response.statusCode != 200) {
        throw ValidationException(
          persianAIError(
            response.data ?? 'error',
            statusCode: response.statusCode,
          ),
        );
      }
      return parseModels(response.data);
    } on DioException catch (error) {
      throw ValidationException(
        persianAIError(error, statusCode: error.response?.statusCode),
      );
    } on AppException {
      rethrow;
    } on Object {
      throw const ValidationException(
        'دریافت فهرست مدل‌های OpenCode ممکن نشد.',
      );
    }
  }

  /// Parses the OpenAI-shaped `{data: [...]}` response.
  static List<AIModelOption> parseModels(Object? payload) {
    final map = payload is Map ? payload : null;
    final data = map?['data'];
    if (data is! List) return const [];

    final seen = <String>{};
    final models = <AIModelOption>[];
    for (final raw in data) {
      if (raw is! Map) continue;
      final id = raw['id'];
      if (id is! String || id.trim().isEmpty || !seen.add(id.trim())) {
        continue;
      }
      final name = raw['name'];
      final capabilities = raw['capabilities'];
      final tools = capabilities is Map ? capabilities['tools'] : null;
      final limit = raw['limit'];
      final context = limit is Map ? limit['context'] : null;
      models.add(
        AIModelOption(
          id: id.trim(),
          name: name is String && name.trim().isNotEmpty
              ? name.trim()
              : id.trim(),
          supportsTools: tools is Map && tools.containsKey('supported')
              ? tools['supported'] == true
              : null,
          contextWindow: context is int ? context : null,
        ),
      );
    }
    models.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
    return models;
  }
}
