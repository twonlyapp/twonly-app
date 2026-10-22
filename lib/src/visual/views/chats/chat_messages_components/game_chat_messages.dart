import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';

/// Only automatic info rows use this ID suffix. Text a person shares from an
/// app also has an origin, but remains an ordinary message in the conversation.
String? gameAnnouncementInstance(Message message) {
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

/// Put the refreshed card immediately before its latest announcement, even
/// when other messages share their timestamp. Older loaded pages may still
/// contain a replaced info row until the next database read; hide those too.
List<Message> arrangeGameMessages(List<Message> chronological) {
  final latest = <String, Message>{};
  final cards = <String, Message>{};
  for (final message in chronological) {
    final instance = gameAnnouncementInstance(message);
    if (instance != null) latest[instance] = message;
    if (message.type == MessageType.webxdcApp.name) {
      cards[message.messageId] = message;
    }
  }
  final result = <Message>[];
  for (final message in chronological) {
    if (message.type == MessageType.webxdcApp.name &&
        latest.containsKey(message.messageId)) {
      continue;
    }
    final instance = gameAnnouncementInstance(message);
    if (instance != null) {
      if (latest[instance]!.messageId != message.messageId) continue;
      final card = cards[instance];
      if (card != null) {
        result.add(card.copyWith(createdAt: message.createdAt));
      }
    }
    result.add(message);
  }
  return result;
}
