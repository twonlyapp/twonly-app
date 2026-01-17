import 'dart:async';
import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart' hide Message;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pbserver.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/client2client/contact.c2c.dart';
import 'package:twonly/src/services/api/client2client/errors.c2c.dart';
import 'package:twonly/src/services/api/client2client/groups.c2c.dart';
import 'package:twonly/src/services/api/client2client/media.c2c.dart';
import 'package:twonly/src/services/api/client2client/messages.c2c.dart';
import 'package:twonly/src/services/api/client2client/prekeys.c2c.dart';
import 'package:twonly/src/services/api/client2client/pushkeys.c2c.dart';
import 'package:twonly/src/services/api/client2client/reaction.c2c.dart';
import 'package:twonly/src/services/api/client2client/text_message.c2c.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

final lockHandleServerMessage = Mutex();

Future<void> handleServerMessage(server.ServerToClient msg) async {
  /// Returns means, that the server can delete the message from the server.
  final ok = client.Response_Ok()..none = true;
  var response = client.Response()..ok = ok;

  try {
    if (msg.v0.hasRequestNewPreKeys()) {
      response = await handleRequestNewPreKey();
    } else if (msg.v0.hasNewMessage()) {
      await handleClient2ClientMessage(msg.v0.newMessage);
    } else if (msg.v0.hasNewMessages()) {
      for (final newMessage in msg.v0.newMessages.newMessages) {
        try {
          await handleClient2ClientMessage(newMessage);
        } catch (e) {
          Log.error(e);
        }
      }
    } else {
      Log.error('Unknown server message: $msg');
    }
  } catch (e) {
    Log.error(e);
  }

  final v0 = client.V0()
    ..seq = msg.v0.seq
    ..response = response;

  await apiService.sendResponse(ClientToServer()..v0 = v0);
}

DateTime lastPushKeyRequest = clock.now().subtract(const Duration(hours: 1));

Mutex protectReceiptCheck = Mutex();

Future<void> handleClient2ClientMessage(NewMessage newMessage) async {
  final body = Uint8List.fromList(newMessage.body);
  final fromUserId = newMessage.fromUserId.toInt();

  final message = Message.fromBuffer(body);
  final receiptId = message.receiptId;

  await protectReceiptCheck.protect(() async {
    if (await twonlyDB.receiptsDao.isDuplicated(receiptId)) {
      Log.warn('Got duplicated message from the server.');
      return;
    }
    await twonlyDB.receiptsDao.gotReceipt(receiptId);
  });

  switch (message.type) {
    case Message_Type.SENDER_DELIVERY_RECEIPT:
      Log.info('Got delivery receipt for $receiptId!');
      await twonlyDB.receiptsDao.confirmReceipt(receiptId, fromUserId);

    case Message_Type.PLAINTEXT_CONTENT:
      var retry = false;
      if (message.hasPlaintextContent()) {
        if (message.plaintextContent.hasDecryptionErrorMessage()) {
          Log.info(
            'Got decryption error: ${message.plaintextContent.decryptionErrorMessage.type} for $receiptId',
          );
          retry = true;
        }
        if (message.plaintextContent.hasRetryControlError()) {
          Log.info(
            'Got access control error for $receiptId. Resending message.',
          );
          retry = true;
        }
      }

      if (retry) {
        final newReceiptId = uuid.v4();
        await twonlyDB.receiptsDao.updateReceipt(
          receiptId,
          ReceiptsCompanion(
            receiptId: Value(newReceiptId),
            ackByServerAt: const Value(null),
          ),
        );
        await tryToSendCompleteMessage(receiptId: newReceiptId);
      }

    case Message_Type.CIPHERTEXT:
    case Message_Type.PREKEY_BUNDLE:
      if (message.hasEncryptedContent()) {
        Value<String>? receiptIdDB;

        final encryptedContentRaw =
            Uint8List.fromList(message.encryptedContent);

        Message? response;

        final user = await twonlyDB.contactsDao
            .getContactByUserId(fromUserId)
            .getSingleOrNull();

        if (user == null) {
          if (!await addNewHiddenContact(fromUserId)) {
            // in case the user could not be added, send a retry error message as this error should only happen in case
            // it was not possible to load the user from the server
            response = Message(
              receiptId: receiptId,
              type: Message_Type.PLAINTEXT_CONTENT,
              plaintextContent: PlaintextContent(
                retryControlError: PlaintextContent_RetryErrorMessage(),
              ),
            );
          }
        }

        if (response == null) {
          final (encryptedContent, plainTextContent) =
              await handleEncryptedMessage(
            fromUserId,
            encryptedContentRaw,
            message.type,
            receiptId,
          );
          if (plainTextContent != null) {
            response = Message(
              receiptId: receiptId,
              type: Message_Type.PLAINTEXT_CONTENT,
              plaintextContent: plainTextContent,
            );
          } else if (encryptedContent != null) {
            response = Message(
              type: Message_Type.CIPHERTEXT,
              encryptedContent: encryptedContent.writeToBuffer(),
            );
            receiptIdDB = const Value.absent();
          }
        }

        response ??= Message(type: Message_Type.SENDER_DELIVERY_RECEIPT);

        try {
          await twonlyDB.receiptsDao.insertReceipt(
            ReceiptsCompanion(
              receiptId: receiptIdDB ?? Value(receiptId),
              contactId: Value(fromUserId),
              message: Value(response.writeToBuffer()),
              contactWillSendsReceipt: const Value(false),
            ),
          );
        } catch (e) {
          Log.warn(e);
        }
        await tryToSendCompleteMessage(receiptId: receiptId);
      }
    case Message_Type.TEST_NOTIFICATION:
      return;
  }
}

