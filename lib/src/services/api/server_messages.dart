import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/api/media_download.dart';
import 'package:twonly/src/services/notification.service.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/prekeys.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

final lockHandleServerMessage = Mutex();

Future handleServerMessage(server.ServerToClient msg) async {
  return lockHandleServerMessage.protect(() async {
    client.Response? response;

    try {
      if (msg.v0.hasRequestNewPreKeys()) {
        response = await handleRequestNewPreKey();
      } else if (msg.v0.hasNewMessage()) {
        Uint8List body = Uint8List.fromList(msg.v0.newMessage.body);
        int fromUserId = msg.v0.newMessage.fromUserId.toInt();
        response = await handleNewMessage(fromUserId, body);
      } else {
        Log.error("Got a new message from the server: $msg");
        response = client.Response()..error = ErrorCode.InternalError;
      }
    } catch (e) {
      response = client.Response()..error = ErrorCode.InternalError;
    }

    var v0 = client.V0()
      ..seq = msg.v0.seq
      ..response = response;

    apiService.sendResponse(ClientToServer()..v0 = v0);
  });
}

DateTime lastSignalDecryptMessage = DateTime.now().subtract(Duration(hours: 1));
DateTime lastPushKeyRequest = DateTime.now().subtract(Duration(hours: 1));

