import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/src/localization/generated/app_localizations_de.dart';
import 'package:twonly/src/localization/generated/app_localizations_en.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/game_chat_messages.dart';

StoredMessage message(
  String id,
  int seconds, {
  String? instance,
  bool card = false,
  String? activity,
  int? sender,
}) {
  return StoredMessage(
    groupId: 'chat',
    messageId: id,
    activityMessageId: activity,
    senderId: sender,
    type: card ? MessageType.webxdcApp.name : MessageType.text.name,
    content: 'Played a move',
    additionalMessageData: instance == null
        ? null
        : AdditionalMessageData(
            webxdcOrigin: WebxdcOrigin(
              instanceId: instance,
              appId: 'arbitrary-app',
            ),
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
  test('own latest game activity shows a short localized played status', () {
    final card = message('card', 100, card: true, activity: 'move-info')
        .copyWith(
          content: const NullableText(
            value: "You played Connect Four. Alex's turn.",
          ),
          additionalMessageData: NullableBytes(
            value: AdditionalMessageData(
              webxdcOrigin: WebxdcOrigin(
                instanceId: 'card',
                appId: 'unlisted-game',
                notificationContent:
                    '{"webxdc_game":"played","instance_id":"card"}',
              ),
            ).writeToBuffer(),
          ),
        );
    expect(
      gameMessageText(card, AppLocalizationsEn()),
      'You have played.',
    );
    expect(
      gameMessageText(card, AppLocalizationsDe()),
      'Du hast gespielt.',
    );
    expect(
      gameMessageText(
        message(
          'card',
          100,
          card: true,
          activity: 'move-info',
          sender: 7,
        ).copyWith(
          content: NullableText(value: card.content),
          additionalMessageData: NullableBytes(
            value: card.additionalMessageData,
          ),
        ),
        AppLocalizationsEn(),
      ),
      'Played.',
    );
    expect(
      gameMessageText(
        message('new-card', 100, card: true),
        AppLocalizationsEn(),
      ),
      'Played a move',
    );
    expect(
      gameMessageText(
        message('shared-text', 100),
        AppLocalizationsEn(),
      ),
      'Played a move',
    );
  });

  test('game activities show only the status in the reader language', () {
    for (final sender in [null, 7]) {
      for (final outcome in ['turn', 'won', 'lost', 'draw']) {
        final card =
            message(
              'card',
              100,
              card: true,
              activity: 'move-info',
              sender: sender,
            ).copyWith(
              additionalMessageData: NullableBytes(
                value: AdditionalMessageData(
                  webxdcOrigin: WebxdcOrigin(
                    instanceId: 'card',
                    notificationContent:
                        '{"webxdc_game":"$outcome","instance_id":"card"}',
                  ),
                ).writeToBuffer(),
              ),
            );
        final en = AppLocalizationsEn();
        final de = AppLocalizationsDe();
        expect(gameMessageText(card, en), switch (outcome) {
          'turn' => 'It is your turn.',
          'won' => 'You have won.',
          'lost' => 'You have lost.',
          _ => 'It is a draw.',
        });
        expect(gameMessageText(card, de), switch (outcome) {
          'turn' => 'Du bist am Zug.',
          'won' => 'Du hast gewonnen.',
          'lost' => 'Du hast verloren.',
          _ => 'Unentschieden.',
        });
      }
    }
  });

  test('legacy and recipient-specific plain announcements remain readable', () {
    final card = message('card', 100, card: true);
    final lang = AppLocalizationsEn();
    expect(gameMessageText(card, lang), 'Played a move');
    final targeted = card.copyWith(
      additionalMessageData: NullableBytes(
        value: AdditionalMessageData(
          webxdcOrigin: WebxdcOrigin(
            notificationContent: 'It is your turn',
          ),
        ).writeToBuffer(),
      ),
    );
    expect(gameMessageText(targeted, lang), 'It is your turn');
    final malformed = card.copyWith(
      additionalMessageData: NullableBytes(value: Uint8List.fromList([255])),
    );
    expect(gameMessageText(malformed, lang), 'Played a move');
  });

  test('unknown structured game status never exposes long announcements', () {
    final lang = AppLocalizationsEn();
    for (final sender in [null, 7]) {
      for (final metadata in [
        '{"webxdc_game":"unknown","instance_id":"card"}',
        '{"webxdc_game":"won","instance_id":"other-game"}',
      ]) {
        final card =
            message(
              'card',
              100,
              card: true,
              activity: 'move-info',
              sender: sender,
            ).copyWith(
              content: const NullableText(
                value: 'has played Chess. It is your turn.',
              ),
              additionalMessageData: NullableBytes(
                value: AdditionalMessageData(
                  webxdcOrigin: WebxdcOrigin(
                    notificationContent: metadata,
                  ),
                ).writeToBuffer(),
              ),
            );
        expect(
          gameMessageText(card, lang),
          sender == null ? 'You have played.' : 'Played.',
        );
      }
    }
  });

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
