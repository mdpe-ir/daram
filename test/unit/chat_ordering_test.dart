import 'package:daram/core/domain/enums.dart';
import 'package:daram/data/database/app_database.dart';
import 'package:daram/features/chat/data/chat_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ChatRepository chat;

  setUp(() {
    db = AppDatabase.memory();
    chat = ChatRepository(db);
  });

  tearDown(() async => db.close());

  test(
    'messages keep insertion order even with same-second timestamps',
    () async {
      final session = await chat.createSession();
      for (var i = 0; i < 6; i++) {
        await chat.addMessage(
          sessionId: session.id,
          role: i.isEven ? ChatRole.user : ChatRole.assistant,
          content: 'message-$i',
          type: ChatMessageType.text,
        );
      }
      final messages = await chat.messages(session.id);
      expect(messages.map((m) => m.content).toList(), [
        'message-0',
        'message-1',
        'message-2',
        'message-3',
        'message-4',
        'message-5',
      ]);

      final sessions = await chat.listSessions();
      expect(sessions.single.messageCount, 6);
      expect(sessions.single.preview, 'message-4');
    },
  );
}
