import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/database/database.dart';
import 'package:twonly/src/database/messages_db.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/proto/api/client_to_server.pb.dart' as client;
import 'package:twonly/src/proto/api/client_to_server.pbserver.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:twonly/src/proto/api/server_to_client.pbserver.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/services/notification_service.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

Future handleServerMessage(server.ServerToClient msg) async {
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
      return;
    }
  } catch (e) {
    response = client.Response()..error = ErrorCode.InternalError;
  }

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
      .info("downloading: ${data.uploadToken} ${data.fin}");
  final box = await getMediaStorage();

  String boxId = data.uploadToken.toString();
  int? messageId = box.get("${data.uploadToken}_messageId");
  if (data.fin && data.data.isEmpty) {
    // media file was deleted by the server. remove the media from device

    if (messageId != null) {
      await twonlyDatabase.deleteMessageById(messageId);
      box.delete(boxId);
      box.delete("${data.uploadToken}_fromUserId");
      box.delete("${data.uploadToken}_downloaded");
      var ok = client.Response_Ok()..none = true;
      return client.Response()..ok = ok;
    } else {
      var ok = client.Response_Ok()..none = true;
      return client.Response()..ok = ok;
    }
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

  if (data.fin) {
    SignalHelper.getSignalStore();
    int? fromUserId = box.get("${data.uploadToken}_fromUserId");
    if (fromUserId != null) {
      Uint8List? rawBytes =
          await SignalHelper.decryptBytes(downloadedBytes, fromUserId);

      if (rawBytes != null) {
        box.put("${data.uploadToken}_downloaded", rawBytes);
      } else {
        Logger("server_messages")
            .shout("error decrypting the message: ${data.uploadToken}");
      }

      final update =
          MessagesCompanion(downloadState: Value(DownloadState.downloaded));
      await twonlyDatabase.updateMessageByOtherUser(
        fromUserId,
        messageId!,
        update,
      );

      box.delete(boxId);
    }
  } else {
    box.put(boxId, downloadedBytes);
  }

  var ok = client.Response_Ok()..none = true;
  return client.Response()..ok = ok;
}

Future<client.Response> handleNewMessage(int fromUserId, Uint8List body) async {
  MessageJson? message = await SignalHelper.getDecryptedText(fromUserId, body);
  if (message != null) {
    switch (message.kind) {
      case MessageKind.contactRequest:
        Result username = await apiProvider.getUsername(fromUserId);
        if (username.isSuccess) {
          Uint8List name = username.value.userdata.username;

          int added = await twonlyDatabase.insertContact(ContactsCompanion(
            username: Value(utf8.decode(name)),
            userId: Value(fromUserId),
            requested: Value(true),
          ));
          if (added > 0) {
            localPushNotificationNewMessage(
              fromUserId.toInt(),
              message,
              999999,
            );
          }
        }
        break;
      case MessageKind.opened:
        final update = MessagesCompanion(openedAt: Value(message.timestamp));
        await twonlyDatabase.updateMessageByOtherUser(
          fromUserId,
          message.messageId!,
          update,
        );
        break;
      case MessageKind.rejectRequest:
        await twonlyDatabase.deleteContactByUserId(fromUserId);
        break;
      case MessageKind.acceptRequest:
        final update = ContactsCompanion(accepted: Value(true));
        twonlyDatabase.updateContact(fromUserId, update);
        localPushNotificationNewMessage(fromUserId.toInt(), message, 8888888);
        break;
      case MessageKind.ack:
        final update = MessagesCompanion(acknowledgeByUser: Value(true));
        await twonlyDatabase.updateMessageByOtherUser(
          fromUserId,
          message.messageId!,
          update,
        );
        break;
      default:
        if (message.kind != MessageKind.textMessage &&
            message.kind != MessageKind.media) {
          Logger("handleServerMessages")
              .shout("Got unknown MessageKind $message");
        } else {
          String content = jsonEncode(message.content!.toJson());

          final update = MessagesCompanion(
            contactId: Value(fromUserId),
            kind: Value(message.kind),
            messageOtherId: Value(message.messageId),
            contentJson: Value(content),
            downloadState: Value(DownloadState.downloaded),
            sendAt: Value(message.timestamp),
          );

          final messageId = await twonlyDatabase.insertMessage(
            update,
          );

          if (messageId == null) {
            return client.Response()..error = ErrorCode.InternalError;
          }

          encryptAndSendMessage(
            fromUserId,
            MessageJson(
              kind: MessageKind.ack,
              messageId: message.messageId!,
              content: MessageContent(),
              timestamp: DateTime.now(),
            ),
          );

          if (message.kind == MessageKind.media) {
            twonlyDatabase.updateContact(
              fromUserId,
              ContactsCompanion(
                lastMessageReceived: Value(message.timestamp),
              ),
            );

            twonlyDatabase.incTotalMediaCounter(fromUserId);

            if (!globalIsAppInBackground) {
              final content = message.content;
              if (content is MediaMessageContent) {
                List<int> downloadToken = content.downloadToken;
                tryDownloadMedia(messageId, fromUserId, downloadToken);
              }
            }
          }
          localPushNotificationNewMessage(fromUserId, message, messageId);
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
