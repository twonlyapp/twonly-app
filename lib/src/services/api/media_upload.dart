import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:background_downloader/background_downloader.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/tables/media_uploads_table.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/http/http_requests.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pbserver.dart';
import 'package:twonly/src/services/api/media_download.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.twonly_safe.dart';
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
    int? todaysImageCounter = user.todaysImageCounter;
    if (user.lastImageSend != null && user.todaysImageCounter != null) {
      if (isToday(user.lastImageSend!)) {
        if (user.todaysImageCounter == 3) {
          return ErrorCode.PlanLimitReached;
        }
        todaysImageCounter = user.todaysImageCounter! + 1;
      } else {
        todaysImageCounter = 1;
      }
    } else {
      todaysImageCounter = 1;
    }
    await updateUserdata((user) {
      user.lastImageSend = DateTime.now();
      user.todaysImageCounter = todaysImageCounter;
      return user;
    });
  }
  return null;
}

Future initFileDownloader() async {
  FileDownloader().updates.listen((update) async {
    switch (update) {
      case TaskStatusUpdate():
        if (update.task.taskId.contains("upload_")) {
          await handleUploadStatusUpdate(update);
        }
        if (update.task.taskId.contains("download_")) {
          await handleDownloadStatusUpdate(update);
        }
        if (update.task.taskId.contains("backup")) {
          await handleBackupStatusUpdate(update);
        }
      case TaskProgressUpdate():
        Log.info(
            'Progress update for ${update.task} with progress ${update.progress}');
    }
  });

  await FileDownloader().start();

  FileDownloader().configure(androidConfig: [
    (Config.bypassTLSCertificateValidation, kDebugMode),
  ]);

  if (kDebugMode) {
    FileDownloader().configureNotification(
      running: TaskNotification(
        'Uploading/Downloading',
        '{filename} ({progress}).',
      ),
      complete: null,
      progressBar: true,
    );
  }
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
  if (messages.isNotEmpty) {
    Log.error(
      "Got ${messages.length} messages (${mediaUploadIds.length} media upload files) that are not correctly uploaded. Trying from scratch again.",
    );
  }
  return mediaUploadIds.isNotEmpty; // return true if there are affected
}

final lockingHandleMediaFile = Mutex();
Future retryMediaUpload(bool appRestarted, {int maxRetries = 3}) async {
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
        if (appRestarted) {
          /// When the app got restarted and the messageIds or the metadata is not
          /// set then the app was closed before the images was send.
          await twonlyDB.mediaUploadsDao
              .deleteMediaUpload(mediaFile.mediaUploadId);
          Log.info(
            "upload can be removed, the finalized function was never called...",
          );
        }
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
    await retryMediaUpload(false, maxRetries: maxRetries - 1);
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

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  Log.info("Raw images size in bytes: ${imageBytes.length}");

  try {
    imageBytesCompressed = await FlutterImageCompress.compressWithList(
      format: CompressFormat.webp,
      // minHeight: 0,
      // minWidth: 0,
      imageBytes,
      quality: 90,
    );

    if (imageBytesCompressed.length >= 1 * 1000 * 1000) {
      // if the media file is over 2MB compress it with 60%
      imageBytesCompressed = await FlutterImageCompress.compressWithList(
        format: CompressFormat.webp,
        imageBytes,
        quality: 60,
      );
    }
    await writeSendMediaFile(mediaUploadId, "png", imageBytesCompressed);
  } catch (e) {
    Log.error("$e");
    // as a fall back use the original image
    await writeSendMediaFile(mediaUploadId, "png", imageBytes);
    imageBytesCompressed = imageBytes;
  }

  stopwatch.stop();

  Log.info(
      'Compression the image took: ${stopwatch.elapsedMilliseconds} milliseconds');
  Log.info("Raw images size in bytes: ${imageBytesCompressed.length}");

  // stopwatch.reset();
  // stopwatch.start();

  // // var helper = MediaUploadHelper();
  // try {
  //   final webpBytes =
  //       await convertAndCompressImage(pngRawImageBytes: imageBytes);
  //   Log.info(
  //       'Compression the image in rust took: ${stopwatch.elapsedMilliseconds} milliseconds');
  //   Log.info("Raw images size in bytes using webp: ${webpBytes.length}");
  // } catch (e) {
  //   Log.error("$e");
  // }

  /// in case the media file was already encrypted of even uploaded
  /// remove the data so it will be done again.
  await twonlyDB.mediaUploadsDao.updateMediaUpload(
    mediaUploadId,
    MediaUploadsCompanion(
      encryptionData: Value(null),
    ),
  );
  return imageBytesCompressed;
}

