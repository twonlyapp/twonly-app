import 'dart:convert';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/proto/api/client_to_server.pb.dart' as client;
import 'package:twonly/src/proto/api/client_to_server.pbserver.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

Future handleServerMessage(server.ServerToClient msg) async {
  client.Response? response;

  if (msg.v0.hasRequestNewPreKeys()) {
    List<PreKeyRecord> localPreKeys = await SignalHelper.getPreKeys();

    List<client.Response_PreKey> prekeysList = [];
    for (int i = 0; i < localPreKeys.length; i++) {
      prekeysList.add(client.Response_PreKey()
        ..id = Int64(localPreKeys[i].id)
        ..prekey = localPreKeys[i].getKeyPair().publicKey.serialize());
    }
    var prekeys = client.Response_Prekeys(prekeys: prekeysList);
    var ok = client.Response_Ok()..prekeys = prekeys;
    response = client.Response()..ok = ok;
  } else if (msg.v0.hasNewMessage()) {
    Uint8List body = Uint8List.fromList(msg.v0.newMessage.body);
    Int64 fromUserId = msg.v0.newMessage.fromUserId;
    Message? message = await SignalHelper.getDecryptedText(fromUserId, body);
    if (message != null) {
      switch (message.kind) {
        case MessageKind.contactRequest:
          Result username = await apiProvider.getUsername(fromUserId);
          if (username.isSuccess) {
            Uint8List name = username.value.userdata.username;
            DbContacts.insertNewContact(
                utf8.decode(name), fromUserId.toInt(), true);
          }
          break;
        case MessageKind.rejectRequest:
          DbContacts.deleteUser(fromUserId.toInt());
          break;
        case MessageKind.acceptRequest:
          DbContacts.acceptUser(fromUserId.toInt());
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
            String content = jsonEncode(message.content!.toJson());
            await DbMessages.insertOtherMessage(
                fromUserId.toInt(), message.kind, message.messageId!, content);

            encryptAndSendMessage(
              fromUserId,
              Message(
                kind: MessageKind.ack,
                messageId: message.messageId!,
                timestamp: DateTime.now(),
              ),
            );

            if (message.kind == MessageKind.video ||
                message.kind == MessageKind.image) {
              dynamic content = message.content!;
              List<int> downloadToken = content.downloadToken;
              tryDownloadMedia(downloadToken);
            }
          }
      }
    }
    var ok = client.Response_Ok()..none = true;
    response = client.Response()..ok = ok;
  } else {
    Logger("handleServerMessage")
        .shout("Got a new message from the server: $msg");
    return;
  }

  var v0 = client.V0()
    ..seq = msg.v0.seq
    ..response = response;

  apiProvider.sendResponse(ClientToServer()..v0 = v0);
}
