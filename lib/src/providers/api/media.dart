import 'dart:convert';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/json_models/message.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/hive.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';

Future tryDownloadAllMediaFiles() async {
  if (!await isAllowedToDownload()) {
    return;
  }
  List<Message> messages =
      await twonlyDatabase.messagesDao.getAllMessagesPendingDownloading();

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
  late Map<int, int> messageIds;
  late bool isRealTwonly;
  late int maxShowTime;
  late DateTime messageSendAt;

  Metadata();

  Map<String, dynamic> toJson() {
    // Convert Map<int, int> to Map<String, int> for JSON encoding
    Map<String, int> stringKeyMessageIds =
        messageIds.map((key, value) => MapEntry(key.toString(), value));

    return {
      'userIds': userIds,
      'messageIds': stringKeyMessageIds,
      'isRealTwonly': isRealTwonly,
      'maxShowTime': maxShowTime,
      'messageSendAt': messageSendAt.toIso8601String(),
    };
  }

  factory Metadata.fromJson(Map<String, dynamic> json) {
    Metadata state = Metadata();
    state.userIds = List<int>.from(json['userIds']);

    // Convert Map<String, dynamic> to Map<int, int>
    state.messageIds = (json['messageIds'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(int.parse(key), value as int));

    state.isRealTwonly = json['isRealTwonly'];
    state.maxShowTime = json['maxShowTime'];
    state.messageSendAt = DateTime.parse(json['messageSendAt']);
    return state;
  }
}

class PrepareState {
  late List<int> sha2Hash;
  late List<int> encryptionKey;
  late List<int> encryptionMac;
  late List<int> encryptedBytes;
  late List<int> encryptionNonce;

  PrepareState();

  Map<String, dynamic> toJson() {
    return {
      'sha2Hash': sha2Hash,
      'encryptionKey': encryptionKey,
      'encryptionMac': encryptionMac,
      'encryptedBytes': encryptedBytes,
      'encryptionNonce': encryptionNonce,
    };
  }

  factory PrepareState.fromJson(Map<String, dynamic> json) {
    PrepareState state = PrepareState();
    state.sha2Hash = List<int>.from(json['sha2Hash']);
    state.encryptionKey = List<int>.from(json['encryptionKey']);
    state.encryptionMac = List<int>.from(json['encryptionMac']);
    state.encryptedBytes = List<int>.from(json['encryptedBytes']);
    state.encryptionNonce = List<int>.from(json['encryptionNonce']);
    return state;
  }
}

class UploadState {
  late List<int> uploadToken;
  late List<List<int>> downloadTokens;

  UploadState();

  Map<String, dynamic> toJson() {
    return {
      'uploadToken': uploadToken,
      'downloadTokens': downloadTokens,
    };
  }

  factory UploadState.fromJson(Map<String, dynamic> json) {
    UploadState state = UploadState();
    state.uploadToken = List<int>.from(json['uploadToken']);
    state.downloadTokens = List<List<int>>.from(
      json['downloadTokens'].map((token) => List<int>.from(token)),
    );
    return state;
  }
}

class States {
  late Metadata metadata;
  late PrepareState prepareState;

  States({
    required this.metadata,
    required this.prepareState,
  });

  Map<String, dynamic> toJson() {
    return {
      'metadata': metadata.toJson(),
      'prepareState': prepareState.toJson(),
    };
  }

  factory States.fromJson(Map<String, dynamic> json) {
    return States(
      metadata: Metadata.fromJson(json['metadata']),
      prepareState: PrepareState.fromJson(json['prepareState']),
    );
  }
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

      twonlyDatabase.contactsDao.incFlameCounter(
        targetUserId,
        false,
        metadata.messageSendAt,
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
        pushKind: PushKind.image,
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
  metadata.messageIds = {};
  metadata.messageSendAt = DateTime.now();

  // at this point it is safe inform the user about the process of sending the image..
  for (final userId in metadata.userIds) {
    int? messageId = await twonlyDatabase.messagesDao.insertMessage(
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
    ); // dearchive contact when sending a new message
    twonlyDatabase.contactsDao.updateContact(
      userId,
      ContactsCompanion(
        archived: Value(false),
      ),
    );
    if (messageId != null) {
      metadata.messageIds[userId] = messageId;
    } else {
      Logger("media.dart")
          .shout("Error inserting message in messages database...");
    }
  }

  String stateId = prepareState.sha2Hash.toString();

  {
    Map<String, dynamic> allMediaFiles = await getStoredMediaUploads();
    allMediaFiles[stateId] = jsonEncode(
      States(metadata: metadata, prepareState: prepareState).toJson(),
    );
    (await getMediaStorage()).put("mediaUploads", jsonEncode(allMediaFiles));
  }

  uploadMediaState(stateId, prepareState, metadata);
}

Future<Map<String, dynamic>> getStoredMediaUploads() async {
  Box storage = await getMediaStorage();
  String? mediaFilesJson = storage.get("mediaUploads");
  Map<String, dynamic> allMediaFiles = {};

  if (mediaFilesJson != null) {
    allMediaFiles = jsonDecode(mediaFilesJson);
  }
  return allMediaFiles;
}

Future retransmitMediaFiles() async {
  Map<String, dynamic> allMediaFiles = await getStoredMediaUploads();
  if (allMediaFiles.isEmpty) return;

  bool allSuccess = true;

  for (final entry in allMediaFiles.entries) {
    try {
      String stateId = entry.key;
      States states = States.fromJson(jsonDecode(entry.value));
      // upload one by one
      allSuccess = allSuccess &
          await uploadMediaState(stateId, states.prepareState, states.metadata);
    } catch (e) {
      Logger("media.dart").shout(e);
    }
  }

  if (allSuccess) {
    // when all retransmittions where sucessfull tag the errors
    final pendings = await twonlyDatabase.messagesDao
        .getAllMessagesPendingUploadOlderThanAMinute();
    for (final pending in pendings) {
      twonlyDatabase.messagesDao.updateMessageByMessageId(
        pending.messageId,
        MessagesCompanion(errorWhileSending: Value(true)),
      );
    }
  }
  // return allSuccess;
}

// if the upload failes this function is called again from the retransmitMediaFiles function which is
// called when the WebSocket is reconnected again.
Future<bool> uploadMediaState(
    String stateId, PrepareState prepareState, Metadata metadata) async {
  final uploadState =
      await ImageUploader.uploadState(prepareState, metadata.userIds.length);
  if (uploadState == null) {
    return false;
  }

  {
    Map<String, dynamic> allMediaFiles = await getStoredMediaUploads();
    if (allMediaFiles.isNotEmpty) {
      allMediaFiles.remove(stateId);
      (await getMediaStorage()).put("mediaUploads", jsonEncode(allMediaFiles));
    }
  }

  await ImageUploader.notifyState(prepareState, uploadState, metadata);
  return true;
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

  await twonlyDatabase.messagesDao.updateMessageByOtherUser(
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
  notifyContactAboutOpeningMessage(
      message.contactId, [message.messageOtherId!]);
  twonlyDatabase.messagesDao.updateMessageByMessageId(
      message.messageId, MessagesCompanion(openedAt: Value(DateTime.now())));

  box.delete(downloadToken.toString());
  box.put("${downloadToken}_downloaded", "deleted");
  box.delete("${downloadToken}_messageId");
  return media;
}
