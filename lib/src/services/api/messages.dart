import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/model/protobuf/client/generated/push_notification.pb.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

final lockRetransmission = Mutex();

Future<void> tryTransmitMessages() async {
  return lockRetransmission.protect(() async {
    final receipts = await twonlyDB.receiptsDao.getReceiptsForRetransmission();

    if (receipts.isEmpty) return;

    Log.info('Reuploading ${receipts.length} messages to the server.');

    final contacts = <int, Contact>{};

    for (final receipt in receipts) {
      if (receipt.markForRetryAfterAccepted != null) {
        if (!contacts.containsKey(receipt.contactId)) {
          final contact = await twonlyDB.contactsDao
              .getContactByUserId(receipt.contactId)
              .getSingleOrNull();
          if (contact == null) {
            Log.error(
              'Contact does not exists, but has a record in receipts, this should not be possible, because of the DELETE CASCADE relation.',
            );
            continue;
          }
          contacts[receipt.contactId] = contact;
        }
        if (!(contacts[receipt.contactId]?.accepted ?? true)) {
          Log.warn(
            'Could not send message as contact has still not yet accepted.',
          );
          continue;
        }
      }
      await tryToSendCompleteMessage(receipt: receipt);
    }
  });
}

// When the ackByServerAt is set this value is written in the receipted
Future<(Uint8List, Uint8List?)?> tryToSendCompleteMessage({
  String? receiptId,
  Receipt? receipt,
  bool onlyReturnEncryptedData = false,
  bool blocking = true,
}) async {
  try {
    if (receiptId == null && receipt == null) return null;
    if (receipt == null) {
      // ignore: parameter_assignments
      receipt = await twonlyDB.receiptsDao.getReceiptById(receiptId!);
      if (receipt == null) {
        Log.warn('Receipt not found.');
        return null;
      }
    }
    // ignore: parameter_assignments
    receiptId = receipt.receiptId;

    final contact =
        await twonlyDB.contactsDao.getContactById(receipt.contactId);
    if (contact == null || contact.accountDeleted) {
      Log.warn('Will not send message again as user does not exist anymore.');
      await twonlyDB.receiptsDao.deleteReceipt(receiptId);
      return null;
    }

    if (!onlyReturnEncryptedData &&
        receipt.ackByServerAt != null &&
        receipt.markForRetry == null) {
      Log.error('Message already uploaded and mark for retry is not set!');
      return null;
    }

    Log.info('Uploading $receiptId');

    final message = pb.Message.fromBuffer(receipt.message)
      ..receiptId = receiptId;

    final encryptedContent =
        pb.EncryptedContent.fromBuffer(message.encryptedContent);

    final pushNotification = await getPushNotificationFromEncryptedContent(
      receipt.contactId,
      receipt.messageId,
      encryptedContent,
    );

    Uint8List? pushData;
    if (pushNotification != null && receipt.retryCount <= 3) {
      /// In case the message has to be resend more than three times, do not show a notification again...
      pushData =
          await encryptPushNotification(receipt.contactId, pushNotification);
    }

    if (message.type == pb.Message_Type.TEST_NOTIFICATION) {
      pushData = (PushNotification()..kind = PushKind.testNotification)
          .writeToBuffer();
    }

    if (message.type == pb.Message_Type.CIPHERTEXT) {
      final cipherText = await signalEncryptMessage(
        receipt.contactId,
        Uint8List.fromList(message.encryptedContent),
      );
      if (cipherText == null) {
        Log.error('Could not encrypt the message. Aborting and trying again.');
        return null;
      }
      message.encryptedContent = cipherText.serialize();
      switch (cipherText.getType()) {
        case CiphertextMessage.prekeyType:
          message.type = pb.Message_Type.PREKEY_BUNDLE;
        case CiphertextMessage.whisperType:
          message.type = pb.Message_Type.CIPHERTEXT;
        default:
          Log.error('Invalid ciphertext type: ${cipherText.getType()}.');
          return null;
      }
    }

    if (onlyReturnEncryptedData) {
      return (message.writeToBuffer(), pushData);
    }

    final resp = await apiService.sendTextMessage(
      receipt.contactId,
      message.writeToBuffer(),
      pushData,
    );

    if (resp.isError) {
      Log.warn('Could not transmit message got ${resp.error}.');
      if (resp.error == ErrorCode.UserIdNotFound) {
        await twonlyDB.receiptsDao.deleteReceipt(receiptId);
        await twonlyDB.contactsDao.updateContact(
          receipt.contactId,
          const ContactsCompanion(accountDeleted: Value(true)),
        );
        return null;
      }
    }

    if (resp.isSuccess) {
      if (receipt.messageId != null) {
        await twonlyDB.messagesDao.handleMessageAckByServer(
          receipt.contactId,
          receipt.messageId!,
          clock.now(),
        );
      }
      if (!receipt.contactWillSendsReceipt) {
        await twonlyDB.receiptsDao.deleteReceipt(receiptId);
      } else {
        await twonlyDB.receiptsDao.updateReceipt(
          receiptId,
          ReceiptsCompanion(
            ackByServerAt: Value(clock.now()),
            retryCount: Value(receipt.retryCount + 1),
            lastRetry: Value(clock.now()),
            markForRetry: const Value(null),
          ),
        );
      }
    }
  } catch (e) {
    Log.error('Unknown Error when sending message: $e');
    if (receiptId != null) {
      await twonlyDB.receiptsDao.deleteReceipt(receiptId);
    }
  }
  return null;
}

