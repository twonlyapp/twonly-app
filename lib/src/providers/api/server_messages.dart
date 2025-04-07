import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/json_models/message.dart';
import 'package:twonly/src/proto/api/client_to_server.pb.dart' as client;
import 'package:twonly/src/proto/api/client_to_server.pbserver.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:twonly/src/proto/api/server_to_client.pbserver.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/api/media.dart';
import 'package:twonly/src/providers/hive.dart';
import 'package:twonly/src/services/notification_service.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

bool isBlocked = false;

Future handleServerMessage(server.ServerToClient msg) async {
  client.Response? response;
  int maxCounter = 0; // only block for 2 seconds
  while (isBlocked && maxCounter < 200) {
    await Future.delayed(Duration(milliseconds: 10));
    maxCounter += 1;
  }
  isBlocked = true;

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

  isBlocked = false;

  var v0 = client.V0()
    ..seq = msg.v0.seq
    ..response = response;

  apiProvider.sendResponse(ClientToServer()..v0 = v0);
}

Future<client.Response> handleDownloadData(DownloadData data) async {
  if (globalIsAppInBackground) {
    // download should only be done when the app is open
    return client.Response()..error = ErrorCode.InternalError;
  }

  Logger("server_messages")
      .info("downloading: ${data.downloadToken} ${data.fin}");

  final box = await getMediaStorage();

  String boxId = data.downloadToken.toString();

  int? messageId = box.get("${data.downloadToken}_messageId");

  if (messageId == null) {
    Logger("server_messages")
        .shout("download data received, but unknown messageID");
    // answers with ok, so the server will delete the message
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  if (data.fin && data.data.isEmpty) {
    Logger("server_messages")
        .shout("Got an image message, but was already deleted by the server!");
    // media file was deleted by the server. remove the media from device
    await twonlyDatabase.messagesDao.deleteMessageById(messageId);
    await box.delete(boxId);
    await box.delete("${data.downloadToken}_downloaded");
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  Uint8List? buffered = box.get(boxId);
  Uint8List downloadedBytes;
  if (buffered != null) {
    if (data.offset != buffered.length) {
      Logger("server_messages")
          .info("server send wrong offset: ${data.offset} ${buffered.length}");
      // Logger("handleDownloadData").error(object)
      return client.Response()..error = ErrorCode.InvalidOffset;
    }
    var b = BytesBuilder();
    b.add(buffered);
    b.add(data.data);

    downloadedBytes = b.takeBytes();
  } else {
    downloadedBytes = Uint8List.fromList(data.data);
  }

  if (!data.fin) {
    // download not finished, so waiting for more data...
    await box.put(boxId, downloadedBytes);
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  // Uint8List? rawBytes =
  //     await SignalHelper.decryptBytes(downloadedBytes, fromUserId);

  Message? msg = await twonlyDatabase.messagesDao
      .getMessageByMessageId(messageId)
      .getSingleOrNull();
  if (msg == null) {
    Logger("server_messages")
        .info("messageId not found in database. Ignoring download");
    // answers with ok, so the server will delete the message
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  MediaMessageContent content =
      MediaMessageContent.fromJson(jsonDecode(msg.contentJson!));

  final xchacha20 = Xchacha20.poly1305Aead();
  SecretKeyData secretKeyData = SecretKeyData(content.encryptionKey!);

  SecretBox secretBox = SecretBox(
    downloadedBytes,
    nonce: content.encryptionNonce!,
    mac: Mac(content.encryptionMac!),
  );

  try {
    final rawBytes =
        await xchacha20.decrypt(secretBox, secretKey: secretKeyData);

    await box.put("${data.downloadToken}_downloaded", rawBytes);
  } catch (e) {
    Logger("server_messages").info("Decryption error: $e");
    // deleting message as this is an invalid image
    await twonlyDatabase.messagesDao.deleteMessageById(messageId);
    // answers with ok, so the server will delete the message
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  Logger("server_messages").info("Downloaded: $messageId");
  await twonlyDatabase.messagesDao.updateMessageByOtherUser(
    msg.contactId,
    messageId,
    MessagesCompanion(downloadState: Value(DownloadState.downloaded)),
  );

  await box.delete(boxId);

  var ok = client.Response_Ok()..none = true;
  return client.Response()..ok = ok;
}

Future<client.Response> handleNewMessage(int fromUserId, Uint8List body) async {
  MessageJson? message = await SignalHelper.getDecryptedText(fromUserId, body);
  if (message == null) {
    Logger("server_messages")
        .info("Got invalid cypher text from $fromUserId. Deleting it.");
    // Message is not valid, so server can delete it
    var ok = client.Response_Ok()..none = true;
    return client.Response()..ok = ok;
  }

  switch (message.kind) {
    case MessageKind.contactRequest:
      return handleContactRequest(fromUserId, message);

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
      final update = MessagesCompanion(acknowledgeByUser: Value(true));
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
          message.kind != MessageKind.storedMediaFile) {
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

        String content = jsonEncode(message.content!.toJson());

        bool acknowledgeByUser = false;
        DateTime? openedAt;

        if (message.kind == MessageKind.storedMediaFile) {
          acknowledgeByUser = true;
          openedAt = DateTime.now();
        }

        int? responseToMessageId;
        final textContent = message.content!;
        if (textContent is TextMessageContent) {
          responseToMessageId = textContent.responseToMessageId;
        }

        final update = MessagesCompanion(
          contactId: Value(fromUserId),
          kind: Value(message.kind),
          messageOtherId: Value(message.messageId),
          contentJson: Value(content),
          acknowledgeByServer: Value(true),
          acknowledgeByUser: Value(acknowledgeByUser),
          responseToMessageId: Value(responseToMessageId),
          openedAt: Value(openedAt),
          downloadState: Value(message.kind == MessageKind.media
              ? DownloadState.pending
              : DownloadState.downloaded),
          sendAt: Value(message.timestamp),
        );

        final messageId = await twonlyDatabase.messagesDao.insertMessage(
          update,
        );

        if (messageId == null) {
          return client.Response()..error = ErrorCode.InternalError;
        }

        encryptAndSendMessage(
          message.messageId!,
          fromUserId,
          MessageJson(
            kind: MessageKind.ack,
            messageId: message.messageId!,
            content: MessageContent(),
            timestamp: DateTime.now(),
          ),
        );

        if (message.kind == MessageKind.media) {
          twonlyDatabase.contactsDao.incFlameCounter(
            fromUserId,
            true,
            message.timestamp,
          );

          if (!globalIsAppInBackground) {
            final content = message.content;
            if (content is MediaMessageContent) {
              tryDownloadMedia(
                messageId,
                fromUserId,
                content,
              );
            }
          }
        }
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
