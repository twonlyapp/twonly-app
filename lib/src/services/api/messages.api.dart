import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/locator.dart';
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
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

final lockRetransmission = Mutex();

Future<void> retransmitAllMessages() async {
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

final Map<String, Mutex> _tryToSendLocks = {};

// When the ackByServerAt is set this value is written in the receipted
Future<(Uint8List, Uint8List?)?> tryToSendCompleteMessage({
  String? receiptId,
  Receipt? receipt,
  bool onlyReturnEncryptedData = false,
  bool blocking = true,
}) async {
  final rId = receiptId ?? receipt?.receiptId;
  if (rId == null) {
    Log.error(
      'Cannot try to send complete message as both receiptId and receipt are null.',
    );
    return null;
  }

  final mutex = _tryToSendLocks.putIfAbsent(rId, Mutex.new);
  return mutex.protect(() async {
    return _tryToSendCompleteMessageInternal(
      receiptId: receiptId,
      receipt: receipt,
      onlyReturnEncryptedData: onlyReturnEncryptedData,
      blocking: blocking,
    );
  });
}

Future<(Uint8List, Uint8List?)?> _tryToSendCompleteMessageInternal({
  String? receiptId,
  Receipt? receipt,
  bool onlyReturnEncryptedData = false,
  bool blocking = true,
}) async {
  // this should have a lock for every receiptID, split the function into a _internal withou the lock and a normal with the lock
  if (apiService.appIsOutdated) return null;
  if (receiptId == null && receipt == null) return null;

  try {
    if (receipt == null) {
      // ignore: parameter_assignments
      receipt = await twonlyDB.receiptsDao.getReceiptById(receiptId!);
      if (receipt == null) {
        Log.warn('[$receiptId] Receipt not found.');
        return null;
      }
    }

    if (receipt.retryCount >= 2) {
      // After two retries, change the receiptId. This addresses a bug where the receiver received the message and marked it as received,
      // but the app was closed before the message was fully processed. Because the receipt was already stored, subsequent retries were
      // detected as duplicates and rejected.
      final oldReceiptId = receipt.receiptId;
      final updatedReceipt = await twonlyDB.receiptsDao.rotateReceiptId(
        oldReceiptId,
      );
      if (updatedReceipt != null) {
        Log.info(
          'Changed receiptId $oldReceiptId to ${updatedReceipt.receiptId} as retryCount is ${receipt.retryCount}',
        );
        receipt = updatedReceipt;
      }
    }

    final contact = await twonlyDB.contactsDao.getContactById(
      receipt.contactId,
    );
    if (contact == null || contact.accountDeleted) {
      Log.warn('Will not send message again as user does not exist anymore.');
      await twonlyDB.receiptsDao.deleteReceipt(receipt.receiptId);
      return null;
    }

    if (!onlyReturnEncryptedData &&
        receipt.ackByServerAt != null &&
        receipt.markForRetry == null) {
      Log.error('Message already uploaded and mark for retry is not set!');
      return null;
    }

    final message = pb.Message.fromBuffer(receipt.message)
      ..receiptId = receipt.receiptId;

    final encryptedContent = pb.EncryptedContent.fromBuffer(
      message.encryptedContent,
    );

    Uint8List? pushData;
    if (receipt.retryCount == 0) {
      final pushNotification = await getPushNotificationFromEncryptedContent(
        receipt.contactId,
        receipt.messageId,
        encryptedContent,
      );

      if (pushNotification != null) {
        // Only show the push notification the first two time.
        pushData = await encryptPushNotification(
          receipt.contactId,
          pushNotification,
        );
      }
    }

    if (message.type == pb.Message_Type.TEST_NOTIFICATION) {
      pushData = (PushNotification()..kind = PushKind.TEST_NOTIFICATION)
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
      Log.info('Returning message  with receiptID ${receipt.receiptId}.');
      return (message.writeToBuffer(), pushData);
    }

    Log.info('Uploading message with receiptID ${receipt.receiptId}.');

    final resp = await apiService.sendTextMessage(
      receipt.contactId,
      message.writeToBuffer(),
      pushData,
    );

    if (resp.isError) {
      Log.warn('Could not transmit ${receipt.receiptId} got ${resp.error}.');
      if (resp.error == ErrorCode.UserIdNotFound) {
        await twonlyDB.receiptsDao.deleteReceipt(receipt.receiptId);
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
        await twonlyDB.receiptsDao.deleteReceipt(receipt.receiptId);
      } else {
        await twonlyDB.receiptsDao.updateReceipt(
          receipt.receiptId,
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
    Log.error('[$receiptId] unknown error when sending message: $e');
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

Future<void> insertAndSendAskAboutUserMessage(
  int contactId,
  int askAboutUserId,
) async {
  final directChat = await twonlyDB.groupsDao.createOrGetDirectChat(contactId);
  if (directChat == null) {
    Log.error(
      'Failed to get or create direct chat group for contact $contactId',
    );
    return;
  }

  final groupId = directChat.groupId;

  final additionalMessageData = AdditionalMessageData(
    type: AdditionalMessageData_Type.ASK_ABOUT_USER,
    askAboutUserId: Int64(askAboutUserId),
  );

  final message = await twonlyDB.messagesDao.insertMessage(
    MessagesCompanion(
      groupId: Value(groupId),
      type: Value(MessageType.askAboutUser.name),
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
      type: MessageType.askAboutUser.name,
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
  bool onlySendIfNoReceiptsAreOpen = false,
}) async {
  final groupMembers = await twonlyDB.groupsDao.getGroupNonLeftMembers(groupId);

  if (messageId != null ||
      encryptedContent.hasReaction() ||
      encryptedContent.hasMedia() ||
      encryptedContent.hasTextMessage()) {
    // only update the counter in case this is a actual message
    await twonlyDB.groupsDao.increaseLastMessageExchange(groupId, clock.now());
  }

  encryptedContent.groupId = groupId;

  for (final groupMember in groupMembers) {
    await sendCipherText(
      groupMember.contactId,
      encryptedContent,
      messageId: messageId,
      blocking: false,
      onlySendIfNoReceiptsAreOpen: onlySendIfNoReceiptsAreOpen,
    );
  }
}

Future<(Uint8List, Uint8List?)?> sendCipherText(
  int contactId,
  pb.EncryptedContent encryptedContent, {
  bool onlyReturnEncryptedData = false,
  bool blocking = true,
  String? messageId,
  bool onlySendIfNoReceiptsAreOpen = false,
}) async {
  if (onlySendIfNoReceiptsAreOpen) {
    final openReceipts = await twonlyDB.receiptsDao.getReceiptCountForContact(
      contactId,
    );
    if (openReceipts > 6) {
      // this prevents that these types of messages are send in case the receiver is offline
      return null;
    }
  }
  encryptedContent.senderProfileCounter = Int64(
    userService.currentUser.avatarCounter,
  );

  if (userService.currentUser.isUserDiscoveryEnabled && messageId != null) {
    final contact = await twonlyDB.contactsDao.getContactById(contactId);
    if (UserDiscoveryService.isContactAllowed(contact)) {
      final version = await UserDiscoveryService.getCurrentVersion();
      if (version != null) {
        encryptedContent.senderUserDiscoveryVersion = version;
      }
    }
  }

  final response = pb.Message()
    ..type = pb.Message_Type.CIPHERTEXT
    ..encryptedContent = encryptedContent.writeToBuffer();

  var retryCounter = 0;
  DateTime? lastRetry;

  if (messageId != null) {
    final receipts = await twonlyDB.receiptsDao
        .getReceiptsByContactAndMessageId(contactId, messageId);

    for (final receipt in receipts) {
      if (receipt.lastRetry != null) {
        lastRetry = receipt.lastRetry;
      }
      retryCounter += 1;
      Log.info('Removing duplicated receipt for message $messageId');
      await twonlyDB.receiptsDao.deleteReceipt(receipt.receiptId);
    }
  }

  final receipt = await twonlyDB.receiptsDao.insertReceipt(
    ReceiptsCompanion(
      contactId: Value(contactId),
      message: Value(response.writeToBuffer()),
      messageId: Value(messageId),
      willBeRetriedByMediaUpload: Value(onlyReturnEncryptedData),
      retryCount: Value(retryCounter),
      lastRetry: Value(lastRetry),
    ),
  );

  if (receipt != null) {
    try {
      final typeKeys = _getEncryptedContentTypes(encryptedContent);
      Log.info(
        'sendCipherText: type=[$typeKeys] messageId=$messageId receiptId=${receipt.receiptId}',
      );
    } catch (_) {
      Log.info(
        'sendCipherText: messageId=$messageId receiptId=${receipt.receiptId}',
      );
    }

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

Future<void> sendTypingIndication(String groupId, bool isTyping) async {
  if (!userService.currentUser.typingIndicators) return;
  await sendCipherTextToGroup(
    groupId,
    pb.EncryptedContent(
      typingIndicator: pb.EncryptedContent_TypingIndicator(
        isTyping: isTyping,
        createdAt: Int64(clock.now().millisecondsSinceEpoch),
      ),
    ),
    onlySendIfNoReceiptsAreOpen: true,
  );
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
  if (userService.currentUser.avatarSvg != null) {
    avatarSvgCompressed = gzip.encode(
      utf8.encode(userService.currentUser.avatarSvg!),
    );
  }
  final encryptedContent = pb.EncryptedContent(
    contactUpdate: pb.EncryptedContent_ContactUpdate(
      type: pb.EncryptedContent_ContactUpdate_Type.UPDATE,
      avatarSvgCompressed: avatarSvgCompressed,
      displayName: userService.currentUser.displayName,
      username: userService.currentUser.username,
    ),
  );
  await sendCipherText(contactId, encryptedContent, blocking: false);
}

String _getEncryptedContentTypes(pb.EncryptedContent content) {
  final ignoredFields = {
    'groupId',
    'isDirectChat',
    'senderProfileCounter',
    'senderUserDiscoveryVersion',
  };

  final types = <String>[];
  for (final field in content.info_.byName.values) {
    if (content.hasField(field.tagNumber) &&
        !ignoredFields.contains(field.name)) {
      types.add(field.name);
    }
  }
  return types.join(', ');
}