Future<void> insertAndSendTextMessage(
  String groupId,
  String textMessage,
  String? quotesMessageId,
) async {
  await twonlyDB.groupsDao.updateGroup(
    groupId,
    const GroupsCompanion(
      draftMessage: Value(null),
    ),
  );
  final message = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      groupId: Value(groupId),
      content: Value(textMessage),
      type: Value(MessageType.text.name),
      quotesMessageId: Value(quotesMessageId),
    ),
  );
  if (message == null) {
    Log.error('Could not insert message into database');
    return;
  }

  final encryptedContent = pb.EncryptedContent(
    textMessage: pb.EncryptedContent_TextMessage(
      senderMessageId: message.messageId,
      text: textMessage,
      timestamp: Int64(message.createdAt.millisecondsSinceEpoch),
    ),
  );

  if (quotesMessageId != null) {
    encryptedContent.textMessage.quoteMessageId = quotesMessageId;
  }

  await sendCipherTextToGroup(
    groupId,
    encryptedContent,
    messageId: message.messageId,
  );
}

Future<void> insertAndSendContactShareMessage(
  String groupId,
  List<int> contactsToShare,
) async {
  final contacts = <SharedContact>[];

  for (final contactId in contactsToShare) {
    final contact = await twonlyDB.contactsDao.getContactById(contactId);
    if (contact != null) {
      final publicIdentityKey = await getPublicKeyFromContact(contactId);

      contacts.add(
        SharedContact(
          userId: Int64(contact.userId),
          publicIdentityKey: publicIdentityKey,
          displayName: getContactDisplayName(contact),
        ),
      );
    }
  }

  final additionalMessageData = AdditionalMessageData(
    type: AdditionalMessageData_Type.CONTACTS,
    contacts: contacts,
  );

  final message = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      groupId: Value(groupId),
      type: Value(MessageType.contacts.name),
      additionalMessageData: Value(additionalMessageData.writeToBuffer()),
    ),
  );

  if (message == null) {
    Log.error('Could not insert message into database');
    return;
  }

  final encryptedContent = pb.EncryptedContent(
    additionalDataMessage: pb.EncryptedContent_AdditionalDataMessage(
      senderMessageId: message.messageId,
      additionalMessageData: additionalMessageData.writeToBuffer(),
      timestamp: Int64(message.createdAt.millisecondsSinceEpoch),
      type: MessageType.contacts.name,
    ),
  );

  await sendCipherTextToGroup(
    groupId,
    encryptedContent,
    messageId: message.messageId,
  );
}

