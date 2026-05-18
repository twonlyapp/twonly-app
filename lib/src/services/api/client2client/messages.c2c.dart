import 'package:drift/drift.dart' show Value;
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleMessageUpdate(
  int contactId,
  EncryptedContent_MessageUpdate messageUpdate,
  String receiptId,
) async {
  switch (messageUpdate.type) {
    case EncryptedContent_MessageUpdate_Type.OPENED:
      Log.info(
        '[$receiptId] Opened message ${messageUpdate.multipleTargetMessageIds}',
      );
      try {
        await twonlyDB.messagesDao.handleMessagesOpened(
          Value(contactId),
          messageUpdate.multipleTargetMessageIds,
          fromTimestamp(messageUpdate.timestamp),
        );
      } catch (e) {
        Log.warn('[$receiptId] Error handling messages opened: $e');
      }
    case EncryptedContent_MessageUpdate_Type.DELETE:
      if (!await isSender(contactId, messageUpdate.senderMessageId, receiptId)) {
        return;
      }
      Log.info('[$receiptId] Delete message ${messageUpdate.senderMessageId}');
      try {
        await twonlyDB.messagesDao.handleMessageDeletion(
          contactId,
          messageUpdate.senderMessageId,
          fromTimestamp(messageUpdate.timestamp),
        );
      } catch (e) {
        Log.warn('[$receiptId] Error handling message deletion: $e');
      }
    case EncryptedContent_MessageUpdate_Type.EDIT_TEXT:
      if (!await isSender(contactId, messageUpdate.senderMessageId, receiptId)) {
        return;
      }
      Log.info('[$receiptId] Edit message ${messageUpdate.senderMessageId}');
      try {
        await twonlyDB.messagesDao.handleTextEdit(
          contactId,
          messageUpdate.senderMessageId,
          messageUpdate.text,
          fromTimestamp(messageUpdate.timestamp),
        );
      } catch (e) {
        Log.warn('[$receiptId] Error handling text edit: $e');
      }
  }
}

Future<bool> isSender(int fromUserId, String messageId, String receiptId) async {
  final message = await twonlyDB.messagesDao
      .getMessageById(messageId)
      .getSingleOrNull();
  if (message == null) return false;
  if (message.senderId == fromUserId) {
    return true;
  }
  Log.error('[$receiptId] Contact $fromUserId tried to modify the message $messageId');
  return false;
}
