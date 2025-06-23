import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

Future tryTransmitMessages() async {
  final retransIds =
      await twonlyDB.messageRetransmissionDao.getRetransmitAbleMessages();

  Log.info("Retransmitting ${retransIds.length} text messages");

  if (retransIds.isEmpty) return;

  for (final retransId in retransIds) {
    sendRetransmitMessage(retransId);
    //twonlyDB.messageRetransmissionDao.deleteRetransmissionById(retransId);
  }
}

Future sendRetransmitMessage(int retransId) async {
  MessageRetransmission? retrans = await twonlyDB.messageRetransmissionDao
      .getRetransmissionById(retransId)
      .getSingleOrNull();

  if (retrans == null) {
    Log.error("$retransId not found in database");
    return;
  }

  MessageJson json = MessageJson.fromJson(
    jsonDecode(
      utf8.decode(
        gzip.decode(retrans.plaintextContent),
      ),
    ),
  );
  Log.info("Retransmitting: ${json.kind} to ${retrans.contactId}");
  // if (json.kind
  //     .contains(MessageKind.pushKey.name)) {
  // await twonlyDB.messageRetransmissionDao.deleteRetransmissionById(retransId);
  // return;
  // }

  Contact? contact = await twonlyDB.contactsDao
      .getContactByUserId(retrans.contactId)
      .getSingleOrNull();
  if (contact == null || contact.deleted) {
    Log.warn("Contact deleted $retransId or not found in database.");
    if (retrans.messageId != null) {
      await twonlyDB.messagesDao.updateMessageByMessageId(
        retrans.messageId!,
        MessagesCompanion(errorWhileSending: Value(true)),
      );
    }
    return;
  }

  Uint8List? encryptedBytes = await signalEncryptMessage(
    retrans.contactId,
    retrans.plaintextContent,
  );

  if (encryptedBytes == null) {
    Log.error("Could not encrypt the message. Aborting and trying again.");
    return;
  }

  Result resp = await apiService.sendTextMessage(
    retrans.contactId,
    encryptedBytes,
    retrans.pushData,
  );

  bool retry = true;

  if (resp.isError) {
    if (resp.error == ErrorCode.UserIdNotFound) {
      retry = false;
      if (retrans.messageId != null) {
        await twonlyDB.messagesDao.updateMessageByMessageId(
          retrans.messageId!,
          MessagesCompanion(errorWhileSending: Value(true)),
        );
      }
      await twonlyDB.contactsDao.updateContact(
        retrans.contactId,
        ContactsCompanion(deleted: Value(true)),
      );
    }
  }

  if (resp.isSuccess) {
    retry = false;
    if (retrans.messageId != null) {
      await twonlyDB.messagesDao.updateMessageByMessageId(
        retrans.messageId!,
        MessagesCompanion(
          acknowledgeByServer: Value(true),
          errorWhileSending: Value(false),
        ),
      );
    }
  }

  if (!retry) {
    if (retrans.willNotGetACKByUser) {
      await twonlyDB.messageRetransmissionDao
          .deleteRetransmissionById(retransId);
    } else {
      await twonlyDB.messageRetransmissionDao.updateRetransmission(
        retransId,
        MessageRetransmissionsCompanion(
          acknowledgeByServerAt: Value(DateTime.now()),
        ),
      );
    }
  }
}

// encrypts and stores the message and then sends it in the background
Future encryptAndSendMessageAsync(int? messageId, int userId, MessageJson msg,
    {PushNotification? pushNotification,
    bool willNotGetACKByUser = false}) async {
  if (gIsDemoUser) {
    return;
  }

  Uint8List? pushData;
  if (pushNotification != null) {
    pushData = await getPushData(userId, pushNotification);
  }

  int? retransId = await twonlyDB.messageRetransmissionDao.insertRetransmission(
    MessageRetransmissionsCompanion(
      contactId: Value(userId),
      messageId: Value(messageId),
      plaintextContent: Value(Uint8List(0)),
      pushData: Value(pushData),
      willNotGetACKByUser: Value(willNotGetACKByUser),
    ),
  );

  if (retransId == null) {
    Log.error("Could not insert the message into the retransmission database");
    return;
  }

  msg.retransId = retransId;

  Uint8List plaintextContent =
      Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(msg.toJson()))));

  await twonlyDB.messageRetransmissionDao.updateRetransmission(
      retransId,
      MessageRetransmissionsCompanion(
          plaintextContent: Value(plaintextContent)));

  // this can now be done in the background...
  sendRetransmitMessage(retransId);
}

Future sendTextMessage(
  int target,
  TextMessageContent content,
  PushNotification? pushNotification,
) async {
  DateTime messageSendAt = DateTime.now();
  DateTime? openedAt;

  if (pushNotification != null && pushNotification.hasReactionContent()) {
    openedAt = DateTime.now();
  }

  int? messageId = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      contactId: Value(target),
      kind: Value(MessageKind.textMessage),
      sendAt: Value(messageSendAt),
      responseToOtherMessageId: Value(content.responseToMessageId),
      responseToMessageId: Value(content.responseToOtherMessageId),
      downloadState: Value(DownloadState.downloaded),
      openedAt: Value(openedAt),
      contentJson: Value(
        jsonEncode(content.toJson()),
      ),
    ),
  );

  if (messageId == null) return;

  if (pushNotification != null && !pushNotification.hasReactionContent()) {
    pushNotification.messageId = Int64(messageId);
  }

  MessageJson msg = MessageJson(
    kind: MessageKind.textMessage,
    messageId: messageId,
    content: content,
    timestamp: messageSendAt,
  );

  await encryptAndSendMessageAsync(
    messageId,
    target,
    msg,
    pushNotification: pushNotification,
  );
}

Future notifyContactAboutOpeningMessage(
  int fromUserId,
  List<int> messageOtherIds,
) async {
  int biggestMessageId = messageOtherIds.first;

  for (final messageOtherId in messageOtherIds) {
    if (messageOtherId > biggestMessageId) biggestMessageId = messageOtherId;
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
  await updateLastMessageId(fromUserId, biggestMessageId);
}

Future notifyContactsAboutProfileChange() async {
  List<Contact> contacts =
      await twonlyDB.contactsDao.getAllNotBlockedContacts();

  UserData? user = await getUser();
  if (user == null) return;
  if (user.avatarSvg == null) return;

  for (Contact contact in contacts) {
    if (contact.myAvatarCounter < user.avatarCounter) {
      twonlyDB.contactsDao.updateContact(
        contact.userId,
        ContactsCompanion(
          myAvatarCounter: Value(user.avatarCounter),
        ),
      );
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
