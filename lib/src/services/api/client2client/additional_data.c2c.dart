import 'package:clock/clock.dart' show clock;
import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleAdditionalDataMessage(
  int fromUserId,
  String groupId,
  EncryptedContent_AdditionalDataMessage message,
) async {
  Log.info(
    'Got a additional data message: ${message.senderMessageId} from $groupId',
  );
  final msg = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      messageId: Value(message.senderMessageId),
      senderId: Value(fromUserId),
      groupId: Value(groupId),
      type: Value(message.type),
      additionalMessageData:
          Value(Uint8List.fromList(message.additionalMessageData)),
      createdAt: Value(fromTimestamp(message.timestamp)),
      ackByServer: Value(clock.now()),
    ),
  );
  await twonlyDB.groupsDao.increaseLastMessageExchange(
    groupId,
    fromTimestamp(message.timestamp),
  );
  if (msg != null) {
    Log.info('Inserted a new text message with ID: ${msg.messageId}');
  }
}
