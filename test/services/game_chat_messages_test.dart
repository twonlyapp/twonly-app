import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/game_chat_messages.dart';

Message message(String id, int seconds, {String? instance, bool card = false}) {
  return Message(
    groupId: 'chat',
    messageId: id,
    type: card ? MessageType.webxdcApp.name : MessageType.text.name,
    content: 'Played a move',
    additionalMessageData: instance == null
        ? null
        : AdditionalMessageData(
            webxdcOrigin: WebxdcOrigin(instanceId: instance, appId: 'chess'),
          ).writeToBuffer(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(seconds * 1000),
    mediaStored: false,
    mediaReopened: false,
    isDeletedFromSender: false,
    isWidgetMedia: false,
    isStory: false,
  );
}

void main() {
  test('latest game text stays beside its card despite timestamp ties', () {
    final ordered = arrangeGameMessages([
      message('old-info', 100, instance: 'card'),
      message('a-latest-info', 300, instance: 'card'),
      message('b-person', 300),
      message('card', 300, card: true),
    ]);
    expect(ordered.map((m) => m.messageId), [
      'card',
      'a-latest-info',
      'b-person',
    ]);
  });

  test('game instances remain independent and shared app text is retained', () {
    final ordered = arrangeGameMessages([
      message('card', 100, card: true),
      message('old-info', 100, instance: 'card'),
      message('other', 200, card: true),
      message('other-info', 200, instance: 'other'),
      message('shared-text', 250, instance: 'card'),
      message('latest-info', 300, instance: 'card'),
    ]);
    expect(ordered.map((m) => m.messageId), [
      'other',
      'other-info',
      'shared-text',
      'card',
      'latest-info',
    ]);
    expect(ordered[3].createdAt, ordered[4].createdAt);
  });

  test(
    'expired info leaves its card visible and malformed data stays readable',
    () {
      final card = message('card', 100, card: true);
      final malformed = message('malformed-info', 200).copyWith(
        additionalMessageData: Value(Uint8List.fromList([255])),
      );
      expect(arrangeGameMessages([card, malformed]), [card, malformed]);
    },
  );
}
