import 'package:clock/clock.dart' show clock;
import 'package:drift/drift.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart'
    as pb_data;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleAdditionalDataMessage(
  int fromUserId,
  String groupId,
  EncryptedContent_AdditionalDataMessage message,
  String receiptId,
) async {
  Log.info(
    '[$receiptId] Got a additional data message: ${message.senderMessageId} from $groupId',
  );

  // Prevent message overwrite: reject if a message with this ID already
  // exists from a different sender.
  final existing = await twonlyDB.messagesDao
      .getMessageById(message.senderMessageId)
      .getSingleOrNull();
  if (existing != null && existing.senderId != fromUserId) {
    Log.warn(
      '[$receiptId] $fromUserId tried to overwrite message from ${existing.senderId}. Dropping.',
    );
    return;
  }

  try {
    final additionalData = pb_data.AdditionalMessageData.fromBuffer(
      message.additionalMessageData,
    );
    if (additionalData.type == pb_data.AdditionalMessageData_Type.CONTACTS) {
      for (final sharedContact in additionalData.contacts) {
        await KeyVerificationService.verifySharedContact(
          contactId: sharedContact.userId.toInt(),
          sharedPublicIdentityKey: sharedContact.publicIdentityKey,
          senderId: fromUserId,
        );
      }
    }
  } catch (e) {
    Log.error(
      'Failed to parse additional message data or verify shared contacts: $e',
    );
  }

  final msg = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      messageId: Value(message.senderMessageId),
      senderId: Value(fromUserId),
      groupId: Value(groupId),
      type: Value(message.type),
      additionalMessageData: Value(
        Uint8List.fromList(message.additionalMessageData),
      ),
      createdAt: Value(fromTimestamp(message.timestamp)),
      ackByServer: Value(clock.now()),
    ),
  );
  await twonlyDB.groupsDao.increaseLastMessageExchange(
    groupId,
    fromTimestamp(message.timestamp),
  );
  if (msg != null) {
    Log.info(
      '[$receiptId] Inserted a new text message with ID: ${msg.messageId}',
    );
  }
}