Future<(EncryptedContent?, PlaintextContent?)> handleEncryptedMessage(
  int fromUserId,
  Uint8List encryptedContentRaw,
  Message_Type messageType,
  String receiptId,
) async {
  final (content, decryptionErrorType) = await signalDecryptMessage(
    fromUserId,
    encryptedContentRaw,
    messageType.value,
  );

  if (content == null) {
    return (
      null,
      PlaintextContent()
        ..decryptionErrorMessage = (PlaintextContent_DecryptionErrorMessage()
          ..type = decryptionErrorType!)
    );
  }

  // We got a valid message fromUserId, so mark all messages which where
  // send to the user but not yet ACK for retransmission. All marked messages
  // will be either transmitted again after a new server connection (minimum 20 seconds).
  // In case the server sends the ACK before they will be deleted.
  // This ensures that 1. all messages will be received by the other person and
  // that they will be retransmitted in case the server deleted them as they
  // where not downloaded within the 40 days
  await twonlyDB.receiptsDao.markMessagesForRetry(fromUserId);

  final senderProfileCounter = await checkForProfileUpdate(fromUserId, content);

  if (content.hasContactRequest()) {
    if (!await handleContactRequest(fromUserId, content.contactRequest)) {
      return (
        null,
        PlaintextContent()
          ..retryControlError = PlaintextContent_RetryErrorMessage()
      );
    }
    return (null, null);
  }

  if (content.hasErrorMessages()) {
    await handleErrorMessage(
      fromUserId,
      content.errorMessages,
    );
    return (null, null);
  }

  if (content.hasContactUpdate()) {
    await handleContactUpdate(
      fromUserId,
      content.contactUpdate,
      senderProfileCounter,
    );
    return (null, null);
  }

  if (content.hasFlameSync()) {
    await handleFlameSync(fromUserId, content.flameSync);
    return (null, null);
  }

  if (content.hasPushKeys()) {
    await handlePushKey(fromUserId, content.pushKeys);
    return (null, null);
  }

  if (content.hasMessageUpdate()) {
    await handleMessageUpdate(
      fromUserId,
      content.messageUpdate,
    );
    return (null, null);
  }

  if (content.hasMediaUpdate()) {
    await handleMediaUpdate(
      fromUserId,
      content.mediaUpdate,
    );
    return (null, null);
  }

  if (!content.hasGroupId()) {
    Log.error('Messages should have a groupId $fromUserId.');
    return (null, null);
  }

  if (content.hasGroupCreate()) {
    await handleGroupCreate(
      fromUserId,
      content.groupId,
      content.groupCreate,
    );
    return (null, null);
  }

  /// Verify that the user is (still) in that group...
  if (!await twonlyDB.groupsDao.isContactInGroup(fromUserId, content.groupId)) {
    if (getUUIDforDirectChat(gUser.userId, fromUserId) == content.groupId) {
      final contact = await twonlyDB.contactsDao
          .getContactByUserId(fromUserId)
          .getSingleOrNull();
      if (contact == null || contact.deletedByUser) {
        await handleNewContactRequest(fromUserId);
        Log.error(
          'User tries to send message to direct chat while the user does not exists !',
        );
        return (
          EncryptedContent(
            errorMessages: EncryptedContent_ErrorMessages(
              type: EncryptedContent_ErrorMessages_Type
                  .ERROR_PROCESSING_MESSAGE_CREATED_ACCOUNT_REQUEST_INSTEAD,
              relatedReceiptId: receiptId,
            ),
          ),
          null
        );
      }
      Log.info(
        'Creating new DirectChat between two users',
      );
      await twonlyDB.groupsDao.createNewDirectChat(
        fromUserId,
        GroupsCompanion(
          groupName: Value(getContactDisplayName(contact)),
        ),
      );
    } else {
      if (content.hasGroupJoin()) {
        Log.error(
          'Got group join message, but group does not exists yet, retry later. As probably the GroupCreate was not yet received.',
        );
        // In case the group join was received before the GroupCreate the sender should send it later again.
        return (
          null,
          PlaintextContent()
            ..retryControlError = PlaintextContent_RetryErrorMessage()
        );
      }

      Log.error('User $fromUserId tried to access group ${content.groupId}.');
      return (null, null);
    }
  }

  if (content.hasGroupUpdate()) {
    await handleGroupUpdate(
      fromUserId,
      content.groupId,
      content.groupUpdate,
    );
    return (null, null);
  }

  if (content.hasGroupJoin()) {
    if (!await handleGroupJoin(
      fromUserId,
      content.groupId,
      content.groupJoin,
    )) {
      return (
        null,
        PlaintextContent()
          ..retryControlError = PlaintextContent_RetryErrorMessage()
      );
    }
    return (null, null);
  }

  if (content.hasResendGroupPublicKey()) {
    await handleResendGroupPublicKey(
      fromUserId,
      content.groupId,
      content.groupJoin,
    );
    return (null, null);
  }

  if (content.hasTextMessage()) {
    await handleTextMessage(
      fromUserId,
      content.groupId,
      content.textMessage,
    );
    return (null, null);
  }

  if (content.hasReaction()) {
    await handleReaction(
      fromUserId,
      content.groupId,
      content.reaction,
    );
    return (null, null);
  }

  if (content.hasMedia()) {
    await handleMedia(
      fromUserId,
      content.groupId,
      content.media,
    );
    return (null, null);
  }

  return (null, null);
}
