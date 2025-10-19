import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleTextMessage(
  int fromUserId,
  String groupId,
  EncryptedContent_TextMessage textMessage,
) async {
  Log.info(
    'Got a text message: ${textMessage.senderMessageId} from $groupId',
  );

  final message = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      messageId: Value(textMessage.senderMessageId),
      senderId: Value(fromUserId),
      groupId: Value(groupId),
      content: Value(textMessage.text),
      ackByServer: const Value(true),
      ackByUser: const Value(true),
      quotesMessageId: Value(
        textMessage.hasQuoteMessageId() ? textMessage.quoteMessageId : null,
      ),
      createdAt: Value(fromTimestamp(textMessage.timestamp)),
    ),
  );
  if (message != null) {
    Log.info('Inserted a new text message with ID: ${message.messageId}');
  }
}
