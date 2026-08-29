import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart'
    hide Message;
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/secure_storage.dart';

class Result<T, E> {
  Result.error(this.error) : value = null, _isSuccess = false;
  Result.success(this.value) : error = null, _isSuccess = true;

  final T? value;
  final E? error;
  final bool _isSuccess;

  bool get isSuccess => _isSuccess;
  bool get isError => !_isSuccess;
}

DateTime fromTimestamp(Int64 timeStamp) {
  final date = DateTime.fromMillisecondsSinceEpoch(timeStamp.toInt());
  final now = DateTime.now();
  if (date.isAfter(now)) {
    return now;
  }
  return date;
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
  await RustApi.sendEncryptedContent(
    contactId: message.senderId!,
    content: EncryptedContent(
      mediaUpdate: EncryptedContent_MediaUpdate(
        type: EncryptedContent_MediaUpdate_Type.DECRYPTION_ERROR,
        targetMessageId: message.messageId,
      ),
    ).writeToBuffer(),
  );
}

Future<bool> importSignalContactAndCreateRequest(
  FrbUserData userdata,
) async {
  try {
    await RustApi.establishSignalSession(
      contactId: userdata.userId,
      expectedPublicKey: Uint8List.fromList(userdata.publicIdentityKey),
    );

    // 2. Then send user request
    await RustApi.sendEncryptedContent(
      contactId: userdata.userId,
      content: EncryptedContent(
        contactRequest: EncryptedContent_ContactRequest(
          type: EncryptedContent_ContactRequest_Type.REQUEST,
        ),
      ).writeToBuffer(),
    );

    return true;
  } catch (e) {
    Log.error('Failed to establish session and send contact request: $e');
    return false;
  }
}

Future<Map<String, String>?> getAuthenticationHeader() async {
  var headers = <String, String>{};

  if (userService.currentUser.canUseLoginTokenForAuth) {
    final loginToken = await RustKeyManager.getLoginToken();

    headers = {
      'x-twonly-user-id': userService.currentUser.userId
          .toRadixString(16)
          .padLeft(16, '0')
          .toUpperCase(),
      'x-twonly-login-token': uint8ListToHex(loginToken),
    };
  } else {
    final apiAuthTokenRaw = await SecureStorage.instance.read(
      key: 'api_auth_token',
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
