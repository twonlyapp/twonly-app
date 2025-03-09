import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import '../../../../.blocked/archives/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import '../../../../.blocked/archives/messages_model.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/utils/misc.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

Future tryTransmitMessages() async {
  List<DbMessage> retransmit =
      await DbMessages.getAllMessagesForRetransmitting();
  if (retransmit.isEmpty) return;

  Logger("api.dart").info("try sending messages: ${retransmit.length}");

  Box box = await getMediaStorage();
  for (int i = 0; i < retransmit.length; i++) {
    int msgId = retransmit[i].messageId;

    Uint8List? bytes = box.get("retransmit-$msgId-textmessage");
    if (bytes != null) {
      Result resp = await apiProvider.sendTextMessage(
        retransmit[i].otherUserId,
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
        uploadMediaFile(msgId, retransmit[i].otherUserId, encryptedMedia,
            content.isRealTwonly, content.maxShowTime, retransmit[i].sendAt);
      }
    }
  }
}

// this functions ensures that the message is received by the server and in case of errors will try again later
Future<Result> encryptAndSendMessage(int userId, Message msg) async {
  Uint8List? bytes = await SignalHelper.encryptMessage(msg, userId);

  if (bytes == null) {
    Logger("api.dart").shout("Error encryption message!");
    return Result.error(ErrorCode.InternalError);
  }

  Box box = await getMediaStorage();
  if (msg.messageId != null) {
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

Future sendTextMessage(int target, String message) async {
  MessageContent content = TextMessageContent(text: message);

  DateTime messageSendAt = DateTime.now();

  int? messageId = await DbMessages.insertMyMessage(
    target.toInt(),
    MessageKind.textMessage,
    content,
    messageSendAt,
  );
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
  int target,
  Uint8List encryptedMedia,
  bool isRealTwonly,
  int maxShowTime,
  DateTime messageSendAt,
) async {
  Box box = await getMediaStorage();
  Logger("api.dart").info("Uploading image $messageId");

  List<int>? uploadToken = box.get("retransmit-$messageId-uploadtoken");
  if (uploadToken == null) {
    Result res = await apiProvider.getUploadToken();

    if (res.isError || !res.value.hasUploadtoken()) {
      Logger("api.dart").shout("Error getting upload token!");
      return; // will be retried on next app start
    }

    uploadToken = res.value.uploadtoken;
  }

  if (uploadToken == null) return;

  int offset = box.get("retransmit-$messageId-offset") ?? 0;

  int fragmentedTransportSize = 1_000_000; // per upload transfer

  while (offset < encryptedMedia.length) {
    Logger("api.dart").info("Uploading image $messageId with offset: $offset");
    int end = encryptedMedia.length;
    if (offset + fragmentedTransportSize < encryptedMedia.length) {
      end = offset + fragmentedTransportSize;
    }

    Result wasSend = await apiProvider.uploadData(
      uploadToken,
      encryptedMedia.sublist(offset, end),
      offset,
    );

    if (wasSend.isError) {
      await box.put("retransmit-$messageId-offset", 0);
      await box.delete("retransmit-$messageId-uploadtoken");
      Logger("api.dart").shout("error while uploading media");
      return;
    }

    box.put("retransmit-$messageId-offset", offset);

    offset = end;
  }

  box.delete("retransmit-$messageId-media");
  box.delete("retransmit-$messageId-uploadtoken");

  await DbContacts.updateTotalMediaCounter(target.toInt());

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

class SendImage {
  final int userId;
  final Uint8List imageBytes;
  final bool isRealTwonly;
  final int maxShowTime;
  DateTime? messageSendAt;
  int? messageId;
  Uint8List? encryptBytes;

  SendImage({
    required this.userId,
    required this.imageBytes,
    required this.isRealTwonly,
    required this.maxShowTime,
  });

  Future upload() async {
    if (messageId == null || encryptBytes == null || messageSendAt == null) {
      return;
    }
    await uploadMediaFile(messageId!, userId, encryptBytes!, isRealTwonly,
        maxShowTime, messageSendAt!);
  }

  Future encryptAndStore() async {
    encryptBytes = await SignalHelper.encryptBytes(imageBytes, userId);
    if (encryptBytes == null) {
      Logger("api.dart").shout("Error encrypting media! Aborting");
      return;
    }

    messageSendAt = DateTime.now();
    messageId = await DbMessages.insertMyMessage(
      userId.toInt(),
      MessageKind.image,
      MediaMessageContent(
        downloadToken: [],
        maxShowTime: maxShowTime,
        isRealTwonly: isRealTwonly,
        isVideo: false,
      ),
      messageSendAt!,
    );
    // should only happen when there is no space left on the smartphone -> abort message
    if (messageId == null) return;

    Box box = await getMediaStorage();
    await box.put("retransmit-$messageId-media", encryptBytes);
    // message is safe until now -> would be retransmitted if sending would fail..
  }
}

Future sendImage(
  List<int> userIds,
  Uint8List imageBytes,
  bool isRealTwonly,
  int maxShowTime,
) async {
  Uint8List? imageBytesCompressed = await getCompressedImage(imageBytes);
  if (imageBytesCompressed == null) {
    Logger("api.dart").shout("Error compressing image!");
    return;
  }

  if (imageBytesCompressed.length >= 10000000) {
    Logger("api.dart").shout("Image to big aborting!");
    return;
  }

  List<SendImage> tasks = [];

  for (int i = 0; i < userIds.length; i++) {
    tasks.add(
      SendImage(
        userId: userIds[i],
        imageBytes: imageBytesCompressed,
        isRealTwonly: isRealTwonly,
        maxShowTime: maxShowTime,
      ),
    );
  }

  // first step encrypt and store the encrypted image
  await Future.wait(tasks.map((task) => task.encryptAndStore()));

  // after the images are safely stored try do upload them one by one
  for (SendImage task in tasks) {
    task.upload();
  }
}

Future tryDownloadMedia(int messageId, int fromUserId, List<int> mediaToken,
    {bool force = false}) async {
  if (globalIsAppInBackground) return;

  if (!force) {
    // TODO: create option to enable download via mobile data
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      Logger("tryDownloadMedia").info("abort download over mobile connection");
      return;
    }
  }

  final box = await getMediaStorage();
  if (box.containsKey("${mediaToken}_downloaded")) {
    Logger("tryDownloadMedia").shout("mediaToken already downloaded");
    return;
  }

  Logger("tryDownloadMedia").info("Downloading: $mediaToken");
  int offset = 0;
  Uint8List? media = box.get("$mediaToken");
  if (media != null && media.isNotEmpty) {
    offset = media.length;
  }
  globalCallBackOnDownloadChange(mediaToken, true);
  box.put("${mediaToken}_messageId", messageId);
  box.put("${mediaToken}_fromUserId", fromUserId);
  apiProvider.triggerDownload(mediaToken, offset);
}

Future notifyContactAboutOpeningMessage(int fromUserId, int messageOtherId) async {
  //await DbMessages.userOpenedOtherMessage(fromUserId, messageOtherId);

  encryptAndSendMessage(
    fromUserId,
    MessageJson(
      kind: MessageKind.opened,
      messageId: messageOtherId,
      content: MessageContent(),
      timestamp: DateTime.now(),
    ),
  );
}

Future<Uint8List?> getDownloadedMedia(
    List<int> mediaToken, int messageOtherId, int otherUserId) async {
  final box = await getMediaStorage();
  Uint8List? media;
  try {
    media = box.get("${mediaToken}_downloaded");
  } catch (e) {
    return null;
  }
  if (media == null) return null;

  await userOpenedOtherMessage(otherUserId, messageOtherId);
  box.delete(mediaToken.toString());
  box.put("${mediaToken}_downloaded", "deleted");
  box.delete("${mediaToken}_messageId");
  box.delete("${mediaToken}_fromUserId");
  return media;
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
