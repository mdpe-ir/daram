import 'package:daram/app/app.dart';
import 'package:daram/app/app_providers.dart';
import 'package:daram/core/domain/enums.dart';
import 'package:daram/core/money/rial.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/settings/data/settings_repository.dart';
import 'package:daram/features/sms/presentation/sms_controller.dart';
import 'package:daram/features/transactions/domain/transaction_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_key_store.dart';

void main() {
  testWidgets(
    'reviews and confirms a matched SMS from chat on a small screen',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now().millisecondsSinceEpoch;
      final calls = <String>[];
      const channel = MethodChannel('ir.daram.daram/sms');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return switch (call.method) {
          'hasPermission' => true,
          'observe' => null,
          'messages' => [
            {
              'id': 1,
              'sender': '1001',
              'date': now,
              'body': 'برداشت: ۲۰۰٬۰۰۰ ریال',
            },
            {
              'id': 2,
              'sender': '1002',
              'date': now,
              'body': 'صورتحساب پارکینگ: ۲۰٬۰۰۰ تومان',
            },
            {
              'id': 3,
              'sender': '1001',
              'date': now,
              'body': 'رمز دوم: ۹۹۹۹۹ مبلغ: ۲۰۰٬۰۰۰ ریال',
            },
          ],
          _ => throw MissingPluginException(call.method),
        };
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      SharedPreferences.setMockInitialValues({
        'settings.onboarding_complete': true,
        'sms.enabled': true,
      });
      final settings = SettingsRepository(
        await SharedPreferences.getInstance(),
        TestKeyStore(''),
      );
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          settingsRepositoryProvider.overrideWithValue(settings),
        ],
      );
      addTearDown(container.dispose);
      await container.read(categoryRepositoryProvider).ensureDefaults();
      final account = await container
          .read(accountRepositoryProvider)
          .create(
            bankId: 'mellat',
            bankName: 'بانک ملت',
            accountName: 'ملت',
            accountType: AccountType.bank,
            initialBalance: Rial.zero,
            operationId: 'seed-account',
          );
      await container.read(smsReviewRepositoryProvider).setSenders(account.id, {
        '1001',
      }, includeHistory: true);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DaramApp(),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(calls, containsAll(['observe', 'messages']));

      await tester.tap(find.byTooltip('بازبینی پیامک‌ها'));
      await tester.pumpAndSettle();
      expect(find.text('پارکینگ'), findsOneWidget);
      expect(find.text('با پیامک مرتبط تطبیق داده شد.'), findsOneWidget);
      expect(find.text('تأیید'), findsOneWidget);
      await tester.ensureVisible(find.text('تأیید'));
      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();
      expect(find.text('پیشنهاد تازه‌ای برای بازبینی نداری.'), findsOneWidget);
      final records = await container
          .read(transactionRepositoryProvider)
          .list(const TransactionFilter());
      expect(records.single.amountRial, Rial(200000));
      expect(records.single.description, 'پارکینگ');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
