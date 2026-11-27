import 'package:daram/app/app.dart';
import 'package:daram/app/app_providers.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/chat/data/chat_repository.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

void main() {
  testWidgets(
    'user messages sit on the physical right and assistant messages on the left',
    (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings.onboarding_complete': true,
        'settings.currency_unit': 'toman',
        'ai.model': 'test-model',
      });
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase.memory();
      addTearDown(db.close);

      final chat = ChatRepository(db);
      final session = await chat.createSession(title: 'چیدمان');
      await chat.addMessage(
        sessionId: session.id,
        role: ChatRole.user,
        content: 'پیام من',
        type: ChatMessageType.text,
      );
      await chat.addMessage(
        sessionId: session.id,
        role: ChatRole.assistant,
        content: 'پاسخ ربات',
        type: ChatMessageType.text,
      );

      final settings = SettingsRepository(prefs, TestKeyStore('sk-test'));
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(settings),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DaramApp(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      final mine = tester.getRect(find.byType(SelectableText));
      final reply = tester.getRect(find.byType(MarkdownBody));

      // The app is RTL, yet each side is physical: mine on the right.
      expect(mine.center.dx, greaterThan(width / 2));
      expect(mine.right, greaterThan(width - 40));

      // The assistant reply hugs its avatar on the physical left.
      expect(reply.center.dx, lessThan(width / 2));
      expect(reply.left, lessThan(80));
    },
  );
}
