import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/api/media_received.dart';
import 'package:twonly/src/services/notification.service.dart';
import 'package:twonly/src/utils/log.dart';
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

/// States:
/// when user recorded an video
///   1. Compress video
/// when user clicked the send button (direct send) or share with
///   2. Encrypt media files
///   3. Upload media files
/// click send button
///   4. Finalize upload by websocket -> get download tokens
///   5. Send all users the message

/// Create a new entry in the database

Future<bool> checkForFailedUploads() async {
  final messages = await twonlyDB.messagesDao.getAllMessagesPendingUpload();
  List<int> mediaUploadIds = [];
  for (Message message in messages) {
    if (mediaUploadIds.contains(message.mediaUploadId)) {
      continue;
    }
    int affectedRows = await twonlyDB.mediaUploadsDao.updateMediaUpload(
      message.mediaUploadId!,
      MediaUploadsCompanion(
        uploadTokens: Value(null), // reupload them
        state: Value(UploadState.pending),
        encryptionData: Value(
          null, // start from scratch e.q. encrypt the files again if already happen
        ),
      ),
    );
    if (affectedRows == 0) {
      Log.error(
        "The media from message ${message.messageId} already deleted.",
      );
      await twonlyDB.messagesDao.updateMessageByMessageId(
        message.messageId,
        MessagesCompanion(
          errorWhileSending: Value(true),
        ),
      );
    } else {
      mediaUploadIds.add(message.mediaUploadId!);
    }
  }
  Log.error(
    "Got ${messages.length} messages (${mediaUploadIds.length} media upload files) that are not correctly uploaded. Trying from scratch again.",
  );
  return mediaUploadIds.isNotEmpty; // return true if there are affected
}

final lockingHandleMediaFile = Mutex();
Future retryMediaUpload({int maxRetries = 3}) async {
  if (maxRetries == 0) {
    Log.error("retried media upload 3 times. abort retrying");
    return;
  }
  bool retry = await lockingHandleMediaFile.protect<bool>(() async {
    final mediaFiles = await twonlyDB.mediaUploadsDao.getMediaUploadsForRetry();
    if (mediaFiles.isEmpty) {
      return checkForFailedUploads();
    }
    Log.info("re uploading ${mediaFiles.length} media files.");
    for (final mediaFile in mediaFiles) {
      if (mediaFile.messageIds == null || mediaFile.metadata == null) {
        // the media upload was canceled,
        if (mediaFile.uploadTokens != null) {
          /// the file was already uploaded.
          /// notify the server to remove the upload
          apiService.getDownloadTokens(mediaFile.uploadTokens!.uploadToken, 0);
        }
        await twonlyDB.mediaUploadsDao
            .deleteMediaUpload(mediaFile.mediaUploadId);
        Log.info(
            "upload can be removed, the finalized function was never called...");
        continue;
      }

      if (mediaFile.state == UploadState.readyToUpload) {
        await handleNextMediaUploadSteps(mediaFile.mediaUploadId);
      } else {
        await handlePreProcessingState(mediaFile);
      }
    }
    return false;
  });
  if (retry) {
    await retryMediaUpload(maxRetries: maxRetries - 1);
  }
}

Future<int?> initMediaUpload() async {
  return await twonlyDB.mediaUploadsDao
      .insertMediaUpload(MediaUploadsCompanion());
}

Future<bool> addVideoToUpload(int mediaUploadId, File videoFilePath) async {
  String basePath = await getMediaFilePath(mediaUploadId, "send");
  await videoFilePath.copy("$basePath.original.mp4");
  return await compressVideoIfExists(mediaUploadId);
}

Future<Uint8List> addOrModifyImageToUpload(
    int mediaUploadId, Uint8List imageBytes) async {
  Uint8List imageBytesCompressed;
  try {
    imageBytesCompressed = await FlutterImageCompress.compressWithList(
      format: CompressFormat.png,
      imageBytes,
      quality: 90,
    );

    if (imageBytesCompressed.length >= 2 * 1000 * 1000) {
      // if the media file is over 2MB compress it with 60%
      imageBytesCompressed = await FlutterImageCompress.compressWithList(
        format: CompressFormat.png,
        imageBytes,
        quality: 60,
      );
    }
    await writeMediaFile(mediaUploadId, "png", imageBytesCompressed);
  } catch (e) {
    Log.error("$e");
    // as a fall back use the original image
    await writeMediaFile(mediaUploadId, "png", imageBytes);
    imageBytesCompressed = imageBytes;
  }

  /// in case the media file was already encrypted of even uploaded
  /// remove the data so it will be done again.
  await twonlyDB.mediaUploadsDao.updateMediaUpload(
    mediaUploadId,
    MediaUploadsCompanion(
      encryptionData: Value(null),
      uploadTokens: Value(null),
    ),
  );
  return imageBytesCompressed;
}

