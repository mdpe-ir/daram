import 'dart:io';

import 'package:daram/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('opens a version 2 database and keeps its existing records', () async {
    final directory = await Directory.systemTemp.createTemp('daram-migration-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/daram.sqlite');
    final before = AppDatabase(NativeDatabase(file));
    try {
      await before.customStatement(
        "INSERT INTO chat_sessions (id, title, created_at, updated_at) "
        "VALUES ('existing', 'گفتگوی قبلی', 1730000000, 1730000000)",
      );
      for (final table in [
        'sms_suggestions',
        'sms_patterns',
        'sms_sender_links',
      ]) {
        await before.customStatement('DROP TABLE $table');
      }
      await before.customStatement('PRAGMA user_version = 2');
    } finally {
      await before.close();
    }

    final migrated = AppDatabase(NativeDatabase(file));
    addTearDown(migrated.close);
    expect(
      (await migrated.select(migrated.chatSessions).get()).single.title,
      'گفتگوی قبلی',
    );
    expect(await migrated.select(migrated.smsSenderLinks).get(), isEmpty);
    expect(await migrated.select(migrated.smsSuggestions).get(), isEmpty);
    expect(await migrated.select(migrated.smsPatterns).get(), isEmpty);
  });
}
