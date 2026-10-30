import 'dart:convert';

import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';

/// Only automatic info rows use this ID suffix. Text a person shares from an
/// app also has an origin, but remains an ordinary message in the conversation.
String? gameAnnouncementInstance(StoredMessage message) {
  final data = message.additionalMessageData;
  if (message.type != MessageType.text.name ||
      !message.messageId.endsWith('-info') ||
      data == null) {
    return null;
  }
  try {
    final decoded = AdditionalMessageData.fromBuffer(data);
    return decoded.hasWebxdcOrigin() ? decoded.webxdcOrigin.instanceId : null;
  } catch (_) {
    return null;
  }
}

/// Rust projects the latest player's activity onto the original card. Also
/// discard automatic text retained in an older page's in-memory snapshot.
List<StoredMessage> arrangeGameMessages(List<StoredMessage> chronological) => [
  for (final message in chronological)
    if (gameAnnouncementInstance(message) == null) message,
];

/// A new turn is new activity even when the card ID and timestamp are unchanged.
String messageActivityId(StoredMessage message) =>
    message.activityMessageId ?? message.messageId;

/// Structured status, supplied by the app, selects game presentation.
/// App identifiers and ordinary announcements do not identify a game.
String gameMessageText(StoredMessage message, AppLocalizations lang) {
  final fallback = message.content ?? '';
  final data = message.additionalMessageData;
  if (data == null) return fallback;
  String content;
  try {
    final origin = AdditionalMessageData.fromBuffer(data).webxdcOrigin;
    if (!origin.hasNotificationContent()) return fallback;
    content = origin.notificationContent;
  } catch (_) {
    return fallback;
  }
  try {
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic> && decoded.containsKey('webxdc_game')) {
      final played = message.activityMessageId == null
          ? ''
          : message.senderId == null
          ? lang.chatGamePlayed
          : lang.chatGameOtherPlayed;
      if (decoded.length != 2 || decoded['instance_id'] != message.messageId) {
        return played;
      }
      return switch (decoded['webxdc_game']) {
        'turn' => lang.chatGameTurn,
        'won' => lang.chatGameWon,
        'lost' => lang.chatGameLost,
        'played' => played,
        'draw' => lang.chatGameDraw,
        _ => played,
      };
    }
  } catch (_) {
    // Other apps can supply plain notification text.
  }
  return content;
}
