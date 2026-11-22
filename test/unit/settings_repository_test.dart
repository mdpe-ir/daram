import 'package:daram/features/ai/domain/ai_log.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

void main() {
  test('the legacy key migrates to the saved provider scope', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ai.provider': 'openCode',
      'ai.base_url': 'https://ai.liara.ir/api/stale',
      'ai.model': 'openai/gpt-6-luna',
    });
    final prefs = await SharedPreferences.getInstance();
    final keys = TestKeyStore('oc_sk_legacy');
    final repository = SettingsRepository(prefs, keys);

    final loaded = await repository.load();
    expect(loaded.aiConfig.apiKey, 'oc_sk_legacy');
    expect(loaded.hasApiKey, isTrue);
    // Vendor-managed providers ignore a stale custom URL and model.
    expect(loaded.aiConfig.baseUrl, AIProviderKind.openCode.defaultBaseUrl);
    expect(loaded.aiConfig.model, AIProviderKind.openCode.defaultModel);
    expect(await keys.read(), isNull);
    expect(await keys.read(scope: 'openCode'), 'oc_sk_legacy');
  });

  test('provider keys are stored and cleared independently', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'ai.provider': 'openCode',
      'ai.model': 'glm-5.3',
    });
    final prefs = await SharedPreferences.getInstance();
    final keys = TestKeyStore('oc_sk_legacy');
    final repository = SettingsRepository(prefs, keys);

    final loaded = await repository.load();
    await repository.saveAIConfig(
      loaded.aiConfig.copyWith(
        provider: AIProviderKind.openAICompatible,
        baseUrl: 'https://proxy.example.com/v1',
        model: 'gpt-4o-mini',
        apiKey: 'sk-openai',
      ),
      apiKey: 'sk-openai',
    );

    expect(
      await repository.readApiKey(AIProviderKind.openCode),
      'oc_sk_legacy',
    );
    expect(
      await repository.readApiKey(AIProviderKind.openAICompatible),
      'sk-openai',
    );

    await repository.clearApiKey(AIProviderKind.openAICompatible);
    expect(
      await repository.readApiKey(AIProviderKind.openAICompatible),
      isNull,
    );
    expect(
      await repository.readApiKey(AIProviderKind.openCode),
      'oc_sk_legacy',
    );
  });

  test('diagnostics logs survive a repository round-trip', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final repository = SettingsRepository(prefs, TestKeyStore());
    final entries = <AILogEntry>[
      AILogEntry(
        time: DateTime(2026, 11, 22, 9, 15),
        level: AILogLevel.error,
        area: AILogArea.network,
        title: 'زمان انتظار تمام شد',
        detail: 'type: receiveTimeout',
      ),
    ];

    await repository.saveAILogs(entries);
    final restored = repository.loadAILogs();
    expect(restored, hasLength(1));
    expect(restored.single.title, 'زمان انتظار تمام شد');
    expect(restored.single.detail, 'type: receiveTimeout');

    await repository.saveAILogs(const []);
    expect(repository.loadAILogs(), isEmpty);
  });
}