Future<void> sendCipherTextToGroup(
  String groupId,
  pb.EncryptedContent encryptedContent, {
  String? messageId,
}) async {
  final groupMembers = await twonlyDB.groupsDao.getGroupNonLeftMembers(groupId);

  await twonlyDB.groupsDao.increaseLastMessageExchange(groupId, clock.now());

  encryptedContent.groupId = groupId;

  for (final groupMember in groupMembers) {
    await sendCipherText(
      groupMember.contactId,
      encryptedContent,
      messageId: messageId,
      blocking: false,
    );
  }
}

Future<(Uint8List, Uint8List?)?> sendCipherText(
  int contactId,
  pb.EncryptedContent encryptedContent, {
  bool onlyReturnEncryptedData = false,
  bool blocking = true,
  String? messageId,
}) async {
  encryptedContent.senderProfileCounter = Int64(gUser.avatarCounter);

  final response = pb.Message()
    ..type = pb.Message_Type.CIPHERTEXT
    ..encryptedContent = encryptedContent.writeToBuffer();

  final receipt = await twonlyDB.receiptsDao.insertReceipt(
    ReceiptsCompanion(
      contactId: Value(contactId),
      message: Value(response.writeToBuffer()),
      messageId: Value(messageId),
      ackByServerAt: Value(onlyReturnEncryptedData ? clock.now() : null),
    ),
  );

  if (receipt != null) {
    final tmp = tryToSendCompleteMessage(
      receipt: receipt,
      onlyReturnEncryptedData: onlyReturnEncryptedData,
      blocking: blocking,
    );
    if (!blocking) {
      return null;
    }
    return tmp;
  }
  return null;
}

Future<void> notifyContactAboutOpeningMessage(
  int contactId,
  List<String> messageOtherIds,
) async {
  var biggestMessageId = messageOtherIds.first;

  for (final messageOtherId in messageOtherIds) {
    if (isUUIDNewer(messageOtherId, biggestMessageId)) {
      biggestMessageId = messageOtherId;
    }
  }
  Log.info('Opened messages: $messageOtherIds');

  final actionAt = clock.now();

  await sendCipherText(
    contactId,
    pb.EncryptedContent(
      messageUpdate: pb.EncryptedContent_MessageUpdate(
        type: pb.EncryptedContent_MessageUpdate_Type.OPENED,
        multipleTargetMessageIds: messageOtherIds,
        timestamp: Int64(actionAt.millisecondsSinceEpoch),
      ),
    ),
    blocking: false,
  );
  await twonlyDB.batch((batch) {
    for (final messageId in messageOtherIds) {
      batch.update(
        twonlyDB.messages,
        MessagesCompanion(
          openedAt: Value(actionAt),
          openedByAll: Value(actionAt),
        ),
        where: (tbl) => tbl.messageId.equals(messageId),
      );
    }
  });
  await updateLastMessageId(contactId, biggestMessageId);
}

Future<void> sendContactMyProfileData(int contactId) async {
  List<int>? avatarSvgCompressed;
  if (gUser.avatarSvg != null) {
    avatarSvgCompressed = gzip.encode(utf8.encode(gUser.avatarSvg!));
  }
  final encryptedContent = pb.EncryptedContent(
    contactUpdate: pb.EncryptedContent_ContactUpdate(
      type: pb.EncryptedContent_ContactUpdate_Type.UPDATE,
      avatarSvgCompressed: avatarSvgCompressed,
      displayName: gUser.displayName,
      username: gUser.username,
    ),
  );
  await sendCipherText(contactId, encryptedContent);
}
