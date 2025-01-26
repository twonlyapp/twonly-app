import 'dart:convert';
import 'dart:io';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:twonly/src/providers/notify_provider.dart';
import 'package:twonly/src/utils/misc.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;
import 'package:twonly/src/model/json/user_data.dart';

Future<bool> addNewContact(String username) async {
  final res = await apiProvider.getUserData(username);

  if (res.isSuccess) {
    bool added = await DbContacts.insertNewContact(
        username, res.value.userdata.userId.toInt(), false);

    if (!added) {
      print("RETURN FALSE HIER!!!");
      // return false;
    }

    if (await SignalHelper.addNewContact(res.value.userdata)) {
      Message msg =
          Message(kind: MessageKind.contactRequest, timestamp: DateTime.now());

      Uint8List? bytes =
          await SignalHelper.encryptMessage(msg, res.value.userdata.userId);

      if (bytes == null) {
        Logger("utils/api").shout("Error encryption message!");
        return res.error(ErrorCode.InternalError);
      }

      Result resp =
          await apiProvider.sendTextMessage(res.value.userdata.userId, bytes);

      return resp.isSuccess;
    }
  }
  return res.isSuccess;
}

Future<Result> encryptAndSendMessage(Int64 userId, Message msg) async {
  Uint8List? bytes = await SignalHelper.encryptMessage(msg, userId);

  if (bytes == null) {
    Logger("utils/api").shout("Error encryption message!");
    return Result.error(ErrorCode.InternalError);
  }

  Result resp = await apiProvider.sendTextMessage(userId, bytes);

  Logger("encryptAndSendMessage")
      .shout("handle errors here and store them in the database");

  return resp;
}

Future<Result> rejectUserRequest(Int64 userId) async {
  Message msg =
      Message(kind: MessageKind.rejectRequest, timestamp: DateTime.now());
  return encryptAndSendMessage(userId, msg);
}

Future<Result> acceptUserRequest(Int64 userId) async {
  Message msg =
      Message(kind: MessageKind.acceptRequest, timestamp: DateTime.now());
  return encryptAndSendMessage(userId, msg);
}

Future<Result> createNewUser(String username, String inviteCode) async {
  final storage = getSecureStorage();

  await SignalHelper.createIfNotExistsSignalIdentity();

  final res = await apiProvider.register(username, inviteCode);

  if (res.isSuccess) {
    Logger("create_new_user").info("Got user_id ${res.value} from server");
    final userData = UserData(
        userId: res.value.userid, username: username, displayName: username);
    storage.write(key: "user_data", value: jsonEncode(userData));
  }

  return res;
}

Future sendImage(
    BuildContext context, List<Contact> users, String imagePath) async {
  // 1. set notifier provider

  context.read<NotifyProvider>().addSendingTo(users);

  File imageFile = File(imagePath);

  Uint8List? imageBytes = await getCompressedImage(imageFile);
  if (imageBytes == null) {
    Logger("api.dart").shout("Error compressing image!");
    return;
  }

  for (int i = 0; i < users.length; i++) {
    Int64 target = users[i].userId;
    Uint8List? encryptedImage =
        await SignalHelper.encryptBytes(imageBytes, target);
    if (encryptedImage == null) {
      Logger("api.dart").shout("Error encrypting image!");
      continue;
    }

    List<int>? imageToken = await apiProvider.uploadData(encryptedImage);
    if (imageToken == null) {
      Logger("api.dart").shout("handle error uploading like saving...");
      continue;
    }

    Message msg = Message(
      kind: MessageKind.image,
      content: ImageContent(imageToken),
      timestamp: DateTime.timestamp(),
    );

    print("Send image to $target");
    encryptAndSendMessage(target, msg);
  }
}