Future handlePreProcessingState(MediaUpload media) async {
  try {
    final imageHandler = readSendMediaFile(media.mediaUploadId, "png");
    final videoHandler = compressVideoIfExists(media.mediaUploadId);
    await encryptMediaFiles(
      media.mediaUploadId,
      imageHandler,
      videoHandler,
    );
  } catch (e) {
    Log.error("${media.mediaUploadId} got error in pre processing: $e");
    await handleUploadError(media);
  }
}

Future encryptMediaFiles(
  int mediaUploadId,
  Future imageHandler,
  Future<bool>? videoHandler,
) async {
  Log.info("$mediaUploadId encrypting files");
  Uint8List dataToEncrypt = await imageHandler;

  /// if there is a video wait until it is finished with compression
  if (videoHandler != null) {
    if (await videoHandler) {
      Uint8List compressedVideo = await readSendMediaFile(mediaUploadId, "mp4");
      dataToEncrypt = combineUint8Lists(dataToEncrypt, compressedVideo);
    }
  }

  var state = MediaEncryptionData();

  final chacha20 = FlutterChacha20.poly1305Aead();
  SecretKeyData secretKey = await (await chacha20.newSecretKey()).extract();

  state.encryptionKey = secretKey.bytes;
  state.encryptionNonce = chacha20.newNonce();

  final secretBox = await chacha20.encrypt(
    dataToEncrypt,
    secretKey: secretKey,
    nonce: state.encryptionNonce,
  );

  state.encryptionMac = secretBox.mac.bytes;

  state.sha2Hash = (await Sha256().hash(secretBox.cipherText)).bytes;

  final encryptedBytes = Uint8List.fromList(secretBox.cipherText);
  await writeSendMediaFile(
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
  handleNextMediaUploadSteps(mediaUploadId);
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

  handleNextMediaUploadSteps(mediaUploadId);
}

final lockingHandleNextMediaUploadStep = Mutex();
Future handleNextMediaUploadSteps(int mediaUploadId) async {
  await lockingHandleNextMediaUploadStep.protect(() async {
    var mediaUpload = await twonlyDB.mediaUploadsDao
        .getMediaUploadById(mediaUploadId)
        .getSingleOrNull();

    if (mediaUpload == null) return false;
    if (mediaUpload.state == UploadState.receiverNotified ||
        mediaUpload.state == UploadState.uploadTaskStarted) {
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

      if (mediaUpload.messageIds == null || mediaUpload.metadata == null) {
        /// the finalize function was not called yet...
        return false;
      }

      await handleMediaUpload(mediaUpload);
    } catch (e) {
      Log.error("Non recoverable error while sending media file: $e");
      await handleUploadError(mediaUpload);
    }
    return false;
  });
}

///
/// -- private functions --
///
///
///

Future handleUploadStatusUpdate(TaskStatusUpdate update) async {
  bool failed = false;
  int mediaUploadId = int.parse(update.task.taskId.replaceAll("upload_", ""));

  MediaUpload? media = await twonlyDB.mediaUploadsDao
      .getMediaUploadById(mediaUploadId)
      .getSingleOrNull();
  if (media == null) {
    Log.error(
      "Got an upload task but no upload media in the media upload database",
    );
    return;
  }
  if (update.status == TaskStatus.failed ||
      update.status == TaskStatus.canceled) {
    Log.error("Upload failed: ${update.status}");
    failed = true;
  } else if (update.status == TaskStatus.complete) {
    if (update.responseStatusCode == 200) {
      await handleUploadSuccess(media);
      return;
    } else if (update.responseStatusCode != null) {
      if (update.responseStatusCode! >= 400 &&
          update.responseStatusCode! < 500) {
        failed = true;
      }
      Log.error(
        "Got error while uploading: ${update.responseStatusCode}",
      );
    }
  }

  if (failed) {
    for (final messageId in media.messageIds!) {
      await twonlyDB.messagesDao.updateMessageByMessageId(
        messageId,
        MessagesCompanion(
          acknowledgeByServer: Value(true),
          errorWhileSending: Value(true),
        ),
      );
    }
  }
  Log.info(
      'Status update for ${update.task.taskId} with status ${update.status}');
}

Future handleUploadSuccess(MediaUpload media) async {
  Log.info("Upload of ${media.mediaUploadId} success!");
  currentUploadTasks.remove(media.mediaUploadId);

  await twonlyDB.mediaUploadsDao.updateMediaUpload(
    media.mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.receiverNotified),
    ),
  );

  for (final messageId in media.messageIds!) {
    await twonlyDB.messagesDao.updateMessageByMessageId(
      messageId,
      MessagesCompanion(
        acknowledgeByServer: Value(true),
        errorWhileSending: Value(false),
      ),
    );
  }
}

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

