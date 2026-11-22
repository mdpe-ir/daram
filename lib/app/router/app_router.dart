import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/localization/fa_strings.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/records/presentation/records_shell_screen.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/settings/presentation/ai_settings_screen.dart';
import '../../features/settings/presentation/categories_screen.dart';
import '../../features/settings/presentation/data_management_screen.dart';
import '../../features/settings/presentation/logs_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/sms/presentation/sms_review_screen.dart';
import '../../features/sms/presentation/sms_sender_conversation.dart';
import '../app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: '/sms',
        builder: (context, state) => const SmsReviewScreen(),
      ),
      GoRoute(
        path: '/sms/senders',
        builder: (context, state) => const SmsSenderConversation(),
      ),
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: OnboardingScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chat',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ChatScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DashboardScreen()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/records',
                redirect: (context, state) =>
                    state.uri.path == '/records' ? '/records/accounts' : null,
                routes: [
                  for (final section in RecordsSection.values)
                    GoRoute(
                      path: section.name,
                      builder: (context, state) =>
                          RecordsShellScreen(section: section),
                    ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'ai',
                    builder: (context, state) => const AISettingsScreen(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) => const CategoriesScreen(),
                  ),
                  GoRoute(
                    path: 'data',
                    builder: (context, state) => const DataManagementScreen(),
                  ),
                  GoRoute(
                    path: 'logs',
                    builder: (context, state) => const LogsScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.circleAlert, size: 44),
              const SizedBox(height: 16),
              Text(
                'صفحه پیدا نشد',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go('/chat'),
                child: const Text(FaStrings.navChat),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});
