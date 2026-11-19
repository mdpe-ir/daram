import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/money/currency.dart';
import '../../../core/services/api_key_store.dart';
import '../../ai/domain/ai_models.dart';
import '../domain/app_settings.dart';

/// Persists preferences in `shared_preferences` and the API key in secure
/// storage. The key is never written to preferences or logs.
class SettingsRepository {
  SettingsRepository(this._prefs, this._keys);

  final SharedPreferences _prefs;
  final ApiKeyStore _keys;

  static const _themeKey = 'settings.theme_mode';
  static const _currencyKey = 'settings.currency_unit';
  static const _digitsKey = 'settings.persian_digits';
  static const _onboardingKey = 'settings.onboarding_complete';
  static const _providerKey = 'ai.provider';
  static const _baseUrlKey = 'ai.base_url';
  static const _modelKey = 'ai.model';
  static const _timeoutKey = 'ai.timeout_seconds';
  static const _toolModeKey = 'ai.tool_mode';
  static const _maxTokensKey = 'ai.max_tokens';

  bool get smsAiEnabled => _prefs.getBool('sms.ai_enabled') ?? false;

  Future<void> setSmsAiEnabled(bool enabled) async {
    await _prefs.setBool('sms.ai_enabled', enabled);
  }

  bool get smsEnabled => _prefs.getBool('sms.enabled') ?? false;

  Future<void> setSmsEnabled(bool enabled) async {
    await _prefs.setBool('sms.enabled', enabled);
  }

  DateTime? get smsLastScan {
    final value = _prefs.getInt('sms.last_scan');
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  Future<void> setSmsLastScan(DateTime date) async {
    await _prefs.setInt('sms.last_scan', date.millisecondsSinceEpoch);
  }

  Future<AppSettings> load() async {
    final apiKey = await _keys.read() ?? '';
    final provider = AIProviderKind.fromStorage(
      _prefs.getString(_providerKey) ?? '',
    );
    final config = AIConfig(
      provider: provider,
      baseUrl: _prefs.getString(_baseUrlKey) ?? provider.defaultBaseUrl,
      model: _prefs.getString(_modelKey) ?? provider.defaultModel,
      apiKey: apiKey,
      timeoutSeconds: _prefs.getInt(_timeoutKey) ?? 90,
      toolMode: AIToolMode.fromStorage(_prefs.getString(_toolModeKey) ?? ''),
      maxTokens: _prefs.getInt(_maxTokensKey) ?? 2048,
    );
    return AppSettings(
      themeMode: _themeModeFromStorage(_prefs.getString(_themeKey)),
      currencyUnit:
          CurrencyUnit.tryParse(_prefs.getString(_currencyKey)) ??
          CurrencyUnit.toman,
      persianDigits: _prefs.getBool(_digitsKey) ?? true,
      onboardingComplete: _prefs.getBool(_onboardingKey) ?? false,
      aiConfig: config,
      hasApiKey: apiKey.trim().isNotEmpty,
    );
  }

  Future<void> saveTheme(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> saveCurrency(CurrencyUnit unit) async {
    await _prefs.setString(_currencyKey, unit.name);
  }

  Future<void> savePersianDigits(bool enabled) async {
    await _prefs.setBool(_digitsKey, enabled);
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_onboardingKey, true);
  }

  Future<void> saveAIConfig(AIConfig config, {String? apiKey}) async {
    await _prefs.setString(_providerKey, config.provider.name);
    await _prefs.setString(_baseUrlKey, config.baseUrl.trim());
    await _prefs.setString(_modelKey, config.model.trim());
    await _prefs.setInt(_timeoutKey, config.timeoutSeconds);
    await _prefs.setString(_toolModeKey, config.toolMode.name);
    await _prefs.setInt(_maxTokensKey, config.maxTokens);
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      await _keys.write(apiKey.trim());
    }
  }

  Future<void> clearApiKey() => _keys.delete();

  Future<String?> readApiKey() => _keys.read();

  ThemeMode _themeModeFromStorage(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
