import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/media_uploads_table.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/api/media_received.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:video_compress/video_compress.dart';

Future<ErrorCode?> isAllowedToSend() async {
  final user = await getUser();
  if (user == null) return null;
  if (user.subscriptionPlan == "Preview") {
    return ErrorCode.PlanNotAllowed;
  }
  if (user.subscriptionPlan == "Free") {
    if (user.lastImageSend != null && user.todaysImageCounter != null) {
      if (isToday(user.lastImageSend!)) {
        if (user.todaysImageCounter == 3) {
          return ErrorCode.PlanLimitReached;
        }
        user.todaysImageCounter = user.todaysImageCounter! + 1;
      } else {
        user.todaysImageCounter = 1;
      }
    } else {
      user.todaysImageCounter = 1;
    }
    user.lastImageSend = DateTime.now();
    await updateUser(user);
  }
  return null;
}

Future sendMediaFile(
  List<int> userIds,
  Uint8List imageBytes,
  bool isRealTwonly,
  int maxShowTime,
  XFile? videoFilePath,
  bool? enableVideoAudio,
  bool mirrorVideo,
) async {
  MediaUploadMetadata metadata = MediaUploadMetadata();
  metadata.contactIds = userIds;
  metadata.isRealTwonly = isRealTwonly;
  metadata.messageSendAt = DateTime.now();
  metadata.isVideo = videoFilePath != null;
  metadata.videoWithAudio = enableVideoAudio != null && enableVideoAudio;
  metadata.maxShowTime = maxShowTime;
  metadata.mirrorVideo = mirrorVideo;

  int? mediaUploadId = await twonlyDatabase.mediaUploadsDao.insertMediaUpload(
    MediaUploadsCompanion(
      metadata: Value(metadata),
    ),
  );

  if (mediaUploadId != null) {
    if (videoFilePath != null) {
      String basePath = await getMediaFilePath(mediaUploadId, "send");
      await File(videoFilePath.path).rename("$basePath.orginal.mp4");
    }
    await writeMediaFile(mediaUploadId, "orginal.png", imageBytes);
    await handleSingleMediaFile(mediaUploadId, imageBytes);
  }
}

Future retryMediaUpload() async {
  final mediaFiles =
      await twonlyDatabase.mediaUploadsDao.getMediaUploadsForRetry();
  for (final mediaFile in mediaFiles) {
    await handleSingleMediaFile(mediaFile.mediaUploadId, null);
  }
}

final lockingHandleMediaFile = Mutex();

Future handleSingleMediaFile(
    int mediaUploadId, Uint8List? tmpCurrentImageBytes) async {
  // await lockingHandleMediaFile.protect(() async {
  MediaUpload? media = await twonlyDatabase.mediaUploadsDao
      .getMediaUploadById(mediaUploadId)
      .getSingleOrNull();
  if (media == null) return;

  try {
    switch (media.state) {
      case UploadState.pending:
        await handleAddToMessageDb(media);
        break;
      case UploadState.addedToMessagesDb:
        tmpCurrentImageBytes =
            await handleCompressionState(media, tmpCurrentImageBytes);
        break;
      case UploadState.isCompressed:
        tmpCurrentImageBytes =
            await handleEncryptionState(media, tmpCurrentImageBytes);
        break;
      case UploadState.isEncrypted:
        if (!await handleGetUploadToken(media)) {
          return; // recoverable error. try again when connected again to the server...
        }
        break;
      case UploadState.hasUploadToken:
        if (!await handleUpload(media, tmpCurrentImageBytes)) {
          return; // recoverable error. try again when connected again to the server...
        }
        break;
      case UploadState.isUploaded:
        if (!await handleNotifyReceiver(media)) {
          return; // recoverable error. try again when connected again to the server...
        }
        try {
          // delete non compressed media files
          await deleteMediaFile(media, "orginal.png");
          await deleteMediaFile(media, "orginal.mp4");
          await deleteMediaFile(media, "encrypted");
        } catch (e) {
          Logger("media_send.dart").shout("$e");
        }
        break;
      case UploadState.receiverNotified:
        return;
    }
  } catch (e) {
    // if the messageIds are already there notify the user about this error...
    if (media.messageIds != null) {
      for (int messageId in media.messageIds!) {
        await twonlyDatabase.messagesDao.updateMessageByMessageId(
          messageId,
          MessagesCompanion(
            errorWhileSending: Value(true),
          ),
        );
      }
    }
    await twonlyDatabase.mediaUploadsDao.deleteMediaUpload(mediaUploadId);
    Logger("media_send.dart")
        .shout("Non recoverable error while sending media file: $e");
    return;
  }
  // });
  // this will be called until there is an recoverable error OR
  // the upload is ready
  await handleSingleMediaFile(mediaUploadId, tmpCurrentImageBytes);
}

