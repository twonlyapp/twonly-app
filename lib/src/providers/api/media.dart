import 'dart:collection';
import 'dart:convert';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/database/database.dart';
import 'package:twonly/src/database/messages_db.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/hive.dart';
import 'package:twonly/src/utils/misc.dart';

Future tryDownloadAllMediaFiles() async {
  if (!await isAllowedToDownload()) {
    return;
  }
  List<Message> messages =
      await twonlyDatabase.getAllMessagesPendingDownloading();

  for (Message message in messages) {
    MessageContent? content =
        MessageContent.fromJson(message.kind, jsonDecode(message.contentJson!));

    if (content is MediaMessageContent) {
      tryDownloadMedia(
        message.messageId,
        message.contactId,
        content,
      );
    }
  }
}

class Metadata {
  late List<int> userIds;
  late HashMap<int, int> messageIds;
  late Uint8List imageBytes;
  late bool isRealTwonly;
  late int maxShowTime;
  late DateTime messageSendAt;
}

class PrepareState {
  late List<int> sha2Hash;
  late List<int> encryptionKey;
  late List<int> encryptionMac;
  late List<int> encryptedBytes;
  late List<int> encryptionNonce;
}

class UploadState {
  late List<int> uploadToken;
  late List<List<int>> downloadTokens;
}

class ImageUploader {
  static Future<PrepareState?> prepareState(Uint8List imageBytes) async {
    Uint8List? imageBytesCompressed = await getCompressedImage(imageBytes);
    if (imageBytesCompressed == null) {
      // non recoverable state
      Logger("media.dart").shout("Error compressing image!");
      return null;
    }

    if (imageBytesCompressed.length >= 10000000) {
      // non recoverable state
      Logger("media.dart").shout("Image to big aborting!");
      return null;
    }

    var state = PrepareState();

    try {
      final xchacha20 = Xchacha20.poly1305Aead();
      SecretKeyData secretKey =
          await (await xchacha20.newSecretKey()).extract();

      state.encryptionKey = secretKey.bytes;
      state.encryptionNonce = xchacha20.newNonce();

      final secretBox = await xchacha20.encrypt(
        imageBytesCompressed,
        secretKey: secretKey,
        nonce: state.encryptionNonce,
      );

      state.encryptionMac = secretBox.mac.bytes;

      state.encryptedBytes = secretBox.cipherText;
      final algorithm = Sha256();
      state.sha2Hash = (await algorithm.hash(state.encryptedBytes)).bytes;

      return state;
    } catch (e) {
      Logger("media.dart").shout("Error encrypting image: $e");
      // non recoverable state
      return null;
    }
  }

  static Future<UploadState?> uploadState(
      PrepareState prepareState, int recipientsCount) async {
    int fragmentedTransportSize = 1000000; // per upload transfer

    final res = await apiProvider.getUploadToken(recipientsCount);

    if (res.isError || !res.value.hasUploadtoken()) {
      Logger("media.dart").shout("Error getting upload token!");
      return null; // will be retried on next app start
    }

    Response_UploadToken tokens = res.value.uploadtoken;

    var state = UploadState();
    state.uploadToken = tokens.uploadToken;
    state.downloadTokens = tokens.downloadTokens;

    // box.get("retransmit-$messageId-offset", offset)
    int offset = 0;

    while (offset < prepareState.encryptedBytes.length) {
      Logger("api.dart").info(
          "Uploading image ${prepareState.encryptionMac} with offset: $offset");

      int end;
      List<int>? checksum;
      if (offset + fragmentedTransportSize <
          prepareState.encryptedBytes.length) {
        end = offset + fragmentedTransportSize;
      } else {
        end = prepareState.encryptedBytes.length;
        checksum = prepareState.sha2Hash;
      }

      Result wasSend = await apiProvider.uploadData(
        state.uploadToken,
        Uint8List.fromList(prepareState.encryptedBytes.sublist(offset, end)),
        offset,
        checksum,
      );

      if (wasSend.isError) {
        // await box.put("retransmit-$messageId-offset", 0);
        // await box.delete("retransmit-$messageId-uploadtoken");
        Logger("api.dart").shout("error while uploading media");
        return null;
      }
      offset = end;
    }
    return state;
  }

