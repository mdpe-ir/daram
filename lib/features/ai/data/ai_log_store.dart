import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/ai_log.dart';

/// Bounded, persisted list of assistant diagnostics.
///
/// The store is deliberately synchronous for producers: providers and the chat
/// loop only add an entry and move on. Persistence is debounced so a streaming
/// answer does not rewrite preferences for every network event.
class AILogStore extends ChangeNotifier {
  AILogStore({
    this.capacity = 250,
    this.persist,
    Iterable<AILogEntry> initial = const <AILogEntry>[],
  }) : _entries = List<AILogEntry>.of(initial) {
    _trim();
  }

  /// A store used when no UI is attached (unit tests, tools). It accepts every
  /// call but keeps nothing.
  AILogStore.silent() : capacity = 0, persist = null, _entries = <AILogEntry>[];

  final int capacity;

  /// Called with a snapshot after changes. Failures are ignored: diagnostics
  /// must never break the assistant.
  final Future<void> Function(List<AILogEntry> entries)? persist;

  final List<AILogEntry> _entries;
  Timer? _persistTimer;

  /// Newest first.
  List<AILogEntry> get entries => List<AILogEntry>.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  int get errorCount =>
      _entries.where((entry) => entry.level == AILogLevel.error).length;

  void info(
    String title, {
    required AILogArea area,
    String? detail,
    String? provider,
    String? model,
    int? statusCode,
    int? durationMs,
  }) => record(
    level: AILogLevel.info,
    area: area,
    title: title,
    detail: detail,
    provider: provider,
    model: model,
    statusCode: statusCode,
    durationMs: durationMs,
  );

  void warning(
    String title, {
    required AILogArea area,
    String? detail,
    String? provider,
    String? model,
    int? statusCode,
    int? durationMs,
  }) => record(
    level: AILogLevel.warning,
    area: area,
    title: title,
    detail: detail,
    provider: provider,
    model: model,
    statusCode: statusCode,
    durationMs: durationMs,
  );

  void error(
    String title, {
    required AILogArea area,
    String? detail,
    String? provider,
    String? model,
    int? statusCode,
    int? durationMs,
  }) => record(
    level: AILogLevel.error,
    area: area,
    title: title,
    detail: detail,
    provider: provider,
    model: model,
    statusCode: statusCode,
    durationMs: durationMs,
  );

  void record({
    required AILogLevel level,
    required AILogArea area,
    required String title,
    String? detail,
    String? provider,
    String? model,
    int? statusCode,
    int? durationMs,
  }) {
    if (capacity <= 0) return;
    final cleaned = detail?.trim();
    _entries.insert(
      0,
      AILogEntry(
        time: DateTime.now(),
        level: level,
        area: area,
        title: redactSecrets(title),
        detail: cleaned == null || cleaned.isEmpty
            ? null
            : truncateText(redactSecrets(cleaned), 1200),
        provider: provider,
        model: model,
        statusCode: statusCode,
        durationMs: durationMs,
      ),
    );
    _trim();
    notifyListeners();
    _schedulePersist();
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
    _persistTimer?.cancel();
    unawaited(_persistNow());
  }

  /// Writes the current snapshot immediately; used by tests and before export.
  Future<void> flush() => _persistNow();

  void _trim() {
    if (_entries.length <= capacity) return;
    _entries.removeRange(capacity, _entries.length);
  }

  void _schedulePersist() {
    if (persist == null) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_persistNow());
    });
  }

  Future<void> _persistNow() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    final callback = persist;
    if (callback == null) return;
    try {
      await callback(List<AILogEntry>.unmodifiable(_entries));
    } on Object {
      // Diagnostics persistence is best-effort.
    }
  }

  @override
  void dispose() {
    _persistTimer?.cancel();
    super.dispose();
  }
}

/// Shortens a technical detail so one failure cannot fill the whole log.
String truncateText(String value, int maxCharacters) {
  final trimmed = value.trim();
  if (trimmed.length <= maxCharacters) return trimmed;
  return '${trimmed.substring(0, maxCharacters)}…';
}

/// Removes obvious credential patterns from diagnostics text.
///
/// The app never logs headers or the key on purpose, but a proxy or gateway
/// can echo a token in an error body. This is the last line of defence before
/// an entry reaches preferences or the clipboard.
String redactSecrets(String value) {
  var text = value;
  text = text.replaceAllMapped(
    RegExp(r'(?<![A-Za-z0-9])(oc_sk|sk)[-_][A-Za-z0-9._-]{4,}'),
    (match) => '${match.group(1)}-[redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'\b(x-api-key|x-goog-api-key|authorization)\s*[:=]\s*(?:Bearer\s+)?[^\s",;]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}: [redacted]',
  );
  text = text.replaceAll(
    RegExp(r'Bearer\s+[^\s",;]+', caseSensitive: false),
    'Bearer [redacted]',
  );
  text = text.replaceAllMapped(
    RegExp(
      r'([?&](?:api[_-]?key|key|token|access_token)=)[^&\s]+',
      caseSensitive: false,
    ),
    (match) => '${match.group(1)}[redacted]',
  );
  return text;
}
