import 'package:twonly/core/database/app/messages/table.dart';
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
