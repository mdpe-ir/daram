import 'package:meta/meta.dart';

/// Which part of the assistant produced a diagnostic event.
enum AILogArea {
  chat('گفتگو'),
  network('شبکه'),
  tool('ابزار');

  const AILogArea(this.labelFa);

  final String labelFa;

  static AILogArea fromStorage(Object? value) => AILogArea.values.firstWhere(
    (area) => area.name == value,
    orElse: () => AILogArea.chat,
  );
}

/// Severity used for colouring and filtering the diagnostics list.
enum AILogLevel {
  info('اطلاع'),
  warning('هشدار'),
  error('خطا');

  const AILogLevel(this.labelFa);

  final String labelFa;

  static AILogLevel fromStorage(Object? value) => AILogLevel.values.firstWhere(
    (level) => level.name == value,
    orElse: () => AILogLevel.info,
  );
}

/// One local diagnostic event.
///
/// Entries never contain the API key, request headers or the whole
/// conversation. They are stored on the device so a failed turn can be
/// inspected after the app restarts.
@immutable
final class AILogEntry {
  const AILogEntry({
    required this.time,
    required this.level,
    required this.area,
    required this.title,
    this.detail,
    this.provider,
    this.model,
    this.statusCode,
    this.durationMs,
  });

  final DateTime time;
  final AILogLevel level;
  final AILogArea area;
  final String title;

  /// Technical context (endpoint, error type, short response body). Optional.
  final String? detail;

  final String? provider;
  final String? model;
  final int? statusCode;
  final int? durationMs;

  /// Stable identity for list expansion state.
  String get id => '${time.microsecondsSinceEpoch}-$title';

  Map<String, Object?> toJson() => {
    'time': time.toUtc().toIso8601String(),
    'level': level.name,
    'area': area.name,
    'title': title,
    if (detail != null) 'detail': detail,
    if (provider != null) 'provider': provider,
    if (model != null) 'model': model,
    if (statusCode != null) 'statusCode': statusCode,
    if (durationMs != null) 'durationMs': durationMs,
  };

  /// Tolerant parser: corrupt or older entries are skipped instead of breaking
  /// the whole diagnostics screen.
  static AILogEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final title = raw['title'];
    final time = DateTime.tryParse('${raw['time'] ?? ''}');
    if (title is! String || title.trim().isEmpty || time == null) return null;
    final status = raw['statusCode'];
    final duration = raw['durationMs'];
    final detail = raw['detail'];
    final provider = raw['provider'];
    final model = raw['model'];
    return AILogEntry(
      time: time.toLocal(),
      level: AILogLevel.fromStorage(raw['level']),
      area: AILogArea.fromStorage(raw['area']),
      title: title,
      detail: detail is String && detail.trim().isNotEmpty ? detail : null,
      provider: provider is String && provider.trim().isNotEmpty
          ? provider
          : null,
      model: model is String && model.trim().isNotEmpty ? model : null,
      statusCode: status is int ? status : null,
      durationMs: duration is int ? duration : null,
    );
  }
}
