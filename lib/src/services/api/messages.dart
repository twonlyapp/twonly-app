import 'dart:async';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/model/protobuf/client/generated/push_notification.pb.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

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
  bool reupload = false,
  bool onlyReturnEncryptedData = false,
}) async {
  try {
    if (receiptId == null && receipt == null) return null;
    if (receipt == null) {
      receipt = await twonlyDB.receiptsDao.getReceiptById(receiptId!);
      if (receipt == null) {
        Log.error('Receipt $receiptId not found.');
        return null;
      }
    }
    receiptId = receipt.receiptId;

    if (reupload) {
      await twonlyDB.receiptsDao.updateReceipt(
        receiptId,
        const ReceiptsCompanion(
          ackByServerAt: Value(null),
        ),
      );
    }

    if (!onlyReturnEncryptedData && receipt.ackByServerAt != null) {
      Log.error('$receiptId message already uploaded!');
      return null;
    }

    Log.info('Uploading $receiptId (Message to ${receipt.contactId})');

    final message = pb.Message.fromBuffer(receipt.message)
      ..receiptId = receiptId;

    final encryptedContent =
        pb.EncryptedContent.fromBuffer(message.encryptedContent);

    var pushData = await getPushDataFromEncryptedContent(
      receipt.contactId,
      receipt.messageId,
      encryptedContent,
    );

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
      Log.error('Could not transmit message $receiptId got ${resp.error}.');
      if (resp.error == ErrorCode.UserIdNotFound) {
        await twonlyDB.receiptsDao.deleteReceipt(receiptId);
        await twonlyDB.contactsDao.updateContact(
          receipt.contactId,
          const ContactsCompanion(deleted: Value(true)),
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
) async {
  final message = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      groupId: Value(groupId),
      content: Value(textMessage),
    ),
  );
  if (message == null) {
    Log.error('Could not insert message into database');
    return;
  }

  final groupMembers = await twonlyDB.groupsDao.getGroupMembers(groupId);

  for (final groupMember in groupMembers) {
    unawaited(sendCipherText(
      groupMember.contactId,
      pb.EncryptedContent(
        textMessage: pb.EncryptedContent_TextMessage(
          senderMessageId: message.messageId,
          text: textMessage,
          timestamp: Int64(message.createdAt.millisecondsSinceEpoch),
        ),
      ),
    ));
  }
}

Future<(Uint8List, Uint8List?)?> sendCipherText(
  int contactId,
  pb.EncryptedContent encryptedContent, {
  bool onlyReturnEncryptedData = false,
}) async {
  final response = pb.Message()
    ..type = pb.Message_Type.CIPHERTEXT
    ..encryptedContent = encryptedContent.writeToBuffer();

  final receipt = await twonlyDB.receiptsDao.insertReceipt(
    ReceiptsCompanion(
      contactId: Value(contactId),
      message: Value(response.writeToBuffer()),
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
  await sendCipherText(
    contactId,
    pb.EncryptedContent(
      messageUpdate: pb.EncryptedContent_MessageUpdate(
        type: pb.EncryptedContent_MessageUpdate_Type.OPENED,
        multipleSenderMessageIds: messageOtherIds,
      ),
    ),
  );
  await updateLastMessageId(contactId, biggestMessageId);
}

Future<void> notifyContactsAboutProfileChange({int? onlyToContact}) async {
  final user = await getUser();
  if (user == null) return;
  if (user.avatarSvg == null) return;

  final encryptedContent = pb.EncryptedContent(
    contactUpdate: pb.EncryptedContent_ContactUpdate(
      type: pb.EncryptedContent_ContactUpdate_Type.UPDATE,
      avatarSvg: user.avatarSvg,
      displayName: user.displayName,
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
