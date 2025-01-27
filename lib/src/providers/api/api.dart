import 'dart:io';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
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
  print("check if free network connection");

  print("Downloading: " + imageToken.toString());
}
