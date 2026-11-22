import 'package:daram/features/ai/data/open_code_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses names, ids, context and tool support from the catalog', () {
    final models = OpenCodeModels.parseModels({
      'object': 'list',
      'data': [
        {
          'id': 'kimi-k3',
          'name': 'Kimi K3',
          'limit': {'context': 262144},
          'capabilities': {
            'tools': {'supported': true},
          },
        },
        {
          'id': 'glm-5.3',
          'name': 'GLM 5.3',
          'capabilities': {
            'tools': {'supported': false},
          },
        },
        {'id': 'kimi-k3', 'name': 'Duplicate'},
        {'name': 'No id'},
        'not-a-model',
      ],
    });

    expect(models, hasLength(2));
    expect(models.first.id, 'glm-5.3');
    expect(models.first.supportsTools, isFalse);
    expect(models.first.contextWindow, isNull);
    expect(models.last.id, 'kimi-k3');
    expect(models.last.name, 'Kimi K3');
    expect(models.last.supportsTools, isTrue);
    expect(models.last.contextWindow, 262144);
  });

  test('an invalid payload yields an empty catalog', () {
    expect(OpenCodeModels.parseModels(null), isEmpty);
    expect(OpenCodeModels.parseModels({'data': 'nope'}), isEmpty);
  });
}
