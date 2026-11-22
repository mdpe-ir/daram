import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/money/currency.dart';
import '../../../core/services/api_key_store.dart';
import '../../ai/domain/ai_log.dart';
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
  static const _aiLogsKey = 'ai.diagnostics';

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
    final provider = AIProviderKind.fromStorage(
      _prefs.getString(_providerKey) ?? '',
    );
    final apiKey = await _readKeyFor(provider);
    final storedBaseUrl = _prefs.getString(_baseUrlKey)?.trim() ?? '';
    final storedModel = _prefs.getString(_modelKey)?.trim() ?? '';
    // A managed provider with a foreign URL is a config left behind by an older
    // app version (or another provider), so its model is stale too.
    final staleManagedConfig =
        provider.usesManagedEndpoint &&
        storedBaseUrl.isNotEmpty &&
        storedBaseUrl != provider.defaultBaseUrl;
    final config = AIConfig(
      provider: provider,
      // Vendor-managed providers always use their fixed gateway. A stale
      // custom URL from another provider must not follow the user here.
      baseUrl: provider.usesManagedEndpoint
          ? provider.defaultBaseUrl
          : storedBaseUrl.isEmpty
          ? provider.defaultBaseUrl
          : storedBaseUrl,
      model: staleManagedConfig || storedModel.isEmpty
          ? provider.defaultModel
          : storedModel,
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
      await _keys.write(apiKey.trim(), scope: config.provider.name);
    }
  }

  Future<void> clearApiKey(AIProviderKind provider) async {
    await _keys.delete(scope: provider.name);
    // Remove the pre-scoping slot too; it has been migrated to [provider] by
    // `load()` and must never be reused by another provider.
    final legacy = await _keys.read();
    if (legacy != null && legacy.trim().isNotEmpty) {
      await _keys.delete();
    }
  }

  Future<String?> readApiKey(AIProviderKind provider) async {
    final value = await _keys.read(scope: provider.name);
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  List<AILogEntry> loadAILogs() {
    final raw = _prefs.getString(_aiLogsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?AILogEntry.fromJson(item)];
    } on Object {
      return const [];
    }
  }

  Future<void> saveAILogs(List<AILogEntry> entries) async {
    if (entries.isEmpty) {
      await _prefs.remove(_aiLogsKey);
      return;
    }
    await _prefs.setString(
      _aiLogsKey,
      jsonEncode([for (final entry in entries) entry.toJson()]),
    );
  }

  /// Reads the provider-scoped key, migrating the old single key once.
  Future<String> _readKeyFor(AIProviderKind provider) async {
    final scoped = await readApiKey(provider);
    if (scoped != null) return scoped;
    final legacy = (await _keys.read())?.trim() ?? '';
    if (legacy.isEmpty) return '';
    try {
      await _keys.write(legacy, scope: provider.name);
      await _keys.delete();
    } on Object {
      // Keep using the legacy key for this session; the next save retries.
    }
    return legacy;
  }

  ThemeMode _themeModeFromStorage(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
