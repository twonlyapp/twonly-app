import 'dart:convert';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
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
      Int64 fromUserId = msg.v0.newMessage.fromUserId;
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
  debugPrint("Downloading: ${data.uploadToken} ${data.fin}");
  final box = await getMediaStorage();

  String boxId = data.uploadToken.toString();
  if (data.fin && data.data.isEmpty) {
    // media file was deleted by the server. remove the media from device

    int? messageId = box.get("${data.uploadToken}_messageId");
    if (messageId != null) {
      int? fromUserId = await DbMessages.deleteMessageById(messageId);
      box.delete(boxId);
      // int? fromUserId = box.get("${data.uploadToken}_fromUserId");
      if (fromUserId != null) {
        globalCallBackOnMessageChange(fromUserId);
      }
      box.delete("${data.uploadToken}_fromUserId");
      box.delete("${data.uploadToken}_downloaded");
      globalCallBackOnDownloadChange(data.uploadToken, false);
      var ok = client.Response_Ok()..none = true;
      return client.Response()..ok = ok;
    } else {
      globalCallBackOnDownloadChange(data.uploadToken, false);
      var ok = client.Response_Ok()..none = true;
      return client.Response()..ok = ok;
    }
  }

  Uint8List? buffered = box.get(boxId);
  Uint8List downloadedBytes;
  if (buffered != null) {
    if (data.offset != buffered.length) {
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
          await SignalHelper.decryptBytes(downloadedBytes, Int64(fromUserId));

      if (rawBytes != null) {
        box.put("${data.uploadToken}_downloaded", rawBytes);
      }

      box.delete(boxId);
      await globalCallBackOnMessageChange(fromUserId);
      globalCallBackOnDownloadChange(data.uploadToken, false);
    }
  } else {
    box.put(boxId, downloadedBytes);
  }

  var ok = client.Response_Ok()..none = true;
  return client.Response()..ok = ok;
}

Future<client.Response> handleNewMessage(
    Int64 fromUserId, Uint8List body) async {
  Message? message = await SignalHelper.getDecryptedText(fromUserId, body);
  if (message != null) {
    switch (message.kind) {
      case MessageKind.contactRequest:
        Result username = await apiProvider.getUsername(fromUserId);
        if (username.isSuccess) {
          Uint8List name = username.value.userdata.username;
          DbContacts.insertNewContact(
              utf8.decode(name), fromUserId.toInt(), true);
          localPushNotificationNewMessage(fromUserId.toInt(), message, 999999);
        }
        break;
      case MessageKind.opened:
        await DbMessages.otherUserOpenedMyMessage(
          fromUserId.toInt(),
          message.messageId!,
          message.timestamp,
        );
        break;
      case MessageKind.rejectRequest:
        DbContacts.deleteUser(fromUserId.toInt());
        break;
      case MessageKind.acceptRequest:
        DbContacts.acceptUser(fromUserId.toInt());
        localPushNotificationNewMessage(fromUserId.toInt(), message, 8888888);
        break;
      case MessageKind.ack:
        DbMessages.acknowledgeMessageByUser(
            fromUserId.toInt(), message.messageId!);
        break;
      default:
        if (message.kind != MessageKind.textMessage &&
            message.kind != MessageKind.video &&
            message.kind != MessageKind.image) {
          Logger("handleServerMessages")
              .shout("Got unknown MessageKind $message");
        } else {
          String content = jsonEncode(message.content.toJson());
          int? messageId = await DbMessages.insertOtherMessage(
              fromUserId.toInt(),
              message.kind,
              message.messageId!,
              content,
              message.timestamp);

          if (messageId == null) {
            return client.Response()..error = ErrorCode.InternalError;
          }

          encryptAndSendMessage(
            fromUserId,
            Message(
              kind: MessageKind.ack,
              messageId: message.messageId!,
              content: MessageContent(),
              timestamp: DateTime.now(),
            ),
          );

          if (message.kind == MessageKind.video ||
              message.kind == MessageKind.image) {
            await DbContacts.checkAndUpdateFlames(fromUserId.toInt(),
                timestamp: message.timestamp);

            final content = message.content;
            if (content is MediaMessageContent) {
              List<int> downloadToken = content.downloadToken;
              Box box = await getMediaStorage();
              box.put("${downloadToken}_fromUserId", fromUserId.toInt());
              if (box.get("${downloadToken}_fromUserId") == null) {
                debugPrint("BOX IS NOT WORKING");
              }
              tryDownloadMedia(messageId, downloadToken);
            }
          }
          localPushNotificationNewMessage(
              fromUserId.toInt(), message, messageId);
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