Future handlePreProcessingState(MediaUpload media) async {
  try {
    final imageHandler = readMediaFile(media.mediaUploadId, "png");
    final videoHandler = compressVideoIfExists(media.mediaUploadId);
    await encryptAndPreUploadMediaFiles(
      media.mediaUploadId,
      imageHandler,
      videoHandler,
    );
  } catch (e) {
    Log.error("${media.mediaUploadId} got error in pre processing: $e");
    await handleUploadError(media);
  }
}

Future encryptAndPreUploadMediaFiles(
  int mediaUploadId,
  Future imageHandler,
  Future<bool>? videoHandler,
) async {
  Log.info("$mediaUploadId encrypting files");
  Uint8List dataToEncrypt = await imageHandler;

  /// if there is a video wait until it is finished with compression
  if (videoHandler != null) {
    if (await videoHandler) {
      Uint8List compressedVideo = await readMediaFile(mediaUploadId, "mp4");
      dataToEncrypt = combineUint8Lists(dataToEncrypt, compressedVideo);
    }
  }

  var state = MediaEncryptionData();

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
    mediaUploadId,
    "encrypted",
    encryptedBytes,
  );

  await twonlyDB.mediaUploadsDao.updateMediaUpload(
    mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.readyToUpload),
      encryptionData: Value(state),
    ),
  );
  await handleNextMediaUploadSteps(mediaUploadId);
}

Future finalizeUpload(int mediaUploadId, List<int> contactIds,
    bool isRealTwonly, bool isVideo, bool mirrorVideo, int maxShowTime) async {
  MediaUploadMetadata metadata = MediaUploadMetadata();
  metadata.contactIds = contactIds;
  metadata.isRealTwonly = isRealTwonly;
  metadata.messageSendAt = DateTime.now();
  metadata.isVideo = isVideo;
  metadata.maxShowTime = maxShowTime;
  metadata.mirrorVideo = mirrorVideo;

  List<int> messageIds = [];

  for (final contactId in contactIds) {
    int? messageId = await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion(
        contactId: Value(contactId),
        kind: Value(MessageKind.media),
        sendAt: Value(metadata.messageSendAt),
        downloadState: Value(DownloadState.pending),
        mediaUploadId: Value(mediaUploadId),
        contentJson: Value(
          jsonEncode(
            MediaMessageContent(
              maxShowTime: maxShowTime,
              isRealTwonly: isRealTwonly,
              isVideo: isVideo,
              mirrorVideo: mirrorVideo,
            ).toJson(),
          ),
        ),
      ),
    );
    // de-archive contact when sending a new message
    await twonlyDB.contactsDao.updateContact(
      contactId,
      ContactsCompanion(
        archived: Value(false),
      ),
    );
    if (messageId != null) {
      messageIds.add(messageId);
    } else {
      Log.error("Error inserting media upload message in database.");
    }
  }

  await twonlyDB.mediaUploadsDao.updateMediaUpload(
    mediaUploadId,
    MediaUploadsCompanion(
      messageIds: Value(messageIds),
      metadata: Value(metadata),
    ),
  );
}

