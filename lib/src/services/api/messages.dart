import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/message_old.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
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

Future<void> tryToSendCompleteMessage(String receiptId) async {
  try {
    final retrans = await twonlyDB.messageRetransmissionDao
        .getRetransmissionById(retransId)
        .getSingleOrNull();

    /// SET THE Message().receiptID !!!!!!!
    /// ALSO THE encryptedContent is NOT YET ENCRYPTED!

    if (retrans == null) {
      Log.error('$retransId not found in database');
      return;
    }

    if (retrans.acknowledgeByServerAt != null) {
      Log.error('$retransId message already retransmitted');
      return;
    }

    final json = MessageJson.fromJson(
      jsonDecode(
        utf8.decode(
          gzip.decode(retrans.plaintextContent),
        ),
      ) as Map<String, dynamic>,
    );

    Log.info('Retransmitting $retransId: ${json.kind} to ${retrans.contactId}');

    final contact = await twonlyDB.contactsDao
        .getContactByUserId(retrans.contactId)
        .getSingleOrNull();
    if (contact == null || contact.deleted) {
      Log.warn('Contact deleted $retransId or not found in database.');
      await twonlyDB.messageRetransmissionDao
          .deleteRetransmissionById(retransId);
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
            retryCount: Value(retrans.retryCount + 1),
            lastRetry: Value(DateTime.now()),
          ),
        );
      }
    }
  } catch (e) {
    Log.error('error resending message: $e');
    await twonlyDB.messageRetransmissionDao.deleteRetransmissionById(retransId);
  }
}

Future<void> sendCipherText(
  int contactId,
  pb.EncryptedContent encryptedContent,
) async {
  final response = pb.Message()
    ..type = pb.Message_Type.CIPHERTEXT
    ..encryptedContent = encryptedContent.writeToBuffer();

  final receipt = await twonlyDB.receiptsDao.insertReceipt(
    ReceiptsCompanion(
      contactId: Value(contactId),
      message: Value(response.writeToBuffer()),
    ),
  );

  if (receipt != null) {
    await tryToSendCompleteMessage(receipt.receiptId);
  }
}

// Future<void> sendTextMessage(
//   int target,
//   TextMessageContent content,
//   PushNotification? pushNotification,
// ) async {
//   final messageSendAt = DateTime.now();
//   DateTime? openedAt;

//   if (pushNotification != null && pushNotification.hasReactionContent()) {
//     openedAt = DateTime.now();
//   }

//   final messageId = await twonlyDB.messagesDao.insertMessage(
//     MessagesCompanion(
//       contactId: Value(target),
//       kind: const Value(MessageKind.textMessage),
//       sendAt: Value(messageSendAt),
//       responseToOtherMessageId: Value(content.responseToMessageId),
//       responseToMessageId: Value(content.responseToOtherMessageId),
//       downloadState: const Value(DownloadState.downloaded),
//       openedAt: Value(openedAt),
//       contentJson: Value(
//         jsonEncode(content.toJson()),
//       ),
//     ),
//   );

//   if (messageId == null) return;

//   if (pushNotification != null && !pushNotification.hasReactionContent()) {
//     pushNotification.messageId = Int64(messageId);
//   }

//   final msg = MessageJson(
//     kind: MessageKind.textMessage,
//     messageSenderId: messageId,
//     content: content,
//     timestamp: messageSendAt,
//   );

//   await encryptAndSendMessageAsync(
//     messageId,
//     target,
//     msg,
//     pushNotification: pushNotification,
//   );
// }

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

Future<void> notifyContactsAboutProfileChange({int? onlyToContact}) async {
  final user = await getUser();
  if (user == null) return;
  if (user.avatarSvg == null) return;

  final encryptedContent = pb.EncryptedContent()
    ..contactUpdate = (pb.EncryptedContent_ContactUpdate()
      ..type = pb.EncryptedContent_ContactUpdate_Type.UPDATE
      ..avatarSvg = user.avatarSvg!
      ..displayName = user.displayName);

  if (onlyToContact != null) {
    await sendCipherText(onlyToContact, encryptedContent);
    return;
  }

  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();

  for (final contact in contacts) {
    await sendCipherText(contact.userId, encryptedContent);
  }
}
