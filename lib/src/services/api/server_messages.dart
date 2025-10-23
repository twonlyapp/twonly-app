import 'dart:async';
import 'package:drift/drift.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart' hide Message;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/server_messages/contact.server_messages.dart';
import 'package:twonly/src/services/api/server_messages/media.server_messages.dart';
import 'package:twonly/src/services/api/server_messages/messages.server_messages.dart';
import 'package:twonly/src/services/api/server_messages/prekeys.server_messages.dart';
import 'package:twonly/src/services/api/server_messages/pushkeys.server_messages.dart';
import 'package:twonly/src/services/api/server_messages/reaction.server_message.dart';
import 'package:twonly/src/services/api/server_messages/text_message.server_messages.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/utils/log.dart';

final lockHandleServerMessage = Mutex();

Future<void> handleServerMessage(server.ServerToClient msg) async {
  /// Returns means, that the server can delete the message from the server.
  final ok = client.Response_Ok()..none = true;
  var response = client.Response()..ok = ok;

  try {
    if (msg.v0.hasRequestNewPreKeys()) {
      response = await handleRequestNewPreKey();
    } else if (msg.v0.hasNewMessage()) {
      final body = Uint8List.fromList(msg.v0.newMessage.body);
      final fromUserId = msg.v0.newMessage.fromUserId.toInt();
      await handleNewMessage(fromUserId, body);
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

DateTime lastPushKeyRequest = DateTime.now().subtract(const Duration(hours: 1));

Future<void> handleNewMessage(int fromUserId, Uint8List body) async {
  final message = Message.fromBuffer(body);
  final receiptId = message.receiptId;

  switch (message.type) {
    case Message_Type.SENDER_DELIVERY_RECEIPT:
      Log.info('Got delivery receipt for $receiptId!');
      await twonlyDB.receiptsDao.confirmReceipt(receiptId, fromUserId);

    case Message_Type.PLAINTEXT_CONTENT:
      if (message.hasPlaintextContent() &&
          message.plaintextContent.hasDecryptionErrorMessage()) {
        Log.info(
          'Got decryption error: ${message.plaintextContent.decryptionErrorMessage.type} for $receiptId',
        );
        await tryToSendCompleteMessage(receiptId: receiptId, reupload: true);
      }

    case Message_Type.CIPHERTEXT:
    case Message_Type.PREKEY_BUNDLE:
      if (message.hasEncryptedContent()) {
        final encryptedContentRaw =
            Uint8List.fromList(message.encryptedContent);

        final responsePlaintextContent = await handleEncryptedMessage(
          fromUserId,
          encryptedContentRaw,
          message.type,
        );
        Message response;
        if (responsePlaintextContent != null) {
          response = Message()
            ..receiptId = receiptId
            ..type = Message_Type.PLAINTEXT_CONTENT
            ..plaintextContent = responsePlaintextContent;
          Log.error('Sending decryption error ($receiptId)');
        } else {
          response = Message()..type = Message_Type.SENDER_DELIVERY_RECEIPT;
        }
        await twonlyDB.receiptsDao.insertReceipt(
          ReceiptsCompanion(
            receiptId: Value(receiptId),
            contactId: Value(fromUserId),
            message: Value(response.writeToBuffer()),
            contactWillSendsReceipt: const Value(false),
          ),
        );
        await tryToSendCompleteMessage(receiptId: receiptId);
      }
    case Message_Type.TEST_NOTIFICATION:
      return;
  }
}

Future<PlaintextContent?> handleEncryptedMessage(
  int fromUserId,
  Uint8List encryptedContentRaw,
  Message_Type messageType,
) async {
  final (content, decryptionErrorType) = await signalDecryptMessage(
    fromUserId,
    encryptedContentRaw,
    messageType as int,
  );

  if (content == null) {
    return PlaintextContent()
      ..decryptionErrorMessage = (PlaintextContent_DecryptionErrorMessage()
        ..type = decryptionErrorType!);
  }

  final senderProfileCounter = await checkForProfileUpdate(fromUserId, content);

  if (content.hasContactRequest()) {
    await handleContactRequest(fromUserId, content.contactRequest);
    return null;
  }

  if (content.hasContactUpdate()) {
    await handleContactUpdate(
      fromUserId,
      content.contactUpdate,
      senderProfileCounter,
    );
    return null;
  }

  if (content.hasFlameSync()) {
    await handleFlameSync(fromUserId, content.flameSync);
    return null;
  }

  if (content.hasPushKeys()) {
    await handlePushKey(fromUserId, content.pushKeys);
    return null;
  }

  if (!content.hasGroupId()) {
    return null;
  }

  /// Verify that the user is (still) in that group...
  if (!await twonlyDB.groupsDao.isContactInGroup(fromUserId, content.groupId)) {
    Log.error('User $fromUserId tried to access group ${content.groupId}.');
    return null;
  }

  if (content.hasMessageUpdate()) {
    await handleMessageUpdate(
      fromUserId,
      content.messageUpdate,
    );
    return null;
  }

  if (content.hasTextMessage()) {
    await handleTextMessage(
      fromUserId,
      content.groupId,
      content.textMessage,
    );
    return null;
  }

  if (content.hasReaction()) {
    await handleReaction(
      fromUserId,
      content.groupId,
      content.reaction,
    );
    return null;
  }

  if (content.hasMedia()) {
    await handleMedia(
      fromUserId,
      content.groupId,
      content.media,
    );
    return null;
  }

  if (content.hasMediaUpdate()) {
    await handleMediaUpdate(
      fromUserId,
      content.groupId,
      content.mediaUpdate,
    );
    return null;
  }

  return null;
}
