import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/app_providers.dart';
import 'core/services/api_key_store.dart';
import 'data/database/app_database.dart';
import 'features/categories/data/category_repository.dart';
import 'features/settings/data/settings_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Color(0xFF080C15),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  try {
    if (!kReleaseMode) debugPrint('DARAM: opening local database');
    final database = AppDatabase.production();
    if (!kReleaseMode) debugPrint('DARAM: database object created');
    final preferences = await SharedPreferences.getInstance();
    if (!kReleaseMode) debugPrint('DARAM: preferences ready');
    final settingsRepository = SettingsRepository(
      preferences,
      SecureApiKeyStore(),
    );

    // First-run category seeding is idempotent.
    await CategoryRepository(database).ensureDefaults();
    if (!kReleaseMode) debugPrint('DARAM: database ready');

    runApp(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
        ],
        child: const DaramApp(),
      ),
    );
  } on Object catch (error, stack) {
    if (!kReleaseMode) {
      debugPrint('DARAM startup failed: $error');
      debugPrintStack(stackTrace: stack);
    }
    runApp(_StartupErrorApp(error: error));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Color(0xFF080C15),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Color(0xFFFF5C7A), size: 48),
                  SizedBox(height: 16),
                  Text(
                    'دارام نتوانست پایگاه داده محلی را باز کند.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'فضای ذخیره‌سازی دستگاه را بررسی کن و دوباره برنامه را باز کن.',
                    style: TextStyle(color: Color(0xFFA3AEC2)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
