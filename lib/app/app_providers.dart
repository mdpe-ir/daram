import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants/app_info.dart';
import '../core/money/currency.dart';
import '../core/services/api_key_store.dart';
import '../data/database/app_database.dart';
import '../features/accounts/data/account_repository.dart';
import '../features/ai/data/ai_chat_service.dart';
import '../features/ai/data/ai_log_store.dart';
import '../features/ai/data/ai_provider_registry.dart';
import '../features/ai/data/open_code_models.dart';
import '../features/ai/data/prompt_builder.dart';
import '../features/ai/data/tool_executor.dart';
import '../features/ai/data/tool_registry.dart';
import '../features/ai/domain/ai_models.dart';
import '../features/assets/data/asset_repository.dart';
import '../features/categories/data/category_repository.dart';
import '../features/categories/domain/category.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/chat/data/confirmation_service.dart';
import '../features/chat/data/undo_service.dart';
import '../features/dashboard/data/analytics_repository.dart';
import '../features/loans/data/loan_repository.dart';
import '../features/market/data/market_price_service.dart';
import '../features/obligations/data/obligation_repository.dart';
import '../features/settings/data/export_service.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/sms/data/sms_review_repository.dart';
import '../features/transactions/data/operation_repository.dart';
import '../features/transactions/data/transaction_repository.dart';
import '../features/transactions/data/transfer_repository.dart';

/// Overridden in `main()` and in tests.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

/// Overridden in `main()` and in tests (SharedPreferences + secure storage).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) =>
      throw UnimplementedError('settingsRepositoryProvider must be overridden'),
);

/// Injected in tests to use a memory implementation without platform channels.
final apiKeyStoreProvider = Provider<ApiKeyStore>((ref) => SecureApiKeyStore());

/// Version name and build code as reported by the platform (pubspec version on
/// Android/iOS, `version.json` on Linux/web).
final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

final operationRepositoryProvider = Provider<OperationRepository>(
  (ref) => OperationRepository(ref.watch(databaseProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(databaseProvider)),
);

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(
    ref.watch(databaseProvider),
    ref.watch(operationRepositoryProvider),
  ),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(
    ref.watch(databaseProvider),
    ref.watch(operationRepositoryProvider),
  ),
);

final transferRepositoryProvider = Provider<TransferRepository>(
  (ref) => TransferRepository(
    ref.watch(databaseProvider),
    ref.watch(operationRepositoryProvider),
  ),
);

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepository(
    ref.watch(databaseProvider),
    ref.watch(operationRepositoryProvider),
  ),
);

final obligationRepositoryProvider = Provider<ObligationRepository>(
  (ref) => ObligationRepository(ref.watch(databaseProvider)),
);

final assetRepositoryProvider = Provider<AssetRepository>(
  (ref) => AssetRepository(ref.watch(databaseProvider)),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepository(
    ref.watch(databaseProvider),
    ref.watch(accountRepositoryProvider),
    ref.watch(transactionRepositoryProvider),
    ref.watch(loanRepositoryProvider),
  ),
);

final exportServiceProvider = Provider<ExportService>(
  (ref) => ExportService(
    db: ref.watch(databaseProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    analytics: ref.watch(analyticsRepositoryProvider),
  ),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.watch(databaseProvider)),
);

final confirmationServiceProvider = Provider<ConfirmationService>(
  (ref) => ConfirmationService(
    db: ref.watch(databaseProvider),
    chat: ref.watch(chatRepositoryProvider),
    accounts: ref.watch(accountRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    transfers: ref.watch(transferRepositoryProvider),
    loans: ref.watch(loanRepositoryProvider),
    assets: ref.watch(assetRepositoryProvider),
    obligations: ref.watch(obligationRepositoryProvider),
    operations: ref.watch(operationRepositoryProvider),
  ),
);

final undoServiceProvider = Provider<UndoService>(
  (ref) => UndoService(
    ref.watch(databaseProvider),
    ref.watch(operationRepositoryProvider),
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        if (!kIsWeb) 'User-Agent': 'DARAM/${AppInfo.version}',
      },
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        // Never log headers: they contain the user's API key.
        handler.next(options);
      },
    ),
  );
  return dio;
});

/// Live market rates (fiat, gold and crypto) from DARAM's own sources.
final marketPriceServiceProvider = Provider<MarketPriceService>(
  (ref) => MarketPriceService(ref.watch(dioProvider)),
);

/// Local, bounded diagnostics used by the settings → logs screen.
final aiLogStoreProvider = Provider<AILogStore>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final store = AILogStore(
    initial: repository.loadAILogs(),
    persist: repository.saveAILogs,
  );
  ref.onDispose(store.dispose);
  return store;
});