Future handleAddToMessageDb(MediaUpload media) async {
  List<int> messageIds = [];

  for (final contactId in media.metadata.contactIds) {
    int? messageId = await twonlyDatabase.messagesDao.insertMessage(
      MessagesCompanion(
        contactId: Value(contactId),
        kind: Value(MessageKind.media),
        sendAt: Value(media.metadata.messageSendAt),
        downloadState: Value(DownloadState.pending),
        mediaUploadId: Value(media.mediaUploadId),
        contentJson: Value(
          jsonEncode(
            MediaMessageContent(
              maxShowTime: media.metadata.maxShowTime,
              isRealTwonly: media.metadata.isRealTwonly,
              isVideo: media.metadata.isVideo,
              mirrorVideo: media.metadata.mirrorVideo,
            ).toJson(),
          ),
        ),
      ),
    ); // dearchive contact when sending a new message
    await twonlyDatabase.contactsDao.updateContact(
      contactId,
      ContactsCompanion(
        archived: Value(false),
      ),
    );
    if (messageId != null) {
      messageIds.add(messageId);
    } else {
      Logger("media_send.dart")
          .shout("Error inserting media upload message in database.");
    }
  }

  await twonlyDatabase.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.addedToMessagesDb),
      messageIds: Value(messageIds),
    ),
  );
}

Future<Uint8List?> handleCompressionState(
  MediaUpload media,
  Uint8List? tmpCurrentImageBytes,
) async {
  Uint8List imageBytes = (tmpCurrentImageBytes != null)
      ? tmpCurrentImageBytes
      : await readMediaFile(media, "orginal.png");

  Uint8List imageBytesCompressed;
  try {
    imageBytesCompressed = await FlutterImageCompress.compressWithList(
      format: CompressFormat.png,
      imageBytes,
      quality: 90,
    );

    if (imageBytesCompressed.length >= 1 * 1000 * 1000) {
      // if the media file is over 1MB compress it with 60%
      imageBytesCompressed = await FlutterImageCompress.compressWithList(
        format: CompressFormat.png,
        imageBytes,
        quality: 60,
      );
    }
    await writeMediaFile(media.mediaUploadId, "png", imageBytesCompressed);
  } catch (e) {
    Logger("media_send.dart").shout("$e");
    // as a fall back use the orginal image
    await writeMediaFile(media.mediaUploadId, "png", imageBytes);
    imageBytesCompressed = imageBytes;
  }

  if (media.metadata.isVideo) {
    String basePath = await getMediaFilePath(media.mediaUploadId, "send");
    File videoOriginalFile = File("$basePath.orginal.mp4");
    File videoCompressedFile = File("$basePath.mp4");

    MediaInfo? mediaInfo;

    try {
      mediaInfo = await VideoCompress.compressVideo(
        videoOriginalFile.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio:
            true, // https://github.com/jonataslaw/VideoCompress/issues/184
      );

      if (mediaInfo!.filesize! >= 20 * 1000 * 1000) {
        // if the media file is over 20MB compress it with low quality
        mediaInfo = await VideoCompress.compressVideo(
          videoOriginalFile.path,
          quality: VideoQuality.Res960x540Quality,
          deleteOrigin: false,
          includeAudio: media.metadata.videoWithAudio,
        );
      }
    } catch (e) {
      Logger("media_send.dart").shout("Video compression: $e");
    }

    if (mediaInfo == null) {
      Logger("media_send.dart").shout("Error compressing video.");
      // as a fall back use the non compressed version
      await videoOriginalFile.copy(videoCompressedFile.path);
      await videoOriginalFile.delete();
    } else {
      await mediaInfo.file!.copy(videoCompressedFile.path);
      await mediaInfo.file!.delete();
    }
  }

  await twonlyDatabase.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.isCompressed),
    ),
  );

  return imageBytesCompressed;
}

