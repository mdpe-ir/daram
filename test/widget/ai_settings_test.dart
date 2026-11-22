import 'package:daram/app/app_providers.dart';
import 'package:daram/app/theme/daram_theme.dart';
import 'package:daram/features/ai/data/open_code_models.dart';
import 'package:daram/features/ai/domain/ai_models.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:daram/features/settings/presentation/ai_settings_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

class _FakeOpenCodeModels extends OpenCodeModels {
  _FakeOpenCodeModels() : super(Dio());

  @override
  Future<List<AIModelOption>> list(AIConfig config) async => const [
    AIModelOption(
      id: 'glm-5.3',
      name: 'GLM 5.3',
      supportsTools: true,
      contextWindow: 200000,
    ),
    AIModelOption(
      id: 'kimi-k3',
      name: 'Kimi K3',
      supportsTools: true,
      contextWindow: 262144,
    ),
  ];
}

Future<ProviderContainer> _pumpScreen(
  WidgetTester tester, {
  required SettingsRepository settings,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 780));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final container = ProviderContainer(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settings),
      openCodeModelsProvider.overrideWithValue(_FakeOpenCodeModels()),
    ],
  );
  addTearDown(container.dispose);
  await container.read(settingsControllerProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: DaramTheme.dark(),
        home: const AISettingsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('OpenCode preset lets the user pick a model from the catalog', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.onboarding_complete': true,
      'ai.provider': 'openCode',
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsRepository(prefs, TestKeyStore('oc_sk_test'));
    await _pumpScreen(tester, settings: settings);

    expect(find.text('OpenCode'), findsOneWidget);
    expect(find.text('OpenCode (پرداخت اعتباری)'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byTooltip('دریافت مدل‌ها از OpenCode'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('دریافت مدل‌ها از OpenCode'));
    await tester.pumpAndSettle();

    expect(find.text('مدل‌های OpenCode'), findsOneWidget);
    expect(find.text('Kimi K3'), findsOneWidget);
    expect(find.text('GLM 5.3'), findsOneWidget);

    await tester.tap(find.text('Kimi K3'));
    await tester.pumpAndSettle();

    expect(find.text('kimi-k3'), findsOneWidget);
    expect(find.text('مدل‌های OpenCode'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('OpenCode Go only asks for the key and resets a stale endpoint', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'settings.onboarding_complete': true,
      'ai.provider': 'openAICompatible',
      'ai.base_url': 'https://proxy.example.com/v1',
      'ai.model': 'gpt-4o-mini',
    });
    final prefs = await SharedPreferences.getInstance();
    final keys = TestKeyStore('sk-openai');
    final settings = SettingsRepository(prefs, keys);
    final container = await _pumpScreen(tester, settings: settings);

    expect(find.text('https://proxy.example.com/v1'), findsOneWidget);

    await tester.tap(find.text('سازگار با OpenAI'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenCode Go').last);
    await tester.pumpAndSettle();

    expect(find.text('OpenCode Go (اشتراک)'), findsOneWidget);
    expect(find.text('https://proxy.example.com/v1'), findsNothing);
    expect(find.text('kimi-k3'), findsOneWidget);
    // Only the API-key field remains; the base URL and model are managed.
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'oc_go_test');
    await tester.scrollUntilVisible(
      find.text('ذخیره'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ذخیره'));
    await tester.pumpAndSettle();

    final saved = await container.read(settingsControllerProvider.future);
    expect(saved.aiConfig.provider, AIProviderKind.openCodeGo);
    expect(saved.aiConfig.baseUrl, AIProviderKind.openCodeGo.defaultBaseUrl);
    expect(saved.aiConfig.model, 'kimi-k3');
    expect(await settings.readApiKey(AIProviderKind.openCodeGo), 'oc_go_test');
    // Switching providers must not overwrite the other provider's key.
    expect(
      await settings.readApiKey(AIProviderKind.openAICompatible),
      'sk-openai',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