  static Future notifyState(PrepareState prepareState, UploadState uploadState,
      Metadata metadata) async {
    for (int targetUserId in metadata.userIds) {
      // should never happen
      if (uploadState.downloadTokens.isEmpty) return;
      if (!metadata.messageIds.containsKey(targetUserId)) continue;

      final downloadToken = uploadState.downloadTokens.removeLast();

      twonlyDatabase.incTotalMediaCounter(targetUserId);
      twonlyDatabase.updateContact(
        targetUserId,
        ContactsCompanion(
          lastMessageReceived: Value(metadata.messageSendAt),
        ),
      );

      // Ensures the retransmit of the message
      encryptAndSendMessage(
        metadata.messageIds[targetUserId],
        targetUserId,
        MessageJson(
          kind: MessageKind.media,
          messageId: metadata.messageIds[targetUserId],
          content: MediaMessageContent(
            downloadToken: downloadToken,
            maxShowTime: metadata.maxShowTime,
            isRealTwonly: metadata.isRealTwonly,
            isVideo: false,
            encryptionKey: prepareState.encryptionKey,
            encryptionMac: prepareState.encryptionMac,
            encryptionNonce: prepareState.encryptionNonce,
          ),
          timestamp: metadata.messageSendAt,
        ),
      );
    }
  }
}

Future sendImage(
  List<int> userIds,
  Uint8List imageBytes,
  bool isRealTwonly,
  int maxShowTime,
) async {
  final prepareState = await ImageUploader.prepareState(imageBytes);
  if (prepareState == null) {
    // non recoverable state
    return;
  }

  var metadata = Metadata();
  metadata.userIds = userIds;
  metadata.isRealTwonly = isRealTwonly;
  metadata.maxShowTime = maxShowTime;
  metadata.messageIds = HashMap();
  metadata.messageSendAt = DateTime.now();

  // store prepareState and metadata...

  // at this point it is safe inform the user about the process of sending the image..
  for (final userId in metadata.userIds) {
    int? messageId = await twonlyDatabase.insertMessage(
      MessagesCompanion(
        contactId: Value(userId),
        kind: Value(MessageKind.media),
        sendAt: Value(metadata.messageSendAt),
        downloadState: Value(DownloadState.pending),
        contentJson: Value(
          jsonEncode(
            MediaMessageContent(
              maxShowTime: metadata.maxShowTime,
              isRealTwonly: metadata.isRealTwonly,
              isVideo: false,
            ).toJson(),
          ),
        ),
      ),
    );
    if (messageId != null) {
      metadata.messageIds[userId] = messageId;
    } else {
      Logger("media.dart")
          .shout("Error inserting message in messages database...");
    }
  }

  final uploadState =
      await ImageUploader.uploadState(prepareState, metadata.userIds.length);
  if (uploadState == null) {
    return;
  }

  // delete prepareState and store uploadState...

  final notifyState =
      await ImageUploader.notifyState(prepareState, uploadState, metadata);
  if (notifyState == null) {
    return;
  }
}

Future tryDownloadMedia(
    int messageId, int fromUserId, MediaMessageContent content,
    {bool force = false}) async {
  if (globalIsAppInBackground) return;
  if (content.downloadToken == null) return;

  if (!force) {
    if (!await isAllowedToDownload()) {
      Logger("tryDownloadMedia").info("abort download over mobile connection");
      return;
    }
  }

  final box = await getMediaStorage();
  if (box.containsKey("${messageId}_downloaded")) {
    Logger("tryDownloadMedia").shout("mediaToken already downloaded");
    return;
  }

  Logger("tryDownloadMedia").info("Downloading: $messageId");

  int offset = 0;
  Uint8List? media = box.get("${content.downloadToken!}");
  if (media != null && media.isNotEmpty) {
    offset = media.length;
  }

  box.put("${content.downloadToken!}_messageId", messageId);

  await twonlyDatabase.updateMessageByOtherUser(
    fromUserId,
    messageId,
    MessagesCompanion(
      downloadState: Value(DownloadState.downloading),
    ),
  );
  apiProvider.triggerDownload(content.downloadToken!, offset);
}

Future<Uint8List?> getDownloadedMedia(
    Message message, List<int> downloadToken) async {
  final box = await getMediaStorage();
  Uint8List? media;
  try {
    media = box.get("${downloadToken}_downloaded");
  } catch (e) {
    return null;
  }
  if (media == null) return null;

  // await userOpenedOtherMessage(otherUserId, messageOtherId);
  notifyContactAboutOpeningMessage(message.contactId, message.messageOtherId!);
  twonlyDatabase.updateMessageByMessageId(
      message.messageId, MessagesCompanion(openedAt: Value(DateTime.now())));

  box.delete(downloadToken.toString());
  box.put("${downloadToken}_downloaded", "deleted");
  box.delete("${downloadToken}_messageId");
  return media;
}