Future<Uint8List> handleEncryptionState(
    MediaUpload media, Uint8List? tmpCurrentImageBytes) async {
  var state = MediaEncryptionData();

  Uint8List dataToEncrypt = (tmpCurrentImageBytes != null)
      ? tmpCurrentImageBytes
      : await readMediaFile(media, "png");

  if (media.metadata.isVideo) {
    Uint8List compressedVideo = await readMediaFile(media, "mp4");
    dataToEncrypt = combineUint8Lists(dataToEncrypt, compressedVideo);
  }

  final xchacha20 = Xchacha20.poly1305Aead();
  SecretKeyData secretKey = await (await xchacha20.newSecretKey()).extract();

  state.encryptionKey = secretKey.bytes;
  state.encryptionNonce = xchacha20.newNonce();

  final secretBox = await xchacha20.encrypt(
    dataToEncrypt,
    secretKey: secretKey,
    nonce: state.encryptionNonce,
  );

  state.encryptionMac = secretBox.mac.bytes;

  final algorithm = Sha256();
  state.sha2Hash = (await algorithm.hash(secretBox.cipherText)).bytes;

  final encryptedBytes = Uint8List.fromList(secretBox.cipherText);
  await writeMediaFile(
    media.mediaUploadId,
    "encrypted",
    encryptedBytes,
  );

  await twonlyDatabase.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.isEncrypted),
      encryptionData: Value(state),
    ),
  );
  return encryptedBytes;
}

Future<bool> handleGetUploadToken(MediaUpload media) async {
  final res =
      await apiProvider.getUploadToken(media.metadata.contactIds.length);

  if (res.isError || !res.value.hasUploadtoken()) {
    if (res.isError) {
      if (res.error == ErrorCode.PlanNotAllowed) {
        throw Exception("PlanNotAllowed");
      }
      if (res.error == ErrorCode.PlanLimitReached) {
        throw Exception("PlanLimitReached");
      }
    }
    Logger("media_send.dart")
        .shout("Will be tried again when reconnected to server!");
    return false;
  }

  Response_UploadToken tokens = res.value.uploadtoken;

  var token = MediaUploadTokens();
  token.uploadToken = tokens.uploadToken;
  token.downloadTokens = tokens.downloadTokens;

  await twonlyDatabase.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.hasUploadToken),
      uploadTokens: Value(token),
    ),
  );

  return true;
}

Future<bool> handleUpload(
    MediaUpload media, Uint8List? tmpCurrentImageBytes) async {
  Uint8List bytesToUpload = (tmpCurrentImageBytes != null)
      ? tmpCurrentImageBytes
      : await readMediaFile(media, "encrypted");

  int fragmentedTransportSize = 1000000;

  int offset = 0;

  while (offset < bytesToUpload.length) {
    Logger("media_send.dart").fine(
        "Uploading media file ${media.mediaUploadId} with offset: $offset");

    int end;
    List<int>? checksum;
    if (offset + fragmentedTransportSize < bytesToUpload.length) {
      end = offset + fragmentedTransportSize;
    } else {
      end = bytesToUpload.length;
      checksum = media.encryptionData!.sha2Hash;
    }

    Result wasSend = await apiProvider.uploadData(
      media.uploadTokens!.uploadToken,
      Uint8List.fromList(bytesToUpload.sublist(offset, end)),
      offset,
      checksum,
    );

    if (wasSend.isError) {
      if (wasSend.error == ErrorCode.InvalidUpdateToken) {
        await twonlyDatabase.mediaUploadsDao.updateMediaUpload(
          media.mediaUploadId,
          MediaUploadsCompanion(
            state: Value(UploadState.isEncrypted),
          ),
        );
        return true; // this will trigger a new token request
      }
      Logger("media_send.dart")
          .shout("error while uploading media: ${wasSend.error}");
      return false;
    }
    offset = end;
  }

  await twonlyDatabase.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.isUploaded),
    ),
  );

  return true;
}

