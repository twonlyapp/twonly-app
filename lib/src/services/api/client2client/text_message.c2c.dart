import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleTextMessage(
  int fromUserId,
  String groupId,
  EncryptedContent_TextMessage textMessage,
) async {
  Log.info(
    'Got a text message: ${textMessage.senderMessageId} from $groupId',
  );

  // Prevent message overwrite: reject if a message with this ID already
  // exists from a different sender.
  final existing = await twonlyDB.messagesDao
      .getMessageById(textMessage.senderMessageId)
      .getSingleOrNull();
  if (existing != null && existing.senderId != fromUserId) {
    Log.warn(
      '$fromUserId tried to overwrite message from ${existing.senderId}. Dropping.',
    );
    return;
  }

  final message = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      messageId: Value(textMessage.senderMessageId),
      senderId: Value(fromUserId),
      groupId: Value(groupId),
      content: Value(textMessage.text),
      type: Value(MessageType.text.name),
      quotesMessageId: Value(
        textMessage.hasQuoteMessageId() ? textMessage.quoteMessageId : null,
      ),
      createdAt: Value(fromTimestamp(textMessage.timestamp)),
      ackByServer: Value(clock.now()),
    ),
  );
  await twonlyDB.groupsDao.increaseLastMessageExchange(
    groupId,
    fromTimestamp(textMessage.timestamp),
  );
  if (message != null) {
    Log.info('Inserted a new text message with ID: ${message.messageId}');
  }
}
