import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/api/error.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/utils/hive.dart';
import 'package:twonly/src/services/notification.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

final lockSendingMessages = Mutex();

Future tryTransmitMessages() async {
  lockSendingMessages.protect(() async {
    Map<String, dynamic> retransmit = await getAllMessagesForRetransmitting();

    if (retransmit.isEmpty) return;

    Log.info("try sending messages: ${retransmit.length}");

    Map<String, dynamic> failed = {};

    List<MapEntry<String, dynamic>> sortedList = retransmit.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    for (final element in sortedList) {
      RetransmitMessage msg =
          RetransmitMessage.fromJson(jsonDecode(element.value));

      Result resp = await apiService.sendTextMessage(
        msg.userId,
        msg.bytes,
        msg.pushData,
      );

      if (resp.isSuccess) {
        if (msg.messageId != null) {
          await twonlyDB.messagesDao.updateMessageByMessageId(
            msg.messageId!,
            MessagesCompanion(
              acknowledgeByServer: Value(true),
            ),
          );
        }
      } else {
        failed[element.key] = element.value;
      }
    }
    Box box = await getMediaStorage();
    box.put("messages-to-retransmit", jsonEncode(failed));
  });
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
    try {
      retransmit = jsonDecode(retransmitJson);
    } catch (e) {
      Log.error("Could not decode the retransmit messages: $e");
      await box.delete("messages-to-retransmit");
    }
  }
  return retransmit;
}

Future<Result> sendRetransmitMessage(
    String stateId, RetransmitMessage msg) async {
  Result resp =
      await apiService.sendTextMessage(msg.userId, msg.bytes, msg.pushData);

  bool retry = true;

  if (resp.isError) {
    if (resp.error == ErrorCode.UserIdNotFound) {
      retry = false;
      if (msg.messageId != null) {
        await twonlyDB.messagesDao.updateMessageByMessageId(
          msg.messageId!,
          MessagesCompanion(errorWhileSending: Value(true)),
        );
      }
    }
  }

  if (resp.isSuccess) {
    if (msg.messageId != null) {
      retry = false;
      await twonlyDB.messagesDao.updateMessageByMessageId(
        msg.messageId!,
        MessagesCompanion(acknowledgeByServer: Value(true)),
      );
    }
  }

  if (!retry) {
    {
      var retransmit = await getAllMessagesForRetransmitting();
      retransmit.remove(stateId);
      Box box = await getMediaStorage();
      box.put("messages-to-retransmit", jsonEncode(retransmit));
    }
  }
  return resp;
}

// this functions ensures that the message is received by the server and in case of errors will try again later
Future<(String, RetransmitMessage)?> encryptMessage(
    int? messageId, int userId, MessageJson msg,
    {PushKind? pushKind}) async {
  return await lockSendingMessages
      .protect<(String, RetransmitMessage)?>(() async {
    Uint8List? bytes = await signalEncryptMessage(userId, msg);

    if (bytes == null) {
      Log.error("Error encryption message!");
      return null;
    }

    var retransmit = await getAllMessagesForRetransmitting();

    int currentMaxStateId = messageId ?? 60000;
    if (retransmit.isNotEmpty && messageId == null) {
      currentMaxStateId = retransmit.keys.map((x) => int.parse(x)).reduce(max);
      if (currentMaxStateId < 60000) {
        currentMaxStateId = 60000;
      }
    }

    String stateId = (currentMaxStateId + 1).toString();

    Box box = await getMediaStorage();

    List<int>? pushData;
    if (pushKind != null) {
      pushData = await getPushData(userId, pushKind);
    }

    RetransmitMessage encryptedMessage = RetransmitMessage(
      messageId: messageId,
      userId: userId,
      bytes: bytes,
      pushData: pushData,
    );

    {
      retransmit[stateId] = jsonEncode(encryptedMessage.toJson());
      box.put("messages-to-retransmit", jsonEncode(retransmit));
    }

    return (stateId, encryptedMessage);
  });
}

// encrypts and stores the message and then sends it in the background
Future encryptAndSendMessageAsync(int? messageId, int userId, MessageJson msg,
    {PushKind? pushKind}) async {
  if (gIsDemoUser) {
    return;
  }
  (String, RetransmitMessage)? stateData =
      await encryptMessage(messageId, userId, msg, pushKind: pushKind);
  if (stateData != null) {
    final (stateId, message) = stateData;
    sendRetransmitMessage(stateId, message);
  }
}

Future sendTextMessage(
    int target, TextMessageContent content, PushKind? pushKind) async {
  DateTime messageSendAt = DateTime.now();

  int? messageId = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      contactId: Value(target),
      kind: Value(MessageKind.textMessage),
      sendAt: Value(messageSendAt),
      responseToOtherMessageId: Value(content.responseToMessageId),
      responseToMessageId: Value(content.responseToOtherMessageId),
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

  await encryptAndSendMessageAsync(messageId, target, msg, pushKind: pushKind);
}

Future notifyContactAboutOpeningMessage(
    int fromUserId, List<int> messageOtherIds) async {
  for (final messageOtherId in messageOtherIds) {
    await encryptAndSendMessageAsync(
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
      await twonlyDB.contactsDao.getAllNotBlockedContacts();

  UserData? user = await getUser();
  if (user == null) return;
  if (user.avatarCounter == null) return;
  if (user.avatarSvg == null) return;

  for (Contact contact in contacts) {
    if (contact.myAvatarCounter < user.avatarCounter!) {
      twonlyDB.contactsDao.updateContact(contact.userId,
          ContactsCompanion(myAvatarCounter: Value(user.avatarCounter!)));
      await encryptAndSendMessageAsync(
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