final aiProviderRegistryProvider = Provider<AIProviderRegistry>(
  (ref) => AIProviderRegistry(
    ref.watch(dioProvider),
    logs: ref.watch(aiLogStoreProvider),
  ),
);

/// Live OpenCode / OpenCode Go model catalog for the settings picker.
final openCodeModelsProvider = Provider<OpenCodeModels>(
  (ref) => OpenCodeModels(ref.watch(dioProvider)),
);

/// Tool schemas are bundled assets, loaded once.
final toolRegistryProvider = FutureProvider<ToolRegistry>(
  (ref) => ToolRegistry.load(rootBundle),
);

/// Persian system prompt + few-shot examples, loaded once.
final promptBuilderProvider = FutureProvider<PromptBuilder>(
  (ref) => PromptBuilder.load(rootBundle),
);

final toolExecutorProvider = FutureProvider<ToolExecutor>((ref) async {
  final registry = await ref.watch(toolRegistryProvider.future);
  final marketRates = ref.watch(marketPriceServiceProvider);
  return ToolExecutor(
    registry: registry,
    accounts: ref.watch(accountRepositoryProvider),
    categories: ref.watch(categoryRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    loans: ref.watch(loanRepositoryProvider),
    analytics: ref.watch(analyticsRepositoryProvider),
    sms: SmsReviewRepository(
      ref.watch(databaseProvider),
      ref.watch(transactionRepositoryProvider),
    ),
    chat: ref.watch(chatRepositoryProvider),
    assets: ref.watch(assetRepositoryProvider),
    obligations: ref.watch(obligationRepositoryProvider),
    transfers: ref.watch(transferRepositoryProvider),
    marketRates: (kind, code) => marketRates.quoteForAsset(kind, code: code),
  );
});

final aiChatServiceProvider = FutureProvider<AIChatService>((ref) async {
  final registry = await ref.watch(toolRegistryProvider.future);
  final executor = await ref.watch(toolExecutorProvider.future);
  return AIChatService(
    providers: ref.watch(aiProviderRegistryProvider),
    tools: registry,
    executor: executor,
    logs: ref.watch(aiLogStoreProvider),
  );
});

/// Live account list (balances derived from the ledger).
final accountsStreamProvider = StreamProvider.autoDispose(
  (ref) => ref
      .watch(accountRepositoryProvider)
      .watchWithBalances(includeArchived: true),
);

final categoriesStreamProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watch(),
);

class SettingsController extends AsyncNotifier<AppSettings> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  @override
  Future<AppSettings> build() => _repository.load();

  AppSettings get _current => state.value ?? const AppSettings.defaults();

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(_current.copyWith(themeMode: mode));
    await _repository.saveTheme(mode);
  }

  Future<void> setCurrency(CurrencyUnit unit) async {
    state = AsyncData(_current.copyWith(currencyUnit: unit));
    await _repository.saveCurrency(unit);
  }

  Future<void> setPersianDigits(bool enabled) async {
    state = AsyncData(_current.copyWith(persianDigits: enabled));
    await _repository.savePersianDigits(enabled);
  }

  Future<void> completeOnboarding() async {
    state = AsyncData(_current.copyWith(onboardingComplete: true));
    await _repository.completeOnboarding();
  }

  Future<void> saveAIConfig(
    AIConfig config, {
    bool replaceApiKey = false,
  }) async {
    String? keyToStore;
    if (replaceApiKey && config.apiKey.trim().isNotEmpty) {
      keyToStore = config.apiKey.trim();
    }
    await _repository.saveAIConfig(config, apiKey: keyToStore);
    final storedKey =
        keyToStore ?? await _repository.readApiKey(config.provider) ?? '';
    state = AsyncData(
      _current.copyWith(
        aiConfig: config.copyWith(apiKey: storedKey),
        hasApiKey: storedKey.trim().isNotEmpty,
      ),
    );
  }

  Future<String?> storedApiKey(AIProviderKind provider) =>
      _repository.readApiKey(provider);

  /// Clears the key of [provider] (the saved provider by default).
  Future<void> clearApiKey([AIProviderKind? provider]) async {
    final target = provider ?? _current.aiConfig.provider;
    await _repository.clearApiKey(target);
    if (target != _current.aiConfig.provider) return;
    state = AsyncData(
      _current.copyWith(
        hasApiKey: false,
        aiConfig: _current.aiConfig.copyWith(apiKey: ''),
      ),
    );
  }
}