final lockingHandleNextMediaUploadStep = Mutex();
Future handleNextMediaUploadSteps(int mediaUploadId) async {
  bool rerun = await lockingHandleNextMediaUploadStep.protect<bool>(() async {
    var mediaUpload = await twonlyDB.mediaUploadsDao
        .getMediaUploadById(mediaUploadId)
        .getSingleOrNull();

    if (mediaUpload == null) return false;
    if (mediaUpload.state == UploadState.receiverNotified) {
      /// Upload done and all users are notified :)
      Log.info("$mediaUploadId is already done");
      return false;
    }
    try {
      /// Stage 1: media files are not yet encrypted...
      if (mediaUpload.encryptionData == null) {
        // when set this function will be called again by encryptAndPreUploadMediaFiles...
        return false;
      }

      if (mediaUpload.uploadTokens == null) {
        /// the files are not yet uploaded, handle upload...
        /// if the upload succeed the uploadTokens was updated and this function
        /// can be called again to processed the upload done
        return await handleMediaUpload(mediaUploadId);
      }

      if (mediaUpload.messageIds == null || mediaUpload.metadata == null) {
        /// the finalize function was not called yet...
        return false;
      }

      // at this point the media file is uploaded and the receiver are known.
      final downloadTokens = mediaUpload.uploadTokens!.downloadTokens;
      if (downloadTokens.isEmpty) {
        /// there are no download tokens yet, request them...
        return await handleUploadDone(mediaUpload);
      }

      // download tokens are known so send the media file to the receivers
      await handleNotifyReceiver(mediaUpload);
    } catch (e) {
      Log.error("Non recoverable error while sending media file: $e");
      await handleUploadError(mediaUpload);
    }
    return false;
  });
  if (rerun) {
    handleNextMediaUploadSteps(mediaUploadId);
  }
}

///
/// -- private functions --
///
///
///
Future handleUploadError(MediaUpload mediaUpload) async {
  // if the messageIds are already there notify the user about this error...
  if (mediaUpload.messageIds != null) {
    for (int messageId in mediaUpload.messageIds!) {
      await twonlyDB.messagesDao.updateMessageByMessageId(
        messageId,
        MessagesCompanion(
          errorWhileSending: Value(true),
        ),
      );
    }
  }
  await twonlyDB.mediaUploadsDao.deleteMediaUpload(mediaUpload.mediaUploadId);
}

Future<bool> handleUploadDone(MediaUpload media) async {
  Result res = await apiService.getDownloadTokens(
      media.uploadTokens!.uploadToken, media.messageIds!.length);

  if (res.isError || !res.value.hasDownloadtokens()) {
    if (res.isError) {
      if (res.error == ErrorCode.PlanNotAllowed) {
        throw Exception("PlanNotAllowed");
      }
      if (res.error == ErrorCode.PlanLimitReached) {
        throw Exception("PlanLimitReached");
      }
    }
    Log.error("Upload done will be tried again when reconnected to server!");
    return false;
  }

  Response_DownloadTokens tokens = res.value.downloadtokens;
  var token = MediaUploadTokens();
  token.uploadToken = media.uploadTokens!.uploadToken;
  token.downloadTokens = tokens.downloadTokens;

  await twonlyDB.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      uploadTokens: Value(token),
    ),
  );
  return true;
}

Future<bool> handleMediaUpload(int mediaUploadId) async {
  Uint8List bytesToUpload = await readMediaFile(mediaUploadId, "encrypted");

  final storage = FlutterSecureStorage();
  String? apiAuthToken = await storage.read(key: "api_auth_token");
  if (apiAuthToken == null) {
    Log.error("api auth token not defined.");
    return false;
  }

  String apiUrl =
      "http${apiService.apiSecure}://${apiService.apiHost}/api/upload";

  var requestMultipart = http.MultipartRequest(
    "POST",
    Uri.parse(apiUrl),
  );
  requestMultipart.headers['x-twonly-auth-token'] =
      uint8ListToHex(base64Decode(apiAuthToken));

  requestMultipart.files.add(http.MultipartFile.fromBytes(
    "file",
    bytesToUpload,
    filename: "upload",
  ));

  Log.info("Starting upload from $mediaUploadId ");

  try {
    var streamedResponse = await requestMultipart.send();

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      if (response.body.length != 64) {
        Log.error("Got invalid upload token.");
        return false;
      }

      final uploadToken = hexToUint8List(response.body);

      var token = MediaUploadTokens();
      token.uploadToken = uploadToken;
      token.downloadTokens = [];

      await twonlyDB.mediaUploadsDao.updateMediaUpload(
        mediaUploadId,
        MediaUploadsCompanion(
          uploadTokens: Value(token),
        ),
      );
      return true;
    }
  } catch (e) {
    Log.error("Exception during upload: $e");
  }
  return false;
}

