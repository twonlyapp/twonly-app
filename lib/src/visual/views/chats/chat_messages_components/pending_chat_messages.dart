import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/game_chat_messages.dart';

/// Outgoing rows displayed while Rust is still persisting them.
///
/// These are ordinary messages with no server acknowledgment, so the existing
/// bubble and sending loader also render the pending state.
class PendingChatMessages {
  final Map<String, Message> _messages = {};
  int _lastIdTimestampMs = 0;

  bool contains(String messageId) => _messages.containsKey(messageId);

  Message add({
    required String groupId,
    required String text,
    String? quoteMessageId,
    Uint8List? additionalMessageData,
  }) {
    final now = clock.now();
    // UUID ordering is also the tie-breaker for rows stored in the same second.
    // Keep it monotonic even for two sends within one millisecond.
    _lastIdTimestampMs = now.millisecondsSinceEpoch > _lastIdTimestampMs
        ? now.millisecondsSinceEpoch
        : _lastIdTimestampMs + 1;
    final message = Message(
      groupId: groupId,
      messageId: uuid.v7(
        utc: DateTime.fromMillisecondsSinceEpoch(
          _lastIdTimestampMs,
          isUtc: true,
        ),
      ),
      type: MessageType.text.name,
      content: text,
      quotesMessageId: quoteMessageId,
      additionalMessageData: additionalMessageData,
      mediaStored: false,
      mediaReopened: false,
      isDeletedFromSender: false,
      isWidgetMedia: false,
      isStory: false,
      // SQLite stores seconds. Keep the timestamp identical on both sides so
      // persistence cannot move a bubble or change its displayed time.
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (now.millisecondsSinceEpoch ~/ 1000) * 1000,
      ),
    );
    track(message);
    return message;
  }

  void track(Message message) => _messages[message.messageId] = message;

  bool remove(String messageId) => _messages.remove(messageId) != null;

  /// A database emission replaces pending rows by ID, even when sends commit
  /// out of order or the emission arrives before the bridge call completes.
  List<Message> merge(Iterable<Message> persisted) {
    final byId = {for (final message in persisted) message.messageId: message};
    byId.keys.forEach(_messages.remove);
    final chronological = [...byId.values, ..._messages.values]
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.messageId.compareTo(b.messageId);
      });
    return arrangeGameMessages(chronological);
  }
}
