import 'package:flutter/material.dart';

import '../../../core/money/currency.dart';
import '../../ai/domain/ai_models.dart';

/// All user preferences.
@immutable
final class AppSettings {
  const AppSettings({
    required this.themeMode,
    required this.currencyUnit,
    required this.persianDigits,
    required this.onboardingComplete,
    required this.aiConfig,
    required this.hasApiKey,
  });

  const AppSettings.defaults()
    : themeMode = ThemeMode.system,
      currencyUnit = CurrencyUnit.toman,
      persianDigits = true,
      onboardingComplete = false,
      aiConfig = const AIConfig(
        provider: AIProviderKind.openAICompatible,
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini',
        apiKey: '',
      ),
      hasApiKey = false;

  final ThemeMode themeMode;
  final CurrencyUnit currencyUnit;
  final bool persianDigits;
  final bool onboardingComplete;
  final AIConfig aiConfig;

  /// Whether a key is present in secure storage.
  final bool hasApiKey;

  bool get isAIConfigured => aiConfig.isConfigured && hasApiKey;

  AppSettings copyWith({
    ThemeMode? themeMode,
    CurrencyUnit? currencyUnit,
    bool? persianDigits,
    bool? onboardingComplete,
    AIConfig? aiConfig,
    bool? hasApiKey,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    currencyUnit: currencyUnit ?? this.currencyUnit,
    persianDigits: persianDigits ?? this.persianDigits,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    aiConfig: aiConfig ?? this.aiConfig,
    hasApiKey: hasApiKey ?? this.hasApiKey,
  );
}
