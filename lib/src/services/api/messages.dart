import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pb.dart';
import 'package:twonly/src/services/api/server_messages.dart'
    show messageGetsAck;
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

final lockRetransmission = Mutex();

Future<void> tryTransmitMessages() async {
  return lockRetransmission.protect(() async {
    final retransIds =
        await twonlyDB.messageRetransmissionDao.getRetransmitAbleMessages();

    Log.info('Retransmitting ${retransIds.length} text messages');

    if (retransIds.isEmpty) return;

    for (final retransId in retransIds) {
      await sendRetransmitMessage(retransId);
    }
  });
}

Future<void> sendRetransmitMessage(int retransId) async {
  try {
    final retrans = await twonlyDB.messageRetransmissionDao
        .getRetransmissionById(retransId)
        .getSingleOrNull();

    if (retrans == null) {
      Log.error('$retransId not found in database');
      return;
    }

    if (retrans.acknowledgeByServerAt != null) {
      Log.error('$retransId message already retransmitted');
      return;
    }

    final json = MessageJson.fromJson(jsonDecode(
      utf8.decode(
        gzip.decode(retrans.plaintextContent),
      ),
    ) as Map<String, dynamic>);

    Log.info('Retransmitting $retransId: ${json.kind} to ${retrans.contactId}');

    final contact = await twonlyDB.contactsDao
        .getContactByUserId(retrans.contactId)
        .getSingleOrNull();
    if (contact == null || contact.deleted) {
      Log.warn('Contact deleted $retransId or not found in database.');
      if (retrans.messageId != null) {
        await twonlyDB.messagesDao.updateMessageByMessageId(
          retrans.messageId!,
          const MessagesCompanion(errorWhileSending: Value(true)),
        );
      }
      return;
    }

    final encryptedBytes = await signalEncryptMessage(
      retrans.contactId,
      retrans.plaintextContent,
    );

    if (encryptedBytes == null) {
      Log.error('Could not encrypt the message. Aborting and trying again.');
      return;
    }

    final encryptedHash = (await Sha256().hash(encryptedBytes)).bytes;

    await twonlyDB.messageRetransmissionDao.updateRetransmission(
      retransId,
      MessageRetransmissionsCompanion(
        encryptedHash: Value(Uint8List.fromList(encryptedHash)),
      ),
    );

    final resp = await apiService.sendTextMessage(
      retrans.contactId,
      encryptedBytes,
      retrans.pushData,
    );

    var retry = true;

    if (resp.isError) {
      Log.error('Could not retransmit message.');
      if (resp.error == ErrorCode.UserIdNotFound) {
        retry = false;
        if (retrans.messageId != null) {
          await twonlyDB.messagesDao.updateMessageByMessageId(
            retrans.messageId!,
            const MessagesCompanion(errorWhileSending: Value(true)),
          );
        }
        await twonlyDB.contactsDao.updateContact(
          retrans.contactId,
          const ContactsCompanion(deleted: Value(true)),
        );
      }
    }

    if (resp.isSuccess) {
      retry = false;
      if (retrans.messageId != null) {
        await twonlyDB.messagesDao.updateMessageByMessageId(
          retrans.messageId!,
          const MessagesCompanion(
            acknowledgeByServer: Value(true),
            errorWhileSending: Value(false),
          ),
        );
      }
    }

    if (!retry) {
      if (!messageGetsAck(json.kind)) {
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
  } catch (e) {
    Log.error('error resending message: $e');
    await twonlyDB.messageRetransmissionDao.deleteRetransmissionById(retransId);
  }
}

// encrypts and stores the message and then sends it in the background
Future<void> encryptAndSendMessageAsync(
  int? messageId,
  int userId,
  MessageJson msg, {
  PushNotification? pushNotification,
}) async {
  if (gIsDemoUser) {
    return;
  }

  Uint8List? pushData;
  if (pushNotification != null) {
    pushData = await getPushData(userId, pushNotification);
  }

  final retransId =
      await twonlyDB.messageRetransmissionDao.insertRetransmission(
    MessageRetransmissionsCompanion(
      contactId: Value(userId),
      messageId: Value(messageId),
      plaintextContent: Value(Uint8List(0)),
      pushData: Value(pushData),
    ),
  );

  if (retransId == null) {
    Log.error('Could not insert the message into the retransmission database');
    return;
  }

  msg.retransId = retransId;

  final plaintextContent =
      Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(msg.toJson()))));

  await twonlyDB.messageRetransmissionDao.updateRetransmission(
      retransId,
      MessageRetransmissionsCompanion(
          plaintextContent: Value(plaintextContent)));

  // this can now be done in the background...
  unawaited(sendRetransmitMessage(retransId));
}

Future<void> sendTextMessage(
  int target,
  TextMessageContent content,
  PushNotification? pushNotification,
) async {
  final messageSendAt = DateTime.now();
  DateTime? openedAt;

  if (pushNotification != null && pushNotification.hasReactionContent()) {
    openedAt = DateTime.now();
  }

  final messageId = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      contactId: Value(target),
      kind: const Value(MessageKind.textMessage),
      sendAt: Value(messageSendAt),
      responseToOtherMessageId: Value(content.responseToMessageId),
      responseToMessageId: Value(content.responseToOtherMessageId),
      downloadState: const Value(DownloadState.downloaded),
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

  final msg = MessageJson(
    kind: MessageKind.textMessage,
    messageSenderId: messageId,
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

Future<void> notifyContactAboutOpeningMessage(
  int fromUserId,
  List<int> messageOtherIds,
) async {
  var biggestMessageId = messageOtherIds.first;

  for (final messageOtherId in messageOtherIds) {
    if (messageOtherId > biggestMessageId) biggestMessageId = messageOtherId;
    await encryptAndSendMessageAsync(
      null,
      fromUserId,
      MessageJson(
        kind: MessageKind.opened,
        messageReceiverId: messageOtherId,
        content: MessageContent(),
        timestamp: DateTime.now(),
      ),
    );
  }
  await updateLastMessageId(fromUserId, biggestMessageId);
}

Future<void> notifyContactsAboutProfileChange() async {
  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();

  final user = await getUser();
  if (user == null) return;
  if (user.avatarSvg == null) return;

  for (final contact in contacts) {
    if (contact.myAvatarCounter < user.avatarCounter) {
      await twonlyDB.contactsDao.updateContact(
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
