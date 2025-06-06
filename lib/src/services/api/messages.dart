import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/api/error.pb.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/notification.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

Future tryTransmitMessages() async {
  final retransIds =
      await twonlyDB.messageRetransmissionDao.getRetransmitAbleMessages();

  if (retransIds.isEmpty) return;

  Log.info("Retransmitting ${retransIds.length} text messages");

  for (final retransId in retransIds) {
    sendRetransmitMessage(retransId);
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
    await twonlyDB.messageRetransmissionDao.deleteRetransmissionById(retransId);
  }
}

// encrypts and stores the message and then sends it in the background
Future encryptAndSendMessageAsync(int? messageId, int userId, MessageJson msg,
    {PushKind? pushKind}) async {
  if (gIsDemoUser) {
    return;
  }

  Uint8List? pushData;
  if (pushKind != null) {
    pushData = await getPushData(userId, pushKind);
  }

  Uint8List plaintextContent =
      Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(msg.toJson()))));

  int? retransId = await twonlyDB.messageRetransmissionDao.insertRetransmission(
    MessageRetransmissionsCompanion(
      contactId: Value(userId),
      messageId: Value(messageId),
      plaintextContent: Value(plaintextContent),
      pushData: Value(pushData),
    ),
  );

  if (retransId == null) {
    Log.error("Could not insert the message into the retransmission database");
    return;
  }

  // this can now be done in the background...
  sendRetransmitMessage(retransId);
}

Future sendTextMessage(
  int target,
  TextMessageContent content,
  PushKind? pushKind,
) async {
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
