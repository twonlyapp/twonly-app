import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';

Future<void> handleTextMessage(
  int fromUserId,
  String groupId,
  EncryptedContent_TextMessage textMessage,
) async {
  TODO
  //   final content = message.content!;
  //   // when a message is received doubled ignore it...

  //   final openedMessage = await twonlyDB.messagesDao
  //       .getMessageByOtherMessageId(fromUserId, message.messageSenderId!)
  //       .getSingleOrNull();

  //   if (openedMessage != null) {
  //     if (openedMessage.errorWhileSending) {
  //       await twonlyDB.messagesDao
  //           .deleteMessagesByMessageId(openedMessage.messageId);
  //     } else {
  //       Log.error(
  //         'Got a duplicated message from other user: ${message.messageSenderId!}',
  //       );
  //       final ok = client.Response_Ok()..none = true;
  //       return client.Response()..ok = ok;
  //     }
  //   }

  //   int? responseToMessageId;
  //   int? responseToOtherMessageId;
  //   int? messageId;

  //   var acknowledgeByUser = false;
  //   DateTime? openedAt;

  //   if (message.kind == MessageKind.reopenedMedia) {
  //     acknowledgeByUser = true;
  //     openedAt = DateTime.now();
  //   }

  //   if (content is TextMessageContent) {
  //     responseToMessageId = content.responseToMessageId;
  //     responseToOtherMessageId = content.responseToOtherMessageId;

  //     if (responseToMessageId != null || responseToOtherMessageId != null) {
  //       // reactions are shown in the notification directly...
  //       if (isEmoji(content.text)) {
  //         openedAt = DateTime.now();
  //       }
  //     }
  //   }
  //   if (content is ReopenedMediaFileContent) {
  //     responseToMessageId = content.messageId;
  //   }

  //   if (responseToMessageId != null) {
  //     await twonlyDB.messagesDao.updateMessageByOtherUser(
  //       fromUserId,
  //       responseToMessageId,
  //       MessagesCompanion(
  //         errorWhileSending: const Value(false),
  //         openedAt: Value(
  //           DateTime.now(),
  //         ), // when a user reacted to the media file, it should be marked as opened
  //       ),
  //     );
  //   }

  //   final contentJson = jsonEncode(content.toJson());
  //   final update = MessagesCompanion(
  //     contactId: Value(fromUserId),
  //     kind: Value(message.kind),
  //     messageOtherId: Value(message.messageSenderId),
  //     contentJson: Value(contentJson),
  //     acknowledgeByServer: const Value(true),
  //     acknowledgeByUser: Value(acknowledgeByUser),
  //     responseToMessageId: Value(responseToMessageId),
  //     responseToOtherMessageId: Value(responseToOtherMessageId),
  //     openedAt: Value(openedAt),
  //     downloadState: Value(
  //       message.kind == MessageKind.media
  //           ? DownloadState.pending
  //           : DownloadState.downloaded,
  //     ),
  //     sendAt: Value(message.timestamp),
  //   );

  //   messageId = await twonlyDB.messagesDao.insertMessage(
  //     update,
  //   );

  //   if (messageId == null) {
  //     Log.error('could not insert message into db');
  //     return client.Response()..error = ErrorCode.InternalError;
  //   }

  //   Log.info('Inserted a new message with id: $messageId');

  //   if (message.kind == MessageKind.media) {
  //     await twonlyDB.contactsDao.incFlameCounter(
  //       fromUserId,
  //       true,
  //       message.timestamp,
  //     );

  //     final msg = await twonlyDB.messagesDao
  //         .getMessageByMessageId(messageId)
  //         .getSingleOrNull();
  //     if (msg != null) {
  //       unawaited(startDownloadMedia(msg, false));
  //     }
  //   }
  // } else {
  //   Log.error('Content is not defined $message');
  // }

  // // unarchive contact when receiving a new message
  // await twonlyDB.contactsDao.updateContact(
  //   fromUserId,
  //   const ContactsCompanion(
  //     archived: Value(false),
  //   ),
  // );
  // return null;
}
