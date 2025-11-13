import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleMessageUpdate(
  int contactId,
  EncryptedContent_MessageUpdate messageUpdate,
) async {
  switch (messageUpdate.type) {
    case EncryptedContent_MessageUpdate_Type.OPENED:
      for (final targetMessageId in messageUpdate.multipleTargetMessageIds) {
        Log.info(
          'Opened message $targetMessageId',
        );
        try {
          await twonlyDB.messagesDao.handleMessageOpened(
            contactId,
            targetMessageId,
            fromTimestamp(messageUpdate.timestamp),
          );
        } catch (e) {
          Log.warn(e);
        }
      }
    case EncryptedContent_MessageUpdate_Type.DELETE:
      if (!await isSender(contactId, messageUpdate.senderMessageId)) {
        return;
      }
      Log.info('Delete message ${messageUpdate.senderMessageId}');
      try {
        await twonlyDB.messagesDao.handleMessageDeletion(
          contactId,
          messageUpdate.senderMessageId,
          fromTimestamp(messageUpdate.timestamp),
        );
      } catch (e) {
        Log.warn(e);
      }
    case EncryptedContent_MessageUpdate_Type.EDIT_TEXT:
      if (!await isSender(contactId, messageUpdate.senderMessageId)) {
        return;
      }
      Log.info('Edit message ${messageUpdate.senderMessageId}');
      try {
        await twonlyDB.messagesDao.handleTextEdit(
          contactId,
          messageUpdate.senderMessageId,
          messageUpdate.text,
          fromTimestamp(messageUpdate.timestamp),
        );
      } catch (e) {
        Log.warn(e);
      }
  }
}

Future<bool> isSender(int fromUserId, String messageId) async {
  final message =
      await twonlyDB.messagesDao.getMessageById(messageId).getSingleOrNull();
  if (message == null) return false;
  if (message.senderId == fromUserId) {
    return true;
  }
  Log.error('Contact $fromUserId tried to modify the message $messageId');
  return false;
}