Future handleMediaUpload(MediaUpload media) async {
  Uint8List bytesToUpload =
      await readSendMediaFile(media.mediaUploadId, "encrypted");

  if (media.messageIds == null) return;

  List<Uint8List> downloadTokens =
      createDownloadTokens(media.messageIds!.length);

  List<TextMessage> messagesOnSuccess = [];

  for (var i = 0; i < media.messageIds!.length; i++) {
    MessageJson msg = MessageJson(
      kind: MessageKind.media,
      messageId: media.messageIds![i],
      content: MediaMessageContent(
        downloadToken: downloadTokens[i],
        maxShowTime: media.metadata!.maxShowTime,
        isRealTwonly: media.metadata!.isRealTwonly,
        isVideo: media.metadata!.isVideo,
        mirrorVideo: media.metadata!.mirrorVideo,
        encryptionKey: media.encryptionData!.encryptionKey,
        encryptionMac: media.encryptionData!.encryptionMac,
        encryptionNonce: media.encryptionData!.encryptionNonce,
      ),
      timestamp: media.metadata!.messageSendAt,
    );

    Uint8List plaintextContent =
        Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(msg.toJson()))));

    Message? message = await twonlyDB.messagesDao
        .getMessageByMessageId(media.messageIds![i])
        .getSingleOrNull();

    if (message == null) continue;

    Contact? contact = await twonlyDB.contactsDao
        .getContactByUserId(message.contactId)
        .getSingleOrNull();

    if (contact == null || contact.deleted) {
      Log.warn(
          "Contact deleted ${message.contactId} or not found in database.");
      await twonlyDB.messagesDao.updateMessageByMessageId(
        message.messageId,
        MessagesCompanion(errorWhileSending: Value(true)),
      );
      continue;
    }

    await twonlyDB.contactsDao.incFlameCounter(
      message.contactId,
      false,
      message.sendAt,
    );

    Uint8List? encryptedBytes = await signalEncryptMessage(
      message.contactId,
      plaintextContent,
    );

    if (encryptedBytes == null) continue;

    var messageOnSuccess = TextMessage()
      ..body = encryptedBytes
      ..userId = Int64(message.contactId);

    final pushKind = (media.metadata!.isRealTwonly)
        ? PushKind.twonly
        : (media.metadata!.isVideo)
            ? PushKind.video
            : PushKind.image;

    final pushData = await getPushData(
      message.contactId,
      PushNotification(
        messageId: Int64(message.messageId),
        kind: pushKind,
      ),
    );
    if (pushData != null) {
      messageOnSuccess.pushData = pushData.toList();
    }

    messagesOnSuccess.add(messageOnSuccess);
  }

  final uploadRequest = UploadRequest(
    messagesOnSuccess: messagesOnSuccess,
    downloadTokens: downloadTokens,
    encryptedData: bytesToUpload,
  );

  final uploadRequestBytes = uploadRequest.writeToBuffer();

  String? apiAuthTokenRaw =
      await FlutterSecureStorage().read(key: SecureStorageKeys.apiAuthToken);
  if (apiAuthTokenRaw == null) {
    Log.error("api auth token not defined.");
    return;
  }
  String apiAuthToken = uint8ListToHex(base64Decode(apiAuthTokenRaw));

  File uploadRequestFile = await writeSendMediaFile(
    media.mediaUploadId,
    "upload",
    uploadRequestBytes,
  );

  String apiUrl =
      "http${apiService.apiSecure}://${apiService.apiHost}/api/upload";

  try {
    Log.info("Starting upload from ${media.mediaUploadId}");

    final task = UploadTask.fromFile(
      taskId: "upload_${media.mediaUploadId}",
      displayName: (media.metadata?.isVideo ?? false) ? "image" : "video",
      file: uploadRequestFile,
      url: apiUrl,
      priority: 0,
      retries: 10,
      headers: {
        'x-twonly-auth-token': apiAuthToken,
      },
    );

    currentUploadTasks[media.mediaUploadId] = task;

    try {
      await uploadFileFast(media, uploadRequestBytes, apiUrl, apiAuthToken);
    } catch (e) {
      Log.error("Fast upload failed: $e. Using slow method directly.");
      enqueueUploadTask(media.mediaUploadId);
    }
  } catch (e) {
    Log.error("Exception during upload: $e");
  }
}

