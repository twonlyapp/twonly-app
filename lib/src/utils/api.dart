import 'dart:convert';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/providers/api_provider.dart';
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

  return resp;
}

Future<Result> rejectUserRequest(Int64 userId) async {
  Message msg =
      Message(kind: MessageKind.rejectRequest, timestamp: DateTime.now());
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
