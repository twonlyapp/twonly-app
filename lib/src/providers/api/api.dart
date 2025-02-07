import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/utils/misc.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

Future tryTransmitMessages() async {
  List<DbMessage> retransmit =
      await DbMessages.getAllMessagesForRetransmitting();

  debugPrint("tryTransmitMessages: ${retransmit.length}");

  Box box = await getMediaStorage();
  for (int i = 0; i < retransmit.length; i++) {
    int msgId = retransmit[i].messageId;
    debugPrint("msgId=$msgId");

    Uint8List? bytes = box.get("retransmit-$msgId-textmessage");
    if (bytes != null) {
      Result resp = await apiProvider.sendTextMessage(
        Int64(retransmit[i].otherUserId),
        bytes,
      );

      if (resp.isSuccess) {
        DbMessages.acknowledgeMessageByServer(msgId);
        box.delete("retransmit-$msgId-textmessage");
      } else {
        // in case of error do nothing. As the message is not removed the app will try again when relaunched
      }
    }

    Uint8List? encryptedMedia = await box.get("retransmit-$msgId-media");
    if (encryptedMedia != null) {
      final content = retransmit[i].messageContent;
      if (content is MediaMessageContent) {
        uploadMediaFile(msgId, Int64(retransmit[i].otherUserId), encryptedMedia,
            content.isRealTwonly, content.maxShowTime, retransmit[i].sendAt);
      }
    }
  }
}

// this functions ensures that the message is received by the server and in case of errors will try again later
Future<Result> encryptAndSendMessage(Int64 userId, Message msg) async {
  Uint8List? bytes = await SignalHelper.encryptMessage(msg, userId);

  if (bytes == null) {
    Logger("api.dart").shout("Error encryption message!");
    return Result.error(ErrorCode.InternalError);
  }

  Box box = await getMediaStorage();
  if (msg.messageId != null) {
    debugPrint("putting=${msg.messageId}");
    box.put("retransmit-${msg.messageId}-textmessage", bytes);
  }

  Result resp = await apiProvider.sendTextMessage(userId, bytes);

  if (resp.isSuccess) {
    if (msg.messageId != null) {
      DbMessages.acknowledgeMessageByServer(msg.messageId!);
      box.delete("retransmit-${msg.messageId}-textmessage");
    }
  }

  return resp;
}

Future sendTextMessage(Int64 target, String message) async {
  MessageContent content = TextMessageContent(text: message);

  DateTime messageSendAt =
      DateTime.now().subtract(Duration(days: 1, minutes: 120));

  int? messageId = await DbMessages.insertMyMessage(
      target.toInt(), MessageKind.textMessage, content, messageSendAt);
  if (messageId == null) return;

  Message msg = Message(
    kind: MessageKind.textMessage,
    messageId: messageId,
    content: content,
    timestamp: messageSendAt,
  );

  encryptAndSendMessage(target, msg);
}

// this will send the media file and ensures retransmission when errors occur
Future uploadMediaFile(
  int messageId,
  Int64 target,
  Uint8List encryptedMedia,
  bool isRealTwonly,
  int maxShowTime,
  DateTime messageSendAt,
) async {
  Box box = await getMediaStorage();

  if ((await box.get("retransmit-$messageId-media") == null)) {
    await box.put("retransmit-$messageId-media", encryptedMedia);
  }

  List<int>? uploadToken = await box.get("retransmit-$messageId-uploadtoken");
  if (uploadToken == null) {
    Result res = await apiProvider.getUploadToken();

    if (res.isError || !res.value.hasUploadtoken()) {
      Logger("api.dart").shout("Error getting upload token!");
      return; // will be retried on next app start
    }

    uploadToken = res.value.uploadtoken;

    await box.put("retransmit-$messageId-uploadtoken", uploadToken);
  }

  if (uploadToken == null) return;

  // TODO: fragmented upload...
  if (!await apiProvider.uploadData(uploadToken, encryptedMedia, 0)) {
    Logger("api.dart").shout("error while uploading media");
    return;
  }

  box.delete("retransmit-$messageId-media");
  box.delete("retransmit-$messageId-uploadtoken");
  await DbContacts.checkAndUpdateFlames(target.toInt());

  // Ensures the retransmit of the message
  await encryptAndSendMessage(
    target,
    Message(
      kind: MessageKind.image,
      messageId: messageId,
      content: MediaMessageContent(
          downloadToken: uploadToken,
          maxShowTime: maxShowTime,
          isRealTwonly: isRealTwonly,
          isVideo: false),
      timestamp: messageSendAt,
    ),
  );
}

Future encryptAndUploadMediaFile(
  Int64 target,
  Uint8List imageBytes,
  bool isRealTwonly,
  int maxShowTime,
) async {
  DateTime messageSendAt = DateTime.now();
  int? messageId = await DbMessages.insertMyMessage(
      target.toInt(),
      MessageKind.image,
      MediaMessageContent(
        downloadToken: [],
        maxShowTime: maxShowTime,
        isRealTwonly: isRealTwonly,
        isVideo: false,
      ),
      messageSendAt);
  // isRealTwonly,
  if (messageId == null) return;

  Uint8List? encryptBytes = await SignalHelper.encryptBytes(imageBytes, target);
  if (encryptBytes == null) {
    await DbMessages.deleteMessageById(messageId);
    Logger("api.dart").shout("Error encrypting media! Deleting media.");
    return;
  }

  await uploadMediaFile(messageId, target, encryptBytes, isRealTwonly,
      maxShowTime, messageSendAt);
}

Future sendImage(
  List<Int64> userIds,
  Uint8List imageBytes,
  bool isRealTwonly,
  int maxShowTime,
) async {
  // 1. set notifier provider

  Uint8List? imageBytesCompressed = await getCompressedImage(imageBytes);
  if (imageBytesCompressed == null) {
    Logger("api.dart").shout("Error compressing image!");
    return;
  }

  for (int i = 0; i < userIds.length; i++) {
    encryptAndUploadMediaFile(
      userIds[i],
      imageBytesCompressed,
      isRealTwonly,
      maxShowTime,
    );
  }
}

Future tryDownloadMedia(List<int> mediaToken, {bool force = false}) async {
  if (!force) {
    // TODO: create option to enable download via mobile data
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      Logger("tryDownloadMedia").info("abort download over mobile connection");
      return;
    }
  }
  Logger("tryDownloadMedia").info("Downloading: $mediaToken");
  int offset = 0;
  final box = await getMediaStorage();
  Uint8List? media = box.get("$mediaToken");
  if (media != null && media.isNotEmpty) {
    offset = media.length;
  }
  globalCallBackOnDownloadChange(mediaToken, true);
  apiProvider.triggerDownload(mediaToken, offset);
}

Future userOpenedOtherMessage(int fromUserId, int messageOtherId) async {
  await DbMessages.userOpenedOtherMessage(messageOtherId, fromUserId);

  encryptAndSendMessage(
    Int64(fromUserId),
    Message(
      kind: MessageKind.opened,
      messageId: messageOtherId,
      content: MessageContent(),
      timestamp: DateTime.now(),
    ),
  );
}

Future<Uint8List?> getDownloadedMedia(
    List<int> mediaToken, int messageOtherId) async {
  final box = await getMediaStorage();
  Uint8List? media = box.get("${mediaToken}_downloaded");

  int fromUserId = box.get("${mediaToken}_fromUserId");
  await userOpenedOtherMessage(fromUserId, messageOtherId);
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
