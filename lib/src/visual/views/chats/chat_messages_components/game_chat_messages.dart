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

/// Show the recipient's game status without the push's played-game prefix. Keep
/// the shared announcement as fallback for the sender, spectators and old rows.
String gameMessageText(
  StoredMessage message,
  AppLocalizations lang,
) {
  final data = message.additionalMessageData;
  if (data == null) return message.content ?? '';
  String content;
  try {
    final origin = AdditionalMessageData.fromBuffer(data).webxdcOrigin;
    if (!origin.hasNotificationContent()) return message.content ?? '';
    content = origin.notificationContent;
  } catch (_) {
    return message.content ?? '';
  }
  try {
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic> &&
        decoded.length == 2 &&
        decoded['instance_id'] == message.messageId) {
      return switch (decoded['webxdc_game']) {
        'turn' => lang.chatGameTurn,
        'won' => lang.chatGameWon,
        'lost' => lang.chatGameLost,
        _ => content,
      };
    }
  } catch (_) {
    // Legacy apps provide plain notification text.
  }
  return content;
}