Future<client.Response> handleNewMessage(int fromUserId, Uint8List body) async {
  MessageJson? message = await signalDecryptMessage(fromUserId, body);
  if (message == null) {
    await encryptAndSendMessageAsync(
      null,
      fromUserId,
      MessageJson(
        kind: MessageKind.signalDecryptError,
        content: MessageContent(),
        timestamp: DateTime.now(),
      ),
    );

    Log.error("Could not decrypt others message!");

    // Message is not valid, so server can delete it
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  Log.info("Got: ${message.kind}");

  if (message.kind != MessageKind.ack && message.retransId != null) {
    Log.info("Sending ACK for ${message.kind}");

    /// ACK every message
    await encryptAndSendMessageAsync(
      null,
      fromUserId,
      MessageJson(
        kind: MessageKind.ack,
        messageId: null,
        content: AckContent(
            messageIdToAck: message.messageId,
            retransIdToAck: message.retransId!),
        timestamp: DateTime.now(),
      ),
      willNotGetACKByUser: true,
    );
  }

  switch (message.kind) {
    case MessageKind.ack:
      final content = message.content;
      if (content is AckContent) {
        if (content.messageIdToAck != null) {
          final update = MessagesCompanion(
            acknowledgeByUser: Value(true),
            errorWhileSending: Value(false),
          );
          await twonlyDB.messagesDao.updateMessageByOtherUser(
            fromUserId,
            content.messageIdToAck!,
            update,
          );
        }

        await twonlyDB.messageRetransmissionDao
            .deleteRetransmissionById(content.retransIdToAck);
      }
      break;
    case MessageKind.signalDecryptError:
      if (lastSignalDecryptMessage
          .isBefore(DateTime.now().subtract(Duration(seconds: 60)))) {
        Log.error(
            "Got signal decrypt error from other user! Sending all non ACK messages again.");
        lastSignalDecryptMessage = DateTime.now();
        await twonlyDB.signalDao.deleteAllPreKeysByContactId(fromUserId);
        await requestNewPrekeysForContact(fromUserId);
        await twonlyDB.messageRetransmissionDao.resetAckStatusForAllMessages();
        tryTransmitMessages();
      }

      break;
    case MessageKind.contactRequest:
      return handleContactRequest(fromUserId, message);

    case MessageKind.flameSync:
      Contact? contact = await twonlyDB.contactsDao
          .getContactByUserId(fromUserId)
          .getSingleOrNull();
      if (contact != null && contact.lastFlameCounterChange != null) {
        final content = message.content;
        if (content is FlameSyncContent) {
          var updates = ContactsCompanion(
            alsoBestFriend: Value(content.bestFriend),
          );
          if (isToday(contact.lastFlameCounterChange!) &&
              isToday(content.lastFlameCounterChange)) {
            if (content.flameCounter > contact.flameCounter) {
              updates = ContactsCompanion(
                alsoBestFriend: Value(content.bestFriend),
                flameCounter: Value(content.flameCounter),
              );
            }
          }
          await twonlyDB.contactsDao.updateContact(fromUserId, updates);
        }
      }

    case MessageKind.receiveMediaError:
      if (message.messageId != null) {
        await twonlyDB.messagesDao.updateMessageByOtherUser(
          fromUserId,
          message.messageId!,
          MessagesCompanion(
            errorWhileSending: Value(true),
          ),
        );
      }

    case MessageKind.opened:
      if (message.messageId != null) {
        final update = MessagesCompanion(
          openedAt: Value(message.timestamp),
          errorWhileSending: Value(false),
        );
        await twonlyDB.messagesDao.updateMessageByOtherUser(
          fromUserId,
          message.messageId!,
          update,
        );
        final openedMessage = await twonlyDB.messagesDao
            .getMessageByMessageId(message.messageId!)
            .getSingleOrNull();
        if (openedMessage != null &&
            openedMessage.kind == MessageKind.textMessage) {
          await twonlyDB.messagesDao.openedAllNonMediaMessagesFromOtherUser(
            fromUserId,
          );
        }
      }
      break;

    case MessageKind.rejectRequest:
      await deleteContact(fromUserId);
      break;

    case MessageKind.acceptRequest:
      final update = ContactsCompanion(accepted: Value(true));
      await twonlyDB.contactsDao.updateContact(fromUserId, update);
      notifyContactsAboutProfileChange();
      break;

    case MessageKind.profileChange:
      var content = message.content;
      if (content is ProfileContent) {
        final update = ContactsCompanion(
          avatarSvg: Value(content.avatarSvg),
          displayName: Value(content.displayName),
        );
        await twonlyDB.contactsDao.updateContact(fromUserId, update);
      }
      createPushAvatars();
      break;

    case MessageKind.requestPushKey:
      if (lastPushKeyRequest
          .isBefore(DateTime.now().subtract(Duration(seconds: 60)))) {
        lastPushKeyRequest = DateTime.now();
        setupNotificationWithUsers(force: true);
      }

    case MessageKind.pushKey:
      if (message.content != null) {
        final pushKey = message.content!;
        if (pushKey is PushKeyContent) {
          await handleNewPushKey(fromUserId, pushKey);
        }
      }

    default:
      if (message.kind != MessageKind.textMessage &&
          message.kind != MessageKind.media &&
          message.kind != MessageKind.storedMediaFile &&
          message.kind != MessageKind.reopenedMedia) {
        Log.error("Got unknown MessageKind $message");
      } else if (message.content == null || message.messageId == null) {
        Log.error("Content or messageid not defined $message");
      } else {
        final content = message.content!;

        if (content is StoredMediaFileContent) {
          /// stored media file just updates the message
          await twonlyDB.messagesDao.updateMessageByOtherUser(
            fromUserId,
            content.messageId,
            MessagesCompanion(
              mediaStored: Value(true),
              errorWhileSending: Value(false),
            ),
          );
        } else {
          // when a message is received doubled ignore it...
          if ((await twonlyDB.messagesDao
              .containsOtherMessageId(fromUserId, message.messageId!))) {
            Log.error(
                "Got a duplicated message from other user: ${message.messageId!}");
            var ok = client.Response_Ok()..none = true;
            return client.Response()..ok = ok;
          }

          int? responseToMessageId;
          int? responseToOtherMessageId;
          int? messageId;

          bool acknowledgeByUser = false;
          DateTime? openedAt;

          if (message.kind == MessageKind.reopenedMedia) {
            acknowledgeByUser = true;
            openedAt = DateTime.now();
          }

          if (content is TextMessageContent) {
            responseToMessageId = content.responseToMessageId;
            responseToOtherMessageId = content.responseToOtherMessageId;
          }
          if (content is ReopenedMediaFileContent) {
            responseToMessageId = content.messageId;
          }

          if (responseToMessageId != null) {
            await twonlyDB.messagesDao.updateMessageByOtherUser(
              fromUserId,
              responseToMessageId,
              MessagesCompanion(
                errorWhileSending: Value(false),
                openedAt: Value(
                  DateTime.now(),
                ), // when a user reacted to the media file, it should be marked as opened
              ),
            );
          }

          String contentJson = jsonEncode(content.toJson());
          final update = MessagesCompanion(
            contactId: Value(fromUserId),
            kind: Value(message.kind),
            messageOtherId: Value(message.messageId),
            contentJson: Value(contentJson),
            acknowledgeByServer: Value(true),
            acknowledgeByUser: Value(acknowledgeByUser),
            responseToMessageId: Value(responseToMessageId),
            responseToOtherMessageId: Value(responseToOtherMessageId),
            openedAt: Value(openedAt),
            downloadState: Value(message.kind == MessageKind.media
                ? DownloadState.pending
                : DownloadState.downloaded),
            sendAt: Value(message.timestamp),
          );

          messageId = await twonlyDB.messagesDao.insertMessage(
            update,
          );

          if (messageId == null) {
            return client.Response()..error = ErrorCode.InternalError;
          }

          if (message.kind == MessageKind.media) {
            twonlyDB.contactsDao.incFlameCounter(
              fromUserId,
              true,
              message.timestamp,
            );

            final msg = await twonlyDB.messagesDao
                .getMessageByMessageId(messageId)
                .getSingleOrNull();
            if (msg != null) {
              startDownloadMedia(msg, false);
            }
          }
        }

        // unarchive contact when receiving a new message
        await twonlyDB.contactsDao.updateContact(
          fromUserId,
          ContactsCompanion(
            archived: Value(false),
          ),
        );
      }
  }
  var ok = client.Response_Ok()..none = true;
  return client.Response()..ok = ok;
}

Future<client.Response> handleRequestNewPreKey() async {
  List<PreKeyRecord> localPreKeys = await signalGetPreKeys();

  List<client.Response_PreKey> prekeysList = [];
  for (int i = 0; i < localPreKeys.length; i++) {
    prekeysList.add(client.Response_PreKey()
      ..id = Int64(localPreKeys[i].id)
      ..prekey = localPreKeys[i].getKeyPair().publicKey.serialize());
  }
  var prekeys = client.Response_Prekeys(prekeys: prekeysList);
  var ok = client.Response_Ok()..prekeys = prekeys;
  return client.Response()..ok = ok;
}

Future<client.Response> handleContactRequest(
    int fromUserId, MessageJson message) async {
  // request the username by the server so an attacker can not
  // forge the displayed username in the contact request
  Result username = await apiService.getUsername(fromUserId);
  if (username.isSuccess) {
    Uint8List name = username.value.userdata.username;
    await twonlyDB.contactsDao.insertContact(
      ContactsCompanion(
        username: Value(utf8.decode(name)),
        userId: Value(fromUserId),
        requested: Value(true),
      ),
    );
  }
  await setupNotificationWithUsers();
  var ok = client.Response_Ok()..none = true;
  return client.Response()..ok = ok;
}
