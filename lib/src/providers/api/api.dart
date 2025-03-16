import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/json_models/message.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/hive.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

Future tryTransmitMessages() async {
  // List<Message> retransmit =
  //     await twonlyDatabase.getAllMessagesForRetransmitting();

  // if (retransmit.isEmpty) return;

  // Logger("api.dart").info("try sending messages: ${retransmit.length}");

  // Box box = await getMediaStorage();
  // for (int i = 0; i < retransmit.length; i++) {
  //   int msgId = retransmit[i].messageId;

  //   Uint8List? bytes = box.get("retransmit-$msgId-textmessage");
  //   if (bytes != null) {
  //     Result resp = await apiProvider.sendTextMessage(
  //       retransmit[i].contactId,
  //       bytes,
  //     );

  //     if (resp.isSuccess) {
  //       await twonlyDatabase.updateMessageByMessageId(
  //           msgId, MessagesCompanion(acknowledgeByServer: Value(true)));

  //       box.delete("retransmit-$msgId-textmessage");
  //     } else {
  //       // in case of error do nothing. As the message is not removed the app will try again when relaunched
  //     }
  //   }

  //   Uint8List? encryptedMedia = await box.get("retransmit-$msgId-media");
  //   if (encryptedMedia != null) {
  //     MediaMessageContent content =
  //         MediaMessageContent.fromJson(jsonDecode(retransmit[i].contentJson!));
  //     uploadMediaFile(msgId, retransmit[i].contactId, encryptedMedia,
  //         content.isRealTwonly, content.maxShowTime, retransmit[i].sendAt);
  //   }
  // }
}

// this functions ensures that the message is received by the server and in case of errors will try again later
Future<Result> encryptAndSendMessage(
    int? messageId, int userId, MessageJson msg) async {
  Uint8List? bytes = await SignalHelper.encryptMessage(msg, userId);

  if (bytes == null) {
    Logger("api.dart").shout("Error encryption message!");
    return Result.error(ErrorCode.InternalError);
  }

  Box box = await getMediaStorage();
  if (messageId != null) {
    box.put("retransmit-$messageId-textmessage", bytes);
  }

  Result resp = await apiProvider.sendTextMessage(userId, bytes);

  if (resp.isSuccess) {
    if (messageId != null) {
      await twonlyDatabase.messagesDao.updateMessageByMessageId(
        messageId,
        MessagesCompanion(acknowledgeByServer: Value(true)),
      );
      box.delete("retransmit-$messageId-textmessage");
    }
  }

  return resp;
}

Future sendTextMessage(int target, String message) async {
  MessageContent content = TextMessageContent(text: message);

  DateTime messageSendAt = DateTime.now();

  int? messageId = await twonlyDatabase.messagesDao.insertMessage(
    MessagesCompanion(
        contactId: Value(target),
        kind: Value(MessageKind.textMessage),
        sendAt: Value(messageSendAt),
        downloadState: Value(DownloadState.downloaded),
        contentJson: Value(jsonEncode(content.toJson()))),
  );

  if (messageId == null) return;

  MessageJson msg = MessageJson(
    kind: MessageKind.textMessage,
    messageId: messageId,
    content: content,
    timestamp: messageSendAt,
  );

  encryptAndSendMessage(messageId, target, msg);
}

Future notifyContactAboutOpeningMessage(
    int fromUserId, int messageOtherId) async {
  //await DbMessages.userOpenedOtherMessage(fromUserId, messageOtherId);

  encryptAndSendMessage(
    null,
    fromUserId,
    MessageJson(
      kind: MessageKind.opened,
      messageId: messageOtherId,
      content: MessageContent(),
      timestamp: DateTime.now(),
    ),
  );
}
