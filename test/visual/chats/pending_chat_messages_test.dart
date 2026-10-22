import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/pending_chat_messages.dart';

void main() {
  test(
    'pending text and sticker retain content, quote and storage timestamp',
    () {
      withClock(Clock.fixed(DateTime(2026, 10, 10, 12, 0, 0, 789)), () {
        final pending = PendingChatMessages();
        final payload = Uint8List.fromList([1, 2, 3]);
        final message = pending.add(
          groupId: 'chat',
          text: 'Hello',
          quoteMessageId: 'quoted',
          additionalMessageData: payload,
        );
        expect(message.content, 'Hello');
        expect(message.quotesMessageId, 'quoted');
        expect(message.additionalMessageData, payload);
        expect(message.createdAt, DateTime(2026, 10, 10, 12));
        expect(message.senderId, isNull);
        expect(message.ackByServer, isNull);
        expect(pending.merge([]), [message]);
      });
    },
  );

  test('rapid sends keep order while commits and acknowledgments arrive', () {
    withClock(Clock.fixed(DateTime(2026, 10, 10, 12)), () {
      final pending = PendingChatMessages();
      final first = pending.add(groupId: 'chat', text: 'First');
      final second = pending.add(groupId: 'chat', text: 'Second');
      final third = pending.add(groupId: 'chat', text: 'Third');
      expect(pending.merge([]), [first, second, third]);

      final storedSecond = second.copyWith(
        ackByServer: NullableInt(value: databaseSeconds(second.createdAt)),
      );
      expect(pending.merge([storedSecond]), [first, storedSecond, third]);
      expect(pending.contains(second.messageId), isFalse);
      expect(pending.contains(first.messageId), isTrue);
      expect(pending.merge([third, storedSecond, first]), [
        first,
        storedSecond,
        third,
      ]);
      expect(pending.contains(first.messageId), isFalse);
      expect(pending.contains(third.messageId), isFalse);
    });
  });

  test(
    'failed persistence can be removed and retried with the same identity',
    () {
      final pending = PendingChatMessages();
      final message = pending.add(groupId: 'chat', text: 'Retry me');
      expect(pending.remove(message.messageId), isTrue);
      expect(pending.merge([]), isEmpty);
      pending.track(message);
      expect(pending.merge([]), [message]);
      expect(pending.merge([message]), [message]);
      expect(pending.remove(message.messageId), isFalse);
    },
  );
}
