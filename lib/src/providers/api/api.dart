import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/json_models/message.dart';
import 'package:twonly/src/json_models/userdata.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/hive.dart';
import 'package:twonly/src/services/notification_service.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;
import 'package:twonly/src/utils/storage.dart';

Future tryTransmitMessages() async {
  Map<String, dynamic> retransmit = await getAllMessagesForRetransmitting();

  if (retransmit.isEmpty) return;

  Logger("api.dart").info("try sending messages: ${retransmit.length}");

  Map<String, dynamic> failed = {};

  for (String key in retransmit.keys) {
    RetransmitMessage msg =
        RetransmitMessage.fromJson(jsonDecode(retransmit[key]));

    Result resp = await apiProvider.sendTextMessage(
      msg.userId,
      msg.bytes,
      msg.pushData,
    );

    if (resp.isSuccess) {
      if (msg.messageId != null) {
        await twonlyDatabase.messagesDao.updateMessageByMessageId(
          msg.messageId!,
          MessagesCompanion(
            acknowledgeByServer: Value(true),
          ),
        );
      }
    } else {
      failed[key] = retransmit[key];
    }
  }
  Box box = await getMediaStorage();
  box.put("messages-to-retransmit", jsonEncode(failed));
}

class RetransmitMessage {
  int? messageId;
  int userId;
  Uint8List bytes;
  List<int>? pushData;
  RetransmitMessage({
    this.messageId,
    required this.userId,
    required this.bytes,
    this.pushData,
  });

  // From JSON constructor
  factory RetransmitMessage.fromJson(Map<String, dynamic> json) {
    return RetransmitMessage(
      messageId: json['messageId'],
      userId: json['userId'],
      bytes: base64Decode(json['bytes']),
      pushData: json['pushData'] == null
          ? null
          : List<int>.from(json['pushData'].map((item) => item as int)),
    );
  }

  // To JSON method
  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'userId': userId,
      'bytes': base64Encode(bytes),
      'pushData': pushData,
    };
  }
}

Future<Map<String, dynamic>> getAllMessagesForRetransmitting() async {
  Box box = await getMediaStorage();
  String? retransmitJson = box.get("messages-to-retransmit");
  Map<String, dynamic> retransmit = {};

  if (retransmitJson != null) {
    retransmit = jsonDecode(retransmitJson);
  }
  return retransmit;
}

// this functions ensures that the message is received by the server and in case of errors will try again later
Future<Result> encryptAndSendMessage(
    int? messageId, int userId, MessageJson msg,
    {PushKind? pushKind}) async {
  Uint8List? bytes = await SignalHelper.encryptMessage(msg, userId);

  if (bytes == null) {
    Logger("api.dart").shout("Error encryption message!");
    return Result.error(ErrorCode.InternalError);
  }

  String stateId = (messageId ?? (60001 + Random().nextInt(100000))).toString();
  Box box = await getMediaStorage();

  List<int>? pushData;
  if (pushKind != null) {
    pushData = await getPushData(userId, pushKind);
  }

  {
    var retransmit = await getAllMessagesForRetransmitting();

    retransmit[stateId] = jsonEncode(RetransmitMessage(
      messageId: messageId,
      userId: userId,
      bytes: bytes,
      pushData: pushData,
    ).toJson());

    box.put("messages-to-retransmit", jsonEncode(retransmit));
  }

  Result resp = await apiProvider.sendTextMessage(userId, bytes, pushData);

  if (resp.isSuccess) {
    if (messageId != null) {
      await twonlyDatabase.messagesDao.updateMessageByMessageId(
        messageId,
        MessagesCompanion(acknowledgeByServer: Value(true)),
      );

      {
        var retransmit = await getAllMessagesForRetransmitting();
        retransmit.remove(stateId);
        box.put("messages-to-retransmit", jsonEncode(retransmit));
      }

      box.delete("retransmit-$messageId-textmessage");
    }
  }

  return resp;
}

Future sendTextMessage(
    int target, TextMessageContent content, PushKind? pushKind) async {
  DateTime messageSendAt = DateTime.now();

  int? messageId = await twonlyDatabase.messagesDao.insertMessage(
    MessagesCompanion(
      contactId: Value(target),
      kind: Value(MessageKind.textMessage),
      sendAt: Value(messageSendAt),
      responseToOtherMessageId: Value(content.responseToMessageId),
      downloadState: Value(DownloadState.downloaded),
      contentJson: Value(
        jsonEncode(content.toJson()),
      ),
    ),
  );

  if (messageId == null) return;

  MessageJson msg = MessageJson(
    kind: MessageKind.textMessage,
    messageId: messageId,
    content: content,
    timestamp: messageSendAt,
  );

  encryptAndSendMessage(messageId, target, msg, pushKind: pushKind);
}

Future notifyContactAboutOpeningMessage(
    int fromUserId, List<int> messageOtherIds) async {
  for (final messageOtherId in messageOtherIds) {
    await encryptAndSendMessage(
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
}

Future notifyContactsAboutProfileChange() async {
  List<Contact> contacts =
      await twonlyDatabase.contactsDao.getAllNotBlockedContacts();

  UserData? user = await getUser();
  if (user == null) return;
  if (user.avatarCounter == null) return;
  if (user.avatarSvg == null) return;

  for (Contact contact in contacts) {
    if (contact.myAvatarCounter < user.avatarCounter!) {
      twonlyDatabase.contactsDao.updateContact(contact.userId,
          ContactsCompanion(myAvatarCounter: Value(user.avatarCounter!)));
      encryptAndSendMessage(
        null,
        contact.userId,
        MessageJson(
          kind: MessageKind.profileChange,
          content: ProfileContent(
            avatarSvg: user.avatarSvg!,
            displayName: user.displayName,
          ),
          timestamp: DateTime.now(),
        ),
      );
    }
  }
}
