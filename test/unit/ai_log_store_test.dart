import 'package:daram/features/ai/data/ai_diagnostics.dart';
import 'package:daram/features/ai/data/ai_log_store.dart';
import 'package:daram/features/ai/domain/ai_log.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store keeps newest entries first and respects capacity', () {
    final store = AILogStore(capacity: 2);
    store.info('اول', area: AILogArea.chat);
    store.error('دوم', area: AILogArea.network, detail: 'boom');
    store.warning('سوم', area: AILogArea.tool);

    expect(store.entries.map((entry) => entry.title), ['سوم', 'دوم']);
    expect(store.errorCount, 1);
    expect(store.entries.last.detail, 'boom');
    store.dispose();
  });

  test('entries round-trip through JSON and corrupt data is skipped', () {
    final time = DateTime(2026, 11, 22, 8, 30, 12);
    final entry = AILogEntry(
      time: time,
      level: AILogLevel.error,
      area: AILogArea.network,
      title: 'خطای شبکه',
      detail: 'type: receiveTimeout',
      provider: 'OpenCode Go',
      model: 'kimi-k3',
      statusCode: 504,
      durationMs: 3200,
    );

    final restored = AILogEntry.fromJson(entry.toJson());
    expect(restored, isNotNull);
    expect(restored!.time, time);
    expect(restored.level, AILogLevel.error);
    expect(restored.area, AILogArea.network);
    expect(restored.title, 'خطای شبکه');
    expect(restored.detail, 'type: receiveTimeout');
    expect(restored.provider, 'OpenCode Go');
    expect(restored.model, 'kimi-k3');
    expect(restored.statusCode, 504);
    expect(restored.durationMs, 3200);

    expect(AILogEntry.fromJson(null), isNull);
    expect(AILogEntry.fromJson({'title': 'بدون زمان'}), isNull);
    expect(AILogEntry.fromJson('not a map'), isNull);
  });

  test(
    'persistence receives snapshots and clear persists an empty list',
    () async {
      final snapshots = <List<AILogEntry>>[];
      final store = AILogStore(
        capacity: 5,
        persist: (entries) async => snapshots.add(entries),
      );
      store.info('رویداد', area: AILogArea.chat);
      await store.flush();
      expect(snapshots, isNotEmpty);
      expect(snapshots.last.single.title, 'رویداد');

      store.clear();
      await store.flush();
      expect(snapshots.last, isEmpty);
      store.dispose();
    },
  );

  test('dio details never contain request headers or the API key', () {
    final options = RequestOptions(
      path: 'https://example.com/v1/chat/completions',
      headers: {'Authorization': 'Bearer super-secret-key'},
    );
    final error = DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      message: 'server said no',
      response: Response<dynamic>(
        requestOptions: options,
        statusCode: 502,
        data: 'bad gateway',
      ),
    );

    final detail = describeDioException(error);
    expect(detail, contains('badResponse'));
    expect(detail, contains('https://example.com/v1/chat/completions'));
    expect(detail, contains('502'));
    expect(detail, contains('bad gateway'));
    expect(detail, isNot(contains('super-secret-key')));
    expect(dioErrorTypeLabel(DioExceptionType.receiveTimeout), isNotEmpty);
  });

  test('obvious credential patterns are redacted before storing', () {
    final store = AILogStore(capacity: 5);
    store.error(
      'failure',
      area: AILogArea.network,
      detail:
          'Authorization: Bearer sk-live-123456\n'
          'key=oc_sk_abcdef123456\n'
          'url: https://example.com/v1?api_key=query-secret-987\n'
          'note: task-force is not a credential',
    );

    final detail = store.entries.single.detail!;
    expect(detail, isNot(contains('sk-live-123456')));
    expect(detail, isNot(contains('oc_sk_abcdef123456')));
    expect(detail, isNot(contains('query-secret-987')));
    expect(detail, contains('task-force'));
    expect(detail, contains('[redacted]'));
    store.dispose();
  });
}
