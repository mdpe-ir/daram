import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/app_providers.dart';
import '../../../data/database/app_database.dart';
import '../data/sms_ai_classifier.dart';
import '../data/sms_inbox.dart';
import '../data/sms_review_repository.dart';
import '../data/sms_scan_service.dart';

final smsInboxProvider = Provider<SmsInbox>((ref) => SmsInbox());

final smsReviewRepositoryProvider = Provider<SmsReviewRepository>(
  (ref) => SmsReviewRepository(
    ref.watch(databaseProvider),
    ref.watch(transactionRepositoryProvider),
  ),
);

final smsDraftsProvider = StreamProvider<List<SmsSuggestionRow>>(
  (ref) => ref.watch(smsReviewRepositoryProvider).watchOpen(),
);

final smsControllerProvider = NotifierProvider<SmsController, SmsState>(
  SmsController.new,
);

class SmsState {
  const SmsState({
    required this.enabled,
    required this.aiEnabled,
    this.scanning = false,
    this.candidates = const [],
    this.error,
  });

  final bool enabled;
  final bool aiEnabled;
  final bool scanning;
  final List<SenderCandidate> candidates;
  final String? error;
}

class SmsController extends Notifier<SmsState> {
  Timer? _timer;
  bool _again = false;

  @override
  SmsState build() {
    ref.onDispose(() => _timer?.cancel());
    final settings = ref.watch(settingsRepositoryProvider);
    return SmsState(
      enabled: settings.smsEnabled,
      aiEnabled: settings.smsAiEnabled,
    );
  }

  Future<bool> enable() async {
    final inbox = ref.read(smsInboxProvider);
    if (!await inbox.requestPermission()) return false;
    await ref.read(settingsRepositoryProvider).setSmsEnabled(true);
    state = SmsState(enabled: true, aiEnabled: state.aiEnabled);
    unawaited(refresh());
    return true;
  }

  Future<void> disable() async {
    await ref.read(settingsRepositoryProvider).setSmsEnabled(false);
    await ref.read(smsInboxProvider).observe(null);
    _timer?.cancel();
    state = SmsState(
      enabled: false,
      aiEnabled: state.aiEnabled,
      scanning: state.scanning,
    );
  }

  Future<void> setAiEnabled(bool enabled) async {
    await ref.read(settingsRepositoryProvider).setSmsAiEnabled(enabled);
    state = SmsState(
      enabled: state.enabled,
      aiEnabled: enabled,
      scanning: state.scanning,
      candidates: state.candidates,
    );
    if (enabled) unawaited(refresh());
  }

  Future<void> refresh() async {
    if (!SmsInbox.supported || !state.enabled) return;
    if (state.scanning) {
      _again = true;
      return;
    }
    state = SmsState(
      enabled: true,
      aiEnabled: state.aiEnabled,
      scanning: true,
      candidates: state.candidates,
    );
    var candidates = state.candidates;
    String? error;
    try {
      final inbox = ref.read(smsInboxProvider);
      if (!await inbox.hasPermission()) {
        await inbox.observe(null);
        error = 'دسترسی پیامک را در تنظیمات اندروید فعال کن.';
        return;
      }
      if (!ref.mounted || !state.enabled) return;
      await inbox.observe(() {
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 2), () => unawaited(refresh()));
      });
      final now = DateTime.now().toUtc();
      final preferences = ref.read(settingsRepositoryProvider);
      final settings = ref.read(settingsControllerProvider).value;
      final config = state.aiEnabled && settings?.isAIConfigured == true
          ? settings!.aiConfig
          : null;
      final classifier = config == null
          ? null
          : SmsAiClassifier(
              ref.read(aiProviderRegistryProvider).forKind(config.provider),
              config,
            );
      final service = SmsScanService(
        inbox,
        ref.read(smsReviewRepositoryProvider),
      );
      final accounts = await ref.read(accountRepositoryProvider).list();
      final categories = await ref.read(categoryRepositoryProvider).list();
      if (!ref.mounted || !state.enabled) return;
      candidates = await service.scan(
        now: now,
        lastScan: preferences.smsLastScan,
        accounts: accounts,
        categories: categories,
        classifier: classifier,
        isEnabled: () => ref.mounted && state.enabled,
        canUseAi: () => ref.mounted && state.enabled && state.aiEnabled,
      );
      if (ref.mounted && state.enabled) await preferences.setSmsLastScan(now);
    } on Object {
      error = 'خواندن پیامک‌ها انجام نشد. دوباره تلاش کن.';
    } finally {
      if (ref.mounted) {
        state = SmsState(
          enabled: state.enabled,
          aiEnabled: state.aiEnabled,
          candidates: state.enabled ? candidates : const [],
          error: state.enabled ? error : null,
        );
        if (_again) {
          _again = false;
          unawaited(refresh());
        }
      }
    }
  }
}
