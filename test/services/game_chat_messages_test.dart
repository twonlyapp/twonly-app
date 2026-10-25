import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/game_chat_messages.dart';

StoredMessage message(
  String id,
  int seconds, {
  String? instance,
  bool card = false,
}) {
  return StoredMessage(
    groupId: 'chat',
    messageId: id,
    type: card ? MessageType.webxdcApp.name : MessageType.text.name,
    content: 'Played a move',
    additionalMessageData: instance == null
        ? null
        : AdditionalMessageData(
            webxdcOrigin: WebxdcOrigin(instanceId: instance, appId: 'chess'),
          ).writeToBuffer(),
    createdAtSeconds: databaseSeconds(
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
    ),
    mediaStored: false,
    mediaReopened: false,
    isDeletedFromSender: false,
    isWidgetMedia: false,
    isStory: false,
  );
}

void main() {
  test('only the original game card remains despite cached move text', () {
    final ordered = arrangeGameMessages([
      message('old-info', 100, instance: 'card'),
      message('a-latest-info', 300, instance: 'card'),
      message('b-person', 300),
      message('card', 300, card: true),
    ]);
    expect(ordered.map((m) => m.messageId), [
      'b-person',
      'card',
    ]);
  });

  test('game instances remain independent and shared app text is retained', () {
    final ordered = arrangeGameMessages([
      message('old-info', 100, instance: 'card'),
      message('other', 200, card: true),
      message('other-info', 200, instance: 'other'),
      message('shared-text', 250, instance: 'card'),
      message('card', 300, card: true),
      message('latest-info', 300, instance: 'card'),
    ]);
    expect(ordered.map((m) => m.messageId), [
      'other',
      'shared-text',
      'card',
    ]);
    expect(
      ordered.last.createdAt,
      databaseDate(
        databaseSeconds(
          DateTime.fromMillisecondsSinceEpoch(300000),
        ),
      ),
    );
  });

  test('each move has its own identity even within the same second', () {
    final first = message('card', 300, card: true);
    final next = StoredMessage(
      groupId: first.groupId,
      messageId: first.messageId,
      activityMessageId: 'next-turn-info',
      type: first.type,
      mediaStored: false,
      mediaReopened: false,
      isDeletedFromSender: false,
      isWidgetMedia: false,
      isStory: false,
      createdAtSeconds: first.createdAtSeconds,
    );
    expect(messageActivityId(first), 'card');
    expect(messageActivityId(next), 'next-turn-info');
    expect(
      next
          .copyWith(content: const NullableText(value: 'copy'))
          .activityMessageId,
      'next-turn-info',
    );
  });

  test(
    'expired info leaves its card visible and malformed data stays readable',
    () {
      final card = message('card', 100, card: true);
      final malformed = message('malformed-info', 200).copyWith(
        additionalMessageData: NullableBytes(value: Uint8List.fromList([255])),
      );
      expect(arrangeGameMessages([card, malformed]), [card, malformed]);
    },
  );
}
