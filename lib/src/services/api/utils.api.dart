import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart'
    hide Message;
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/secure_storage.dart';

class Result<T, E> {
  Result.error(this.error) : value = null;
  Result.success(this.value) : error = null;

  final T? value;
  final E? error;

  bool get isSuccess => value != null;
  bool get isError => error != null;
}

DateTime fromTimestamp(Int64 timeStamp) {
  return DateTime.fromMillisecondsSinceEpoch(timeStamp.toInt());
}

// ignore: strict_raw_type
Result asResult(server.ServerToClient? msg) {
  if (msg == null) {
    return Result.error(ErrorCode.InternalError);
  }
  if (msg.v0.response.hasOk()) {
    return Result.success(msg.v0.response.ok);
  } else {
    return Result.error(msg.v0.response.error);
  }
}

ClientToServer createClientToServerFromHandshake(Handshake handshake) {
  final v0 = client.V0()
    ..seq = Int64()
    ..handshake = handshake;
  return ClientToServer()..v0 = v0;
}

ClientToServer createClientToServerFromApplicationData(
  ApplicationData applicationData,
) {
  final v0 = client.V0()
    ..seq = Int64()
    ..applicationdata = applicationData;
  return ClientToServer()..v0 = v0;
}

Future<void> handleMediaError(MediaFile media) async {
  await twonlyDB.mediaFilesDao.updateMedia(
    media.mediaId,
    const MediaFilesCompanion(
      downloadState: Value(DownloadState.reuploadRequested),
    ),
  );
  final messages = await twonlyDB.messagesDao.getMessagesByMediaId(
    media.mediaId,
  );
  if (messages.length != 1) return;
  final message = messages.first;
  if (message.senderId == null) return;
  await sendCipherText(
    message.senderId!,
    EncryptedContent(
      mediaUpdate: EncryptedContent_MediaUpdate(
        type: EncryptedContent_MediaUpdate_Type.DECRYPTION_ERROR,
        targetMessageId: message.messageId,
      ),
    ),
  );
}

Future<bool> importSignalContactAndCreateRequest(
  server.Response_UserData userdata,
) async {
  if (!await processSignalUserData(userdata)) {
    return false;
  }

  // 1. Setup notifications keys with the other user
  await setupNotificationWithUsers(
    forceContact: userdata.userId.toInt(),
  );

  // 2. Then send user request
  await sendCipherText(
    userdata.userId.toInt(),
    EncryptedContent(
      contactRequest: EncryptedContent_ContactRequest(
        type: EncryptedContent_ContactRequest_Type.REQUEST,
      ),
    ),
  );

  return true;
}

Future<Map<String, String>?> getAuthenticationHeader() async {
  var headers = <String, String>{};

  if (userService.currentUser.canUseLoginTokenForAuth) {
    final loginToken = await FlutterKeyManager.getLoginToken();

    headers = {
      'x-twonly-user-id': userService.currentUser.userId
          .toRadixString(16)
          .padLeft(16, '0')
          .toUpperCase(),
      'x-twonly-login-token': uint8ListToHex(loginToken),
    };
  } else {
    final apiAuthTokenRaw = await SecureStorage.instance.read(
      key: SecureStorageKeys.apiAuthToken,
    );

    if (apiAuthTokenRaw == null) {
      Log.error('api auth token not defined.');
      return null;
    }

    final apiAuthToken = uint8ListToHex(base64Decode(apiAuthTokenRaw));

    headers = {
      'x-twonly-auth-token': apiAuthToken,
    };
  }

  return headers;
}
