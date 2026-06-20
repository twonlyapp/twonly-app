import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:mutex/mutex.dart';

import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart' hide Message;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pbserver.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/client2client/additional_data.c2c.dart';
import 'package:twonly/src/services/api/client2client/contact.c2c.dart';
import 'package:twonly/src/services/api/client2client/errors.c2c.dart';
import 'package:twonly/src/services/api/client2client/groups.c2c.dart';
import 'package:twonly/src/services/api/client2client/media.c2c.dart';
import 'package:twonly/src/services/api/client2client/messages.c2c.dart';
import 'package:twonly/src/services/api/client2client/prekeys.c2c.dart';
import 'package:twonly/src/services/api/client2client/pushkeys.c2c.dart';
import 'package:twonly/src/services/api/client2client/reaction.c2c.dart';
import 'package:twonly/src/services/api/client2client/text_message.c2c.dart';
import 'package:twonly/src/services/api/client2client/user_discovery.c2c.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/group.service.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

Future<void> handleServerMessage(server.ServerToClient msg) async {
  Log.info('Processing a message from the server.');

  /// Returns means, that the server can delete the message from the server.
  final ok = client.Response_Ok()..none = true;
  var response = client.Response()..ok = ok;

  try {
    if (msg.v0.hasRequestNewPreKeys()) {
      response = await handleRequestNewPreKey();
    } else if (msg.v0.hasNewMessage()) {
      Log.info('Got 1 message from the server.');
      await handleClient2ClientMessage(msg.v0.newMessage);
    } else if (msg.v0.hasNewMessages()) {
      Log.info(
        'Got ${msg.v0.newMessages.newMessages.length} messages from the server.',
      );
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
  AppState.gotMessageFromServer = true;
  Log.info('All messages from the server proccessed.');
}

DateTime lastPushKeyRequest = clock.now().subtract(const Duration(hours: 1));

final Map<String, Mutex> _messageLocks = {};

Future<void> handleClient2ClientMessage(NewMessage newMessage) async {
  final body = Uint8List.fromList(newMessage.body);
  final message = Message.fromBuffer(body);
  final receiptId = message.receiptId;

  final mutex = _messageLocks.putIfAbsent(receiptId, Mutex.new);
  if (mutex.isLocked) {
    Log.info(
      '[$receiptId] Skipping — already being processed by another handler',
    );
    return;
  }
  await mutex.protect(() async {
    try {
      await _handleClient2ClientMessage(newMessage, message);
    } finally {
      _messageLocks.remove(receiptId);
    }
  });
}

Future<void> _handleClient2ClientMessage(
  NewMessage newMessage,
  Message message,
) async {
  final fromUserId = newMessage.fromUserId.toInt();
  final receiptId = message.receiptId;

  if (await twonlyDB.receiptsDao.isDuplicated(receiptId)) {
    return;
  }

  Log.info('[$receiptId] Started processing message');

  switch (message.type) {
    case Message_Type.SENDER_DELIVERY_RECEIPT:
      Log.info('[$receiptId] Got delivery receipt!');
      await twonlyDB.receiptsDao.confirmReceipt(receiptId, fromUserId);

    case Message_Type.PLAINTEXT_CONTENT:
      var retry = false;
      if (message.hasPlaintextContent()) {
        if (message.plaintextContent.hasDecryptionErrorMessage()) {
          if (message.plaintextContent.decryptionErrorMessage.type ==
              PlaintextContent_DecryptionErrorMessage_Type.PREKEY_UNKNOWN) {
            // Get a new prekey from the server, and establish a new signal session.
            await handleSessionResync(fromUserId);
          }
          Log.info(
            '[$receiptId] Got decryption error: ${message.plaintextContent.decryptionErrorMessage.type}',
          );
          retry = true;
        }
        if (message.plaintextContent.hasRetryControlError()) {
          Log.info(
            '[$receiptId] Got access control error. Resending message.',
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
        Log.info(
          '[$receiptId] Sending error message to the original sender with receiptId $newReceiptId.',
        );
        await tryToSendCompleteMessage(
          receiptId: newReceiptId,
          blocking: false,
        );
      }

    case Message_Type.CIPHERTEXT:
    case Message_Type.PREKEY_BUNDLE:
      if (message.hasEncryptedContent()) {
        Value<String>? receiptIdDB;

        final encryptedContentRaw = Uint8List.fromList(
          message.encryptedContent,
        );

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
          final (
            encryptedContent,
            plainTextContent,
          ) = await handleEncryptedMessageRaw(
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
            // Use Value.absent() for CIPHERTEXT messages so that insertReceipt generates a new UUID.
            // This prevents receipt ID collisions and ensures the recipient's ACK is tracked correctly.
            receiptIdDB = const Value.absent();
          } else {
            // Message was successful processed
          }
        }

        response ??= Message(type: Message_Type.SENDER_DELIVERY_RECEIPT);

        String? targetReceiptId;
        try {
          final inserted = await twonlyDB.receiptsDao.insertReceipt(
            ReceiptsCompanion(
              receiptId: receiptIdDB ?? Value(receiptId),
              contactId: Value(fromUserId),
              message: Value(response.writeToBuffer()),
              contactWillSendsReceipt: const Value(false),
            ),
          );
          // Use the inserted receipt's ID because for CIPHERTEXT messages we generate a new UUID
          // (receiptIdDB is Value.absent()) to avoid ID collisions and properly track individual ACKs.
          targetReceiptId = inserted?.receiptId;
        } catch (e) {
          Log.warn('[$receiptId] Error inserting receipt: $e');
        }
        if (targetReceiptId != null) {
          await tryToSendCompleteMessage(
            receiptId: targetReceiptId,
            blocking: false,
          );
        }
      }
    case Message_Type.TEST_NOTIFICATION:
      break;
  }

  try {
    await twonlyDB.receiptsDao.gotReceipt(receiptId);
    Log.info('[$receiptId] Finished processing');
  } catch (e) {
    Log.warn('[$receiptId] Error marking message as received: $e');
    Log.error(
      'Error marking message as received: $e',
      onlyIfSentryEnabled: true,
    );
  }
}

Future<(EncryptedContent?, PlaintextContent?)> handleEncryptedMessageRaw(
  int fromUserId,
  Uint8List encryptedContentRaw,
  Message_Type messageType,
  String receiptId,
) async {
  Log.info('[$receiptId] calling signalDecryptMessage');
  var (encryptedContent, decryptionErrorType) = await signalDecryptMessage(
    fromUserId,
    encryptedContentRaw,
    messageType.value,
  );

  if (encryptedContent == null) {
    return (
      null,
      PlaintextContent(
        decryptionErrorMessage: PlaintextContent_DecryptionErrorMessage(
          type: decryptionErrorType ??=
              PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
        ),
      ),
    );
  }

  Log.info('[$receiptId] Calling handleEncryptedMessage');

  final (a, b) = await handleEncryptedMessage(
    fromUserId,
    encryptedContent,
    messageType,
    receiptId,
  );

  Log.info('[$receiptId] Finished handleEncryptedMessage');

  if (a == null && b == null) {
    unawaited(FcmNotificationService.updateLastServerMessageTimestamp());
    if (Platform.isAndroid) {
      // Message was handled without any error. Show push notification to the user for Android.
      await showPushNotificationFromServerMessages(
        fromUserId,
        encryptedContent,
      );
    }
  }

  return (a, b);
}

Future<(EncryptedContent?, PlaintextContent?)> handleEncryptedMessage(
  int fromUserId,
  EncryptedContent content,
  Message_Type messageType,
  String receiptId,
) async {
  // We got a valid message fromUserId, so mark all messages which where
  // send to the user but not yet ACK for retransmission. All marked messages
  // will be either transmitted again after a new server connection (minimum 20 seconds).
  // In case the server sends the ACK before they will be deleted.
  // This ensures that 1. all messages will be received by the other person and
  // that they will be retransmitted in case the server deleted them as they
  // where not downloaded within the 40 days
  await twonlyDB.receiptsDao.markMessagesForRetry(fromUserId);

  final senderProfileCounter = await checkForProfileUpdate(fromUserId, content);
  if (userService.currentUser.isUserDiscoveryEnabled &&
      content.hasSenderUserDiscoveryVersion()) {
    await checkForUserDiscoveryChanges(
      fromUserId,
      content.senderUserDiscoveryVersion,
      receiptId,
    );
  }

  if (content.hasAskForFriendPromotions() && content.askForFriendPromotions) {
    final contact = await twonlyDB.contactsDao.getContactById(fromUserId);
    if (contact != null && contact.askForFriendPromotions == null) {
      await twonlyDB.contactsDao.updateContact(
        fromUserId,
        const ContactsCompanion(askForFriendPromotions: Value(true)),
      );
    }
  }

  if (content.hasContactRequest()) {
    if (!await handleContactRequest(
      fromUserId,
      content.contactRequest,
      receiptId,
    )) {
      return (
        null,
        PlaintextContent()
          ..retryControlError = PlaintextContent_RetryErrorMessage(),
      );
    }
    return (null, null);
  }

  if (content.hasErrorMessages()) {
    await handleErrorMessage(
      fromUserId,
      content.errorMessages,
      receiptId,
      groupId: content.hasGroupId() ? content.groupId : null,
    );
    return (null, null);
  }

  if (content.hasContactUpdate()) {
    await handleContactUpdate(
      fromUserId,
      content.contactUpdate,
      senderProfileCounter,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasUserDiscoveryRequest()) {
    await handleUserDiscoveryRequest(
      fromUserId,
      content.userDiscoveryRequest,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasUserDiscoveryUpdate()) {
    await handleUserDiscoveryUpdate(
      fromUserId,
      content.userDiscoveryUpdate,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasPushKeys()) {
    await handlePushKey(fromUserId, content.pushKeys, receiptId);
    return (null, null);
  }

  if (content.hasMessageUpdate()) {
    await handleMessageUpdate(
      fromUserId,
      content.messageUpdate,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasKeyVerificationProof()) {
    await KeyVerificationService.handleVerificationProof(
      fromUserId,
      content.keyVerificationProof.calculatedMac,
    );
    return (null, null);
  }

  if (content.hasMediaUpdate()) {
    await handleMediaUpdate(
      fromUserId,
      content.mediaUpdate,
      receiptId,
    );
    return (null, null);
  }

  if (!content.hasGroupId()) {
    final type = _getEncryptedContentType(content);
    Log.warn(
      '[$receiptId] Messages should have a groupId $fromUserId. Type: $type',
    );
    Log.error(
      'Messages should have a groupId. Type: $type',
      onlyIfSentryEnabled: true,
    );
    return (null, null);
  }

  if (content.hasGroupCreate()) {
    await handleGroupCreate(
      fromUserId,
      content.groupId,
      content.groupCreate,
      receiptId,
    );
    return (null, null);
  }

  /// Verify that the user is (still) in that group...
  if (!await twonlyDB.groupsDao.isContactInGroup(fromUserId, content.groupId)) {
    // Check if this is a direct chat...
    if (getUUIDforDirectChat(userService.currentUser.userId, fromUserId) ==
        content.groupId) {
      final contact = await twonlyDB.contactsDao
          .getContactByUserId(fromUserId)
          .getSingleOrNull();
      Log.info(
        '[$receiptId] Contact exists?: ${contact != null} Is deleted? ${contact?.deletedByUser} Accepted? (${contact?.accepted})',
      );
      if (contact == null || !contact.accepted || contact.deletedByUser) {
        await handleNewContactRequest(fromUserId);
        Log.warn(
          '[$receiptId] User tries to send message to direct chat while the user does not exist!',
        );
        return (
          EncryptedContent(
            errorMessages: EncryptedContent_ErrorMessages(
              type: EncryptedContent_ErrorMessages_Type
                  .ERROR_PROCESSING_MESSAGE_CREATED_ACCOUNT_REQUEST_INSTEAD,
              relatedReceiptId: receiptId,
            ),
          ),
          null,
        );
      }
      Log.info(
        '[$receiptId] Creating new DirectChat between two users',
      );
      await twonlyDB.groupsDao.createNewDirectChat(
        fromUserId,
        GroupsCompanion(
          groupName: Value(getContactDisplayName(contact)),
        ),
      );
    } else {
      if (content.hasGroupJoin()) {
        Log.warn(
          '[$receiptId] Got group join message, but group does not exist yet, retry later. As probably the GroupCreate was not yet received.',
        );
        // In case the group join was received before the GroupCreate the sender should send it later again.
        return (
          null,
          PlaintextContent()
            ..retryControlError = PlaintextContent_RetryErrorMessage(),
        );
      }

      Log.warn(
        '[$receiptId] User $fromUserId tried to access group ${content.groupId}. Sending GROUP_NOT_FOUND_OR_NOT_A_MEMBER error.',
      );
      return (
        EncryptedContent(
          groupId: content.groupId,
          errorMessages: EncryptedContent_ErrorMessages(
            type: EncryptedContent_ErrorMessages_Type
                .GROUP_NOT_FOUND_OR_NOT_A_MEMBER,
            relatedReceiptId: receiptId,
          ),
        ),
        null,
      );
    }
  }

  if (content.hasFlameSync()) {
    await handleFlameSync(content.groupId, content.flameSync, receiptId);
    return (null, null);
  }

  if (content.hasGroupUpdate()) {
    await handleGroupUpdate(
      fromUserId,
      content.groupId,
      content.groupUpdate,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasGroupJoin()) {
    if (!await handleGroupJoin(
      fromUserId,
      content.groupId,
      content.groupJoin,
      receiptId,
    )) {
      return (
        null,
        PlaintextContent()
          ..retryControlError = PlaintextContent_RetryErrorMessage(),
      );
    }
    return (null, null);
  }

  if (content.hasResendGroupPublicKey()) {
    await handleResendGroupPublicKey(
      fromUserId,
      content.groupId,
      content.groupJoin,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasAdditionalDataMessage()) {
    await handleAdditionalDataMessage(
      fromUserId,
      content.groupId,
      content.additionalDataMessage,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasTextMessage()) {
    await handleTextMessage(
      fromUserId,
      content.groupId,
      content.textMessage,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasReaction()) {
    await handleReaction(
      fromUserId,
      content.groupId,
      content.reaction,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasMedia()) {
    await handleMedia(
      fromUserId,
      content.groupId,
      content.media,
      receiptId,
    );
    return (null, null);
  }

  if (content.hasTypingIndicator()) {
    await handleTypingIndicator(
      fromUserId,
      content.groupId,
      content.typingIndicator,
      receiptId,
    );
  }

  return (null, null);
}

String _getEncryptedContentType(EncryptedContent content) {
  if (content.hasMessageUpdate()) return 'messageUpdate';
  if (content.hasMedia()) return 'media';
  if (content.hasMediaUpdate()) return 'mediaUpdate';
  if (content.hasContactUpdate()) return 'contactUpdate';
  if (content.hasContactRequest()) return 'contactRequest';
  if (content.hasFlameSync()) return 'flameSync';
  if (content.hasPushKeys()) return 'pushKeys';
  if (content.hasReaction()) return 'reaction';
  if (content.hasTextMessage()) return 'textMessage';
  if (content.hasGroupCreate()) return 'groupCreate';
  if (content.hasGroupJoin()) return 'groupJoin';
  if (content.hasGroupUpdate()) return 'groupUpdate';
  if (content.hasResendGroupPublicKey()) return 'resendGroupPublicKey';
  if (content.hasErrorMessages()) return 'errorMessages';
  if (content.hasAdditionalDataMessage()) return 'additionalDataMessage';
  if (content.hasTypingIndicator()) return 'typingIndicator';
  if (content.hasUserDiscoveryRequest()) return 'userDiscoveryRequest';
  if (content.hasUserDiscoveryUpdate()) return 'userDiscoveryUpdate';
  if (content.hasKeyVerificationProof()) return 'keyVerificationProof';
  return 'unknown';
}