Map<int, UploadTask> currentUploadTasks = {};

Future enqueueUploadTask(int mediaUploadId) async {
  if (currentUploadTasks[mediaUploadId] == null) {
    Log.info("could not enqueue upload task: $mediaUploadId");
    return;
  }

  Log.info("Enqueue upload task: $mediaUploadId");

  await FileDownloader().enqueue(currentUploadTasks[mediaUploadId]!);
  currentUploadTasks.remove(mediaUploadId);

  await twonlyDB.mediaUploadsDao.updateMediaUpload(
    mediaUploadId,
    MediaUploadsCompanion(
      state: Value(UploadState.uploadTaskStarted),
    ),
  );
}

Future handleUploadWhenAppGoesBackground() async {
  if (currentUploadTasks.keys.isEmpty) {
    return;
  }
  Log.info("App goes into background. Enqueue uploads to the background.");
  final keys = currentUploadTasks.keys.toList();
  for (final key in keys) {
    enqueueUploadTask(key);
  }
}

Future uploadFileFast(
  MediaUpload media,
  Uint8List uploadRequestFile,
  String apiUrl,
  String apiAuthToken,
) async {
  var requestMultipart = http.MultipartRequest(
    "POST",
    Uri.parse(apiUrl),
  );
  requestMultipart.headers['x-twonly-auth-token'] = apiAuthToken;

  requestMultipart.files.add(http.MultipartFile.fromBytes(
    "file",
    uploadRequestFile,
    filename: "upload",
  ));

  final response = await requestMultipart.send();
  if (response.statusCode == 200) {
    Log.info('Upload successful!');
    await handleUploadSuccess(media);
    return;
  } else {
    Log.info('Upload failed with status: ${response.statusCode}');
  }
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

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  MediaInfo? mediaInfo;
  try {
    mediaInfo = await VideoCompress.compressVideo(
      videoOriginalFile.path,
      quality: VideoQuality.Res1280x720Quality,
      deleteOrigin: false,
      includeAudio:
          true, // https://github.com/jonataslaw/VideoCompress/issues/184
    );

    Log.info("Video has now size of ${mediaInfo!.filesize} bytes.");

    if (mediaInfo.filesize! >= 30 * 1000 * 1000) {
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
  stopwatch.stop();
  Log.info("It took ${stopwatch.elapsedMilliseconds}ms to compress the video");

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

Future<Uint8List> readSendMediaFile(int mediaUploadId, String type) async {
  String basePath = await getMediaFilePath(mediaUploadId, "send");
  File file = File("$basePath.$type");
  if (!await file.exists()) {
    throw Exception("$file not found");
  }
  return await file.readAsBytes();
}

Future<File> writeSendMediaFile(
    int mediaUploadId, String type, Uint8List data) async {
  String basePath = await getMediaFilePath(mediaUploadId, "send");
  File file = File("$basePath.$type");
  await file.writeAsBytes(data);
  return file;
}

Future<void> deleteSendMediaFile(int mediaUploadId, String type) async {
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

List<Uint8List> createDownloadTokens(int n) {
  final Random random = Random();
  List<Uint8List> tokens = [];

  for (int i = 0; i < n; i++) {
    Uint8List token = Uint8List(32);
    for (int j = 0; j < 32; j++) {
      token[j] = random.nextInt(256); // Generate a random byte (0-255)
    }
    tokens.add(token);
  }

  return tokens;
}
