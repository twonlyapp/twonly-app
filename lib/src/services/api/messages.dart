import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/model/protobuf/client/generated/push_notification.pb.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

final lockRetransmission = Mutex();

Future<void> tryTransmitMessages() async {
  return lockRetransmission.protect(() async {
    final receipts = await twonlyDB.receiptsDao.getReceiptsNotAckByServer();

    if (receipts.isEmpty) return;

    Log.info('Reuploading ${receipts.length} messages to the server.');

    for (final receipt in receipts) {
      await tryToSendCompleteMessage(receipt: receipt);
    }
  });
}

// When the ackByServerAt is set this value is written in the receipted
Future<(Uint8List, Uint8List?)?> tryToSendCompleteMessage({
  String? receiptId,
  Receipt? receipt,
  bool onlyReturnEncryptedData = false,
}) async {
  try {
    if (receiptId == null && receipt == null) return null;
    if (receipt == null) {
      receipt = await twonlyDB.receiptsDao.getReceiptById(receiptId!);
      if (receipt == null) {
        Log.error('Receipt not found.');
        return null;
      }
    }
    receiptId = receipt.receiptId;

    if (!onlyReturnEncryptedData && receipt.ackByServerAt != null) {
      Log.error('message already uploaded!');
      return null;
    }

    Log.info('Uploading $receiptId (Message to ${receipt.contactId})');

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
          DateTime.now(),
        );
      }
      if (!receipt.contactWillSendsReceipt) {
        await twonlyDB.receiptsDao.deleteReceipt(receiptId);
      } else {
        await twonlyDB.receiptsDao.updateReceipt(
          receiptId,
          ReceiptsCompanion(
            ackByServerAt: Value(DateTime.now()),
            retryCount: Value(receipt.retryCount + 1),
            lastRetry: Value(DateTime.now()),
          ),
        );
      }
    }
  } catch (e) {
    Log.error('Unknown Error when sending message: $e');
    if (receiptId != null) {
      await twonlyDB.receiptsDao.deleteReceipt(receiptId);
    }
    if (receipt != null) {
      await twonlyDB.receiptsDao.deleteReceipt(receipt.receiptId);
    }
  }
  return null;
}

Future<void> insertAndSendTextMessage(
  String groupId,
  String textMessage,
  String? quotesMessageId,
) async {
  final message = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      groupId: Value(groupId),
      content: Value(textMessage),
      type: const Value(MessageType.text),
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

Future<void> sendCipherTextToGroup(
  String groupId,
  pb.EncryptedContent encryptedContent, {
  String? messageId,
}) async {
  final groupMembers = await twonlyDB.groupsDao.getGroupNonLeftMembers(groupId);

  await twonlyDB.groupsDao.increaseLastMessageExchange(groupId, DateTime.now());

  encryptedContent.groupId = groupId;

  for (final groupMember in groupMembers) {
    unawaited(
      sendCipherText(
        groupMember.contactId,
        encryptedContent,
        messageId: messageId,
      ),
    );
  }
}

Future<(Uint8List, Uint8List?)?> sendCipherText(
  int contactId,
  pb.EncryptedContent encryptedContent, {
  bool onlyReturnEncryptedData = false,
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
      ackByServerAt: Value(onlyReturnEncryptedData ? DateTime.now() : null),
    ),
  );

  if (receipt != null) {
    return tryToSendCompleteMessage(
      receipt: receipt,
      onlyReturnEncryptedData: onlyReturnEncryptedData,
    );
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

  final actionAt = DateTime.now();

  await sendCipherText(
    contactId,
    pb.EncryptedContent(
      messageUpdate: pb.EncryptedContent_MessageUpdate(
        type: pb.EncryptedContent_MessageUpdate_Type.OPENED,
        multipleTargetMessageIds: messageOtherIds,
        timestamp: Int64(actionAt.millisecondsSinceEpoch),
      ),
    ),
  );
  for (final messageId in messageOtherIds) {
    await twonlyDB.messagesDao.updateMessageId(
      messageId,
      MessagesCompanion(
        openedAt: Value(actionAt),
        openedByAll: Value(actionAt),
      ),
    );
  }
  await updateLastMessageId(contactId, biggestMessageId);
}

Future<void> notifyContactsAboutProfileChange({int? onlyToContact}) async {
  if (gUser.avatarSvg == null) return;

  final encryptedContent = pb.EncryptedContent(
    contactUpdate: pb.EncryptedContent_ContactUpdate(
      type: pb.EncryptedContent_ContactUpdate_Type.UPDATE,
      avatarSvgCompressed: gzip.encode(utf8.encode(gUser.avatarSvg!)),
      displayName: gUser.displayName,
      username: gUser.username,
    ),
  );

  if (onlyToContact != null) {
    await sendCipherText(onlyToContact, encryptedContent);
    return;
  }

  final contacts = await twonlyDB.contactsDao.getAllNotBlockedContacts();

  for (final contact in contacts) {
    await sendCipherText(contact.userId, encryptedContent);
  }
}
