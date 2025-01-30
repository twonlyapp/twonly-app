import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/utils/misc.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

// this functions ensures that the message is received by the server and in case of errors will try again later
Future<Result> encryptAndSendMessage(Int64 userId, Message msg) async {
  Uint8List? bytes = await SignalHelper.encryptMessage(msg, userId);

  if (bytes == null) {
    Logger("api.dart").shout("Error encryption message!");
    return Result.error(ErrorCode.InternalError);
  }

  Logger("api.dart").shout(
      "TODO: store encrypted message and send later again. STORE: userId, bytes and messageId");

  Result resp = await apiProvider.sendTextMessage(userId, bytes);

  if (resp.isSuccess) {
    if (msg.messageId != null) {
      DbMessages.acknowledgeMessageByServer(msg.messageId!);
    }
    // TODO: remove encrypted tmp file
  } else {
    // in case of error do nothing. As the message is not removed the app will try again when relaunched
  }

  return resp;
}

Future sendTextMessage(Int64 target, String message) async {
  MessageContent content = MessageContent(text: message, downloadToken: null);

  int? messageId = await DbMessages.insertMyMessage(
      target.toInt(), MessageKind.textMessage,
      jsonContent: jsonEncode(content.toJson()));
  if (messageId == null) return;

  Message msg = Message(
    kind: MessageKind.textMessage,
    messageId: messageId,
    content: content,
    timestamp: DateTime.now(),
  );

  await encryptAndSendMessage(target, msg);
}

Future sendImageToSingleTarget(Int64 target, Uint8List imageBytes) async {
  int? messageId =
      await DbMessages.insertMyMessage(target.toInt(), MessageKind.image);
  if (messageId == null) return;

  Result res = await apiProvider.getUploadToken();

  if (res.isError || !res.value.hasUploadtoken()) {
    Logger("api.dart").shout("Error getting upload token!");

    // TODO store message for later and try again

    return null;
  }

  List<int> uploadToken = res.value.uploadtoken;
  Logger("sendImageToSingleTarget").fine("Got token: $uploadToken");

  MessageContent content =
      MessageContent(text: null, downloadToken: uploadToken);

  Uint8List? encryptBytes = await SignalHelper.encryptBytes(imageBytes, target);
  if (encryptBytes == null) {
    await DbMessages.deleteMessageById(messageId);
    Logger("api.dart").shout("Error encrypting image! Deleting image.");
    return;
  }

  List<int>? imageToken =
      await apiProvider.uploadData(uploadToken, encryptBytes);
  if (imageToken == null) {
    Logger("api.dart").shout("handle error uploading like saving...");
    return;
  }

  print("TODO: insert into DB and then create this MESSAGE");

  Message msg = Message(
    kind: MessageKind.image,
    messageId: messageId,
    content: content,
    timestamp: DateTime.now(),
  );

  await encryptAndSendMessage(target, msg);
}

Future sendImage(List<Int64> userIds, String imagePath) async {
  // 1. set notifier provider

  File imageFile = File(imagePath);

  Uint8List? imageBytes = await getCompressedImage(imageFile);
  if (imageBytes == null) {
    Logger("api.dart").shout("Error compressing image!");
    return;
  }

  for (int i = 0; i < userIds.length; i++) {
    sendImageToSingleTarget(userIds[i], imageBytes);
  }
}

Future tryDownloadMedia(List<int> imageToken, {bool force = false}) async {
  if (!force) {
    // TODO: create option to enable download via mobile data
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      Logger("tryDownloadMedia").info("abort download over mobile connection");
      return;
    }
  }
  Logger("tryDownloadMedia").info("Downloading: $imageToken");
  apiProvider.triggerDownload(imageToken);
}

Future userOpenedMessage(int fromUserId, int messageId) async {
  await DbMessages.userOpenedMessage(messageId);

  encryptAndSendMessage(
    Int64(fromUserId),
    Message(
      kind: MessageKind.opened,
      messageId: messageId,
      timestamp: DateTime.now(),
    ),
  );
}

Future<Uint8List?> getDownloadedMedia(
    List<int> mediaToken, int messageId) async {
  final box = await getMediaStorage();
  Uint8List? media = box.get("${mediaToken}_downloaded");
  int fromUserId = box.get("${mediaToken}_fromUserId");
  await userOpenedMessage(fromUserId, messageId);
  box.delete(mediaToken.toString());
  box.put("${mediaToken}_downloaded", "deleted");
  box.delete("${mediaToken}_fromUserId");
  return media;
}

Future<bool> isMediaDownloaded(List<int> mediaToken) async {
  final box = await getMediaStorage();
  return box.containsKey("${mediaToken}_downloaded");
}

Future initMediaStorage() async {
  final storage = getSecureStorage();
  var containsEncryptionKey =
      await storage.containsKey(key: 'hive_encryption_key');
  if (!containsEncryptionKey) {
    var key = Hive.generateSecureKey();
    await storage.write(
      key: 'hive_encryption_key',
      value: base64UrlEncode(key),
    );
  }
  final dir = await getApplicationDocumentsDirectory();
  Hive.init(dir.path);
}

Future<Box> getMediaStorage() async {
  await initMediaStorage();

  final storage = getSecureStorage();
  var encryptionKey =
      base64Url.decode((await storage.read(key: 'hive_encryption_key'))!);

  return await Hive.openBox('media_storage',
      encryptionCipher: HiveAesCipher(encryptionKey));
}
