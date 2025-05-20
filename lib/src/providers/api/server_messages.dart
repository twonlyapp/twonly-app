import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/client_to_server.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/api/media_received.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

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
      } else if (msg.v0.hasDownloaddata()) {
        response = await handleDownloadData(msg.v0.downloaddata);
      } else {
        Logger("handleServerMessage")
            .shout("Got a new message from the server: $msg");
        response = client.Response()..error = ErrorCode.InternalError;
      }
    } catch (e) {
      response = client.Response()..error = ErrorCode.InternalError;
    }

    var v0 = client.V0()
      ..seq = msg.v0.seq
      ..response = response;

    apiProvider.sendResponse(ClientToServer()..v0 = v0);
  });
}

Future<client.Response> handleNewMessage(int fromUserId, Uint8List body) async {
  MessageJson? message = await SignalHelper.getDecryptedText(fromUserId, body);
  if (message == null) {
    Logger("server_messages")
        .info("Got invalid cipher text from $fromUserId. Deleting it.");
    // Message is not valid, so server can delete it
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  switch (message.kind) {
    case MessageKind.contactRequest:
      return handleContactRequest(fromUserId, message);

    case MessageKind.flameSync:
      Contact? contact = await twonlyDatabase.contactsDao
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
          await twonlyDatabase.contactsDao.updateContact(fromUserId, updates);
        }
      }

    case MessageKind.opened:
      final update = MessagesCompanion(openedAt: Value(message.timestamp));
      await twonlyDatabase.messagesDao.updateMessageByOtherUser(
        fromUserId,
        message.messageId!,
        update,
      );
      final openedMessage = await twonlyDatabase.messagesDao
          .getMessageByMessageId(message.messageId!)
          .getSingleOrNull();
      if (openedMessage != null &&
          openedMessage.kind == MessageKind.textMessage) {
        await twonlyDatabase.messagesDao.openedAllNonMediaMessagesFromOtherUser(
          fromUserId,
        );
      }

      break;

    case MessageKind.rejectRequest:
      await twonlyDatabase.contactsDao.deleteContactByUserId(fromUserId);
      break;

    case MessageKind.acceptRequest:
      final update = ContactsCompanion(accepted: Value(true));
      await twonlyDatabase.contactsDao.updateContact(fromUserId, update);
      notifyContactsAboutProfileChange();
      break;

    case MessageKind.profileChange:
      var content = message.content;
      if (content is ProfileContent) {
        final update = ContactsCompanion(
          avatarSvg: Value(content.avatarSvg),
          displayName: Value(content.displayName),
        );
        twonlyDatabase.contactsDao.updateContact(fromUserId, update);
      }
      break;

    case MessageKind.ack:
      final update = MessagesCompanion(
        acknowledgeByUser: Value(true),
        errorWhileSending: Value(false),
      );
      await twonlyDatabase.messagesDao.updateMessageByOtherUser(
        fromUserId,
        message.messageId!,
        update,
      );
      break;

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
        Logger("handleServerMessages")
            .shout("Got unknown MessageKind $message");
      } else if (message.content == null || message.messageId == null) {
        Logger("handleServerMessages")
            .shout("Content or messageid not defined $message");
      } else {
        // when a message is received doubled ignore it...
        if ((await twonlyDatabase.messagesDao
            .containsOtherMessageId(fromUserId, message.messageId!))) {
          var ok = client.Response_Ok()..none = true;
          return client.Response()..ok = ok;
        }

        bool acknowledgeByUser = false;
        DateTime? openedAt;

        if (message.kind == MessageKind.storedMediaFile ||
            message.kind == MessageKind.reopenedMedia) {
          acknowledgeByUser = true;
          openedAt = DateTime.now();
        }

        int? responseToMessageId;
        int? responseToOtherMessageId;
        int? messageId;

        final content = message.content!;
        if (content is TextMessageContent) {
          responseToMessageId = content.responseToMessageId;
          responseToOtherMessageId = content.responseToOtherMessageId;
        }
        if (content is ReopenedMediaFileContent) {
          responseToMessageId = content.messageId;
        }
        if (content is StoredMediaFileContent) {
          responseToMessageId = content.messageId;
          await twonlyDatabase.messagesDao.updateMessageByOtherUser(
            fromUserId,
            content.messageId,
            MessagesCompanion(
              mediaStored: Value(true),
            ),
          );
        } else {
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

          messageId = await twonlyDatabase.messagesDao.insertMessage(
            update,
          );

          if (messageId == null) {
            return client.Response()..error = ErrorCode.InternalError;
          }
        }

        await encryptAndSendMessageAsync(
          message.messageId!,
          fromUserId,
          MessageJson(
            kind: MessageKind.ack,
            messageId: message.messageId!,
            content: MessageContent(),
            timestamp: DateTime.now(),
          ),
        );

        if (message.kind == MessageKind.media && messageId != null) {
          twonlyDatabase.contactsDao.incFlameCounter(
            fromUserId,
            true,
            message.timestamp,
          );

          final msg = await twonlyDatabase.messagesDao
              .getMessageByMessageId(messageId)
              .getSingleOrNull();
          if (msg != null) {
            startDownloadMedia(msg, false);
          }
        }
        // dearchive contact when receiving a new message
        await twonlyDatabase.contactsDao.updateContact(
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
  List<PreKeyRecord> localPreKeys = await SignalHelper.getPreKeys();

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
  Result username = await apiProvider.getUsername(fromUserId);
  if (username.isSuccess) {
    Uint8List name = username.value.userdata.username;
    await twonlyDatabase.contactsDao.insertContact(
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
