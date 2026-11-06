import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/ai_models.dart';

/// Minimal Server-Sent-Events reader for provider streams.
///
/// Providers share the same framing (`data: {...}` lines separated by blank
/// lines) but differ in payloads, so only the framing lives here.
class SseReader {
  const SseReader._();

  static Stream<String> dataEvents(ResponseBody body) {
    final controller = StreamController<String>();
    late StreamSubscription<String> subscription;
    subscription = body.stream
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            final trimmed = line.trimRight();
            if (trimmed.startsWith('data:')) {
              final data = trimmed.substring(5).trim();
              if (data.isNotEmpty) controller.add(data);
            } else if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
              // Some OpenAI-compatible servers omit the `data:` prefix.
              controller.add(trimmed);
            }
          },
          onError: controller.addError,
          onDone: controller.close,
          cancelOnError: false,
        );
    controller.onCancel = () => subscription.cancel();
    return controller.stream;
  }
}

/// Accumulates OpenAI-style streamed tool calls by index.
class OpenAIToolCallAccumulator {
  final Map<int, _Accumulator> _calls = {};

  void add(List<dynamic> toolCalls) {
    for (final raw in toolCalls) {
      if (raw is! Map) continue;
      final index = (raw['index'] as num?)?.toInt() ?? 0;
      final acc = _calls.putIfAbsent(index, _Accumulator.new);
      final id = raw['id'];
      if (id is String && id.isNotEmpty) acc.id = id;
      final function = raw['function'];
      if (function is Map) {
        final name = function['name'];
        if (name is String && name.isNotEmpty) acc.name = name;
        final arguments = function['arguments'];
        if (arguments is String) acc.arguments.write(arguments);
      }
    }
  }

  List<ToolCall> build() {
    final entries = _calls.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return [
      for (final entry in entries)
        if (entry.value.name != null)
          ToolCall(
            id: entry.value.id ?? 'call_${entry.key}',
            name: entry.value.name!,
            arguments: _decodeArguments(entry.value.arguments.toString()),
            rawArguments: entry.value.arguments.toString(),
          ),
    ];
  }

  Map<String, Object?> _decodeArguments(String raw) {
    if (raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry('$key', value));
      }
    } on FormatException {
      // The caller surfaces a validation error; never execute malformed args.
    }
    return const {};
  }
}

class _Accumulator {
  String? id;
  String? name;
  final StringBuffer arguments = StringBuffer();
}