Future<bool> handleNotifyReceiver(MediaUpload media) async {
  List<int> alreadyNotified = media.alreadyNotified;

  for (var i = 0; i < media.messageIds!.length; i++) {
    int messageId = media.messageIds![i];

    if (alreadyNotified.contains(messageId)) {
      continue;
    }

    Message? message = await twonlyDatabase.messagesDao
        .getMessageByMessageId(messageId)
        .getSingleOrNull();
    if (message == null) continue;

    await twonlyDatabase.contactsDao.incFlameCounter(
      message.contactId,
      false,
      message.sendAt,
    );

    // Ensures the retransmit of the message
    await encryptAndSendMessage(
      messageId,
      message.contactId,
      MessageJson(
        kind: MessageKind.media,
        messageId: messageId,
        content: MediaMessageContent(
          downloadToken: media.uploadTokens!.downloadTokens[i],
          maxShowTime: media.metadata.maxShowTime,
          isRealTwonly: media.metadata.isRealTwonly,
          isVideo: media.metadata.isVideo,
          mirrorVideo: media.metadata.mirrorVideo,
          encryptionKey: media.encryptionData!.encryptionKey,
          encryptionMac: media.encryptionData!.encryptionMac,
          encryptionNonce: media.encryptionData!.encryptionNonce,
        ),
        timestamp: media.metadata.messageSendAt,
      ),
      pushKind: (media.metadata.isRealTwonly)
          ? PushKind.twonly
          : (media.metadata.isVideo)
              ? PushKind.video
              : PushKind.image,
    );

    alreadyNotified.add(messageId);
    await twonlyDatabase.mediaUploadsDao.updateMediaUpload(
      media.mediaUploadId,
      MediaUploadsCompanion(
        alreadyNotified: Value(alreadyNotified),
      ),
    );
  }

  await twonlyDatabase.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.receiverNotified),
    ),
  );
  return true;
}

/// --- helper functions ---

Future<Uint8List> readMediaFile(MediaUpload media, String type) async {
  String basePath = await getMediaFilePath(media.mediaUploadId, "send");
  File file = File("$basePath.$type");
  if (!await file.exists()) {
    throw Exception("$file not found");
  }
  return await file.readAsBytes();
}

Future<void> writeMediaFile(
    int mediaUploadId, String type, Uint8List data) async {
  String basePath = await getMediaFilePath(mediaUploadId, "send");
  File file = File("$basePath.$type");
  await file.writeAsBytes(data);
}

Future<void> deleteMediaFile(MediaUpload media, String type) async {
  String basePath = await getMediaFilePath(media.mediaUploadId, "send");
  File file = File("$basePath.$type");
  if (await file.exists()) {
    await file.delete();
  }
}

Future<String> getMediaFilePath(int mediaId, String type) async {
  final basedir = await getApplicationSupportDirectory();
  final mediaSendDir = Directory(join(basedir.path, 'media', type));
  if (!await mediaSendDir.exists()) {
    await mediaSendDir.create(recursive: true);
  }
  return join(mediaSendDir.path, '$mediaId');
}

/// combines two utf8 list
Uint8List combineUint8Lists(Uint8List list1, Uint8List list2) {
  final combinedLength = 4 + list1.length + list2.length;
  final combinedList = Uint8List(combinedLength);
  final byteData = ByteData.sublistView(combinedList);
  byteData.setInt32(
      0, list1.length, Endian.big); // Store size in big-endian format
  combinedList.setRange(4, 4 + list1.length, list1);
  combinedList.setRange(4 + list1.length, combinedLength, list2);
  return combinedList;
}

List<Uint8List> extractUint8Lists(Uint8List combinedList) {
  final byteData = ByteData.sublistView(combinedList);
  final sizeOfList1 = byteData.getInt32(0, Endian.big);
  final list1 = Uint8List.view(combinedList.buffer, 4, sizeOfList1);
  final list2 = Uint8List.view(combinedList.buffer, 4 + sizeOfList1,
      combinedList.lengthInBytes - 4 - sizeOfList1);
  return [list1, list2];
}

Future<void> purgeSendMediaFiles() async {
  final basedir = await getApplicationSupportDirectory();
  final directory = Directory(join(basedir.path, 'media', "send"));
  await purgeMediaFiles(directory);
}
