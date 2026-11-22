import 'package:daram/app/app_providers.dart';
import 'package:daram/app/theme/daram_theme.dart';
import 'package:daram/features/ai/data/ai_log_store.dart';
import 'package:daram/features/ai/domain/ai_log.dart';
import 'package:daram/features/settings/presentation/logs_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('logs screen filters errors, expands details and clears', (
    tester,
  ) async {
    final now = DateTime.now();
    final store = AILogStore(
      initial: <AILogEntry>[
        AILogEntry(
          time: now,
          level: AILogLevel.info,
          area: AILogArea.chat,
          title: 'شروع درخواست دستیار',
          detail: 'mode: native',
        ),
        AILogEntry(
          time: now.subtract(const Duration(seconds: 3)),
          level: AILogLevel.error,
          area: AILogArea.network,
          title: 'خطای شبکه: زمان انتظار تمام شد',
          detail: 'type: receiveTimeout\nurl: https://example.com',
        ),
      ],
    );
    addTearDown(store.dispose);
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiLogStoreProvider.overrideWithValue(store)],
        child: MaterialApp(theme: DaramTheme.dark(), home: const LogsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('شروع درخواست دستیار'), findsOneWidget);
    expect(find.text('خطای شبکه: زمان انتظار تمام شد'), findsOneWidget);

    await tester.tap(find.textContaining('فقط خطاها'));
    await tester.pumpAndSettle();
    expect(find.text('شروع درخواست دستیار'), findsNothing);
    expect(find.text('خطای شبکه: زمان انتظار تمام شد'), findsOneWidget);

    await tester.tap(find.text('خطای شبکه: زمان انتظار تمام شد'));
    await tester.pumpAndSettle();
    expect(find.textContaining('type: receiveTimeout'), findsOneWidget);

    await tester.tap(find.byTooltip('پاک کردن گزارش‌ها'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('پاک کردن'));
    await tester.pumpAndSettle();

    expect(find.text('خطایی ثبت نشده'), findsOneWidget);
    expect(store.isEmpty, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
