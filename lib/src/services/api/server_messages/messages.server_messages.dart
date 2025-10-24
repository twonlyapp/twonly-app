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
      Log.info(
        'Opened message ${messageUpdate.multipleSenderMessageIds.length}',
      );
      for (final senderMessageId in messageUpdate.multipleSenderMessageIds) {
        await twonlyDB.messagesDao.handleMessageOpened(
          contactId,
          senderMessageId,
          fromTimestamp(messageUpdate.timestamp),
        );
      }
    case EncryptedContent_MessageUpdate_Type.DELETE:
      Log.info('Delete message ${messageUpdate.senderMessageId}');
      await twonlyDB.messagesDao.handleMessageDeletion(
        contactId,
        messageUpdate.senderMessageId,
        fromTimestamp(messageUpdate.timestamp),
      );
    case EncryptedContent_MessageUpdate_Type.EDIT_TEXT:
      Log.info('Edit message ${messageUpdate.senderMessageId}');
      await twonlyDB.messagesDao.handleTextEdit(
        contactId,
        messageUpdate.senderMessageId,
        messageUpdate.text,
        fromTimestamp(messageUpdate.timestamp),
      );
  }
}