Future<bool> handleNotifyReceiver(MediaUpload media) async {
  List<int> alreadyNotified = media.alreadyNotified;

  for (var i = 0; i < media.messageIds!.length; i++) {
    int messageId = media.messageIds![i];

    if (alreadyNotified.contains(messageId)) {
      continue;
    }

    Message? message = await twonlyDB.messagesDao
        .getMessageByMessageId(messageId)
        .getSingleOrNull();
    if (message == null) continue;

    await twonlyDB.contactsDao.incFlameCounter(
      message.contactId,
      false,
      message.sendAt,
    );

    // Ensures the retransmit of the message
    await encryptAndSendMessageAsync(
      messageId,
      message.contactId,
      MessageJson(
        kind: MessageKind.media,
        messageId: messageId,
        content: MediaMessageContent(
          downloadToken: media.uploadTokens!.downloadTokens[i],
          maxShowTime: media.metadata!.maxShowTime,
          isRealTwonly: media.metadata!.isRealTwonly,
          isVideo: media.metadata!.isVideo,
          mirrorVideo: media.metadata!.mirrorVideo,
          encryptionKey: media.encryptionData!.encryptionKey,
          encryptionMac: media.encryptionData!.encryptionMac,
          encryptionNonce: media.encryptionData!.encryptionNonce,
        ),
        timestamp: media.metadata!.messageSendAt,
      ),
      pushKind: (media.metadata!.isRealTwonly)
          ? PushKind.twonly
          : (media.metadata!.isVideo)
              ? PushKind.video
              : PushKind.image,
    );

    alreadyNotified.add(messageId);
    await twonlyDB.mediaUploadsDao.updateMediaUpload(
      media.mediaUploadId,
      MediaUploadsCompanion(
        alreadyNotified: Value(alreadyNotified),
      ),
    );
  }

  await twonlyDB.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.receiverNotified),
    ),
  );
  return true;
}

Future<bool> compressVideoIfExists(int mediaUploadId) async {
  String basePath = await getMediaFilePath(mediaUploadId, "send");
  File videoOriginalFile = File("$basePath.original.mp4");
  File videoCompressedFile = File("$basePath.mp4");

  if (videoCompressedFile.existsSync()) {
    // file is already compressed and exists
    return true;
  }

  if (!videoOriginalFile.existsSync()) {
    // media upload does not have a video
    return false;
  }

  MediaInfo? mediaInfo;

  try {
    mediaInfo = await VideoCompress.compressVideo(
      videoOriginalFile.path,
      quality: VideoQuality.Res1280x720Quality,
      deleteOrigin: false,
      includeAudio:
          true, // https://github.com/jonataslaw/VideoCompress/issues/184
    );

    if (mediaInfo!.filesize! >= 30 * 1000 * 1000) {
      // if the media file is over 20MB compress it with low quality
      mediaInfo = await VideoCompress.compressVideo(
        videoOriginalFile.path,
        quality: VideoQuality.Res960x540Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
    }
  } catch (e) {
    Log.error("during video compression: $e");
  }

  if (mediaInfo == null) {
    Log.error("could not compress video.");
    // as a fall back use the non compressed version
    await videoOriginalFile.copy(videoCompressedFile.path);
    await videoOriginalFile.delete();
  } else {
    await mediaInfo.file!.copy(videoCompressedFile.path);
    await mediaInfo.file!.delete();
  }
  return true;
}

/// --- helper functions ---

Future<Uint8List> readMediaFile(int mediaUploadId, String type) async {
  String basePath = await getMediaFilePath(mediaUploadId, "send");
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

Future<void> deleteMediaFile(int mediaUploadId, String type) async {
  String basePath = await getMediaFilePath(mediaUploadId, "send");
  File file = File("$basePath.$type");
  if (await file.exists()) {
    await file.delete();
  }
}

Future<String> getMediaFilePath(dynamic mediaId, String type) async {
  final basedir = await getApplicationSupportDirectory();
  final mediaSendDir = Directory(join(basedir.path, 'media', type));
  if (!await mediaSendDir.exists()) {
    await mediaSendDir.create(recursive: true);
  }
  return join(mediaSendDir.path, '$mediaId');
}

Future<String> getMediaBaseFilePath(String type) async {
  final basedir = await getApplicationSupportDirectory();
  final mediaSendDir = Directory(join(basedir.path, 'media', type));
  if (!await mediaSendDir.exists()) {
    await mediaSendDir.create(recursive: true);
  }
  return mediaSendDir.path;
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

String uint8ListToHex(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

Uint8List hexToUint8List(String hex) => Uint8List.fromList(List<int>.generate(
    hex.length ~/ 2,
    (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16)));
