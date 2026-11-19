import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/fa_strings.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/sms/data/sms_inbox.dart';
import '../features/sms/presentation/sms_controller.dart';
import 'app_providers.dart';
import 'design_system/daram_widgets.dart';
import 'router/app_router.dart';
import 'theme/daram_theme.dart';

class DaramApp extends ConsumerStatefulWidget {
  const DaramApp({super.key});

  @override
  ConsumerState<DaramApp> createState() => _DaramAppState();
}

class _DaramAppState extends ConsumerState<DaramApp> {
  AppLifecycleListener? _smsLifecycle;

  @override
  void initState() {
    super.initState();
    if (!SmsInbox.supported) return;
    _smsLifecycle = AppLifecycleListener(onResume: _refreshSms);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshSms());
  }

  void _refreshSms() {
    if (mounted) ref.read(smsControllerProvider.notifier).refresh();
  }

  @override
  void dispose() {
    _smsLifecycle?.dispose();
    super.dispose();
  }

  static bool get _desktopPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    if (SmsInbox.supported) {
      ref.listen(settingsControllerProvider, (previous, next) {
        final before = previous?.value?.aiConfig;
        final after = next.value?.aiConfig;
        if (after?.isConfigured == true &&
            (before?.apiKey != after!.apiKey ||
                before?.provider != after.provider ||
                before?.model != after.model ||
                before?.baseUrl != after.baseUrl)) {
          _refreshSms();
        }
      });
    }
    final value = settings.value ?? const AppSettings.defaults();
    final format = DaramFormat(
      unit: value.currencyUnit,
      persianDigits: value.persianDigits,
    );

    return DaramFormatScope(
      format: format,
      child: MaterialApp.router(
        title: FaStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: DaramTheme.light(),
        darkTheme: DaramTheme.dark(),
        themeMode: value.themeMode,
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa', 'IR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        themeAnimationDuration: const Duration(milliseconds: 260),
        themeAnimationCurve: Curves.easeOutCubic,
        routerConfig: ref.watch(routerProvider),
        builder: _responsiveFrame,
      ),
    );
  }

  /// DARAM is a phone-first product. On desktop and in wide browser windows
  /// it renders inside a centered 600 px frame instead of stretching the
  /// mobile layout across a large display.
  Widget _responsiveFrame(BuildContext context, Widget? child) {
    if (child == null) return const SizedBox.shrink();
    final media = MediaQuery.of(context);
    if (!_desktopPlatform || media.size.width <= 620) return child;

    const frameWidth = 600.0;
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: Center(
        child: Container(
          width: frameWidth,
          height: media.size.height,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.symmetric(
              vertical: BorderSide(color: theme.dividerColor),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: MediaQuery(
            data: media.copyWith(size: Size(frameWidth, media.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}
