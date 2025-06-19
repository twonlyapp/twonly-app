import 'dart:convert';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';

Map<int, DateTime> downloadStartedForMediaReceived = {};

Future tryDownloadAllMediaFiles({bool force = false}) async {
  // this is called when websocket is newly connected, so allow all downloads to be restarted.
  downloadStartedForMediaReceived = {};
  List<Message> messages =
      await twonlyDB.messagesDao.getAllMessagesPendingDownloading();

  for (Message message in messages) {
    await startDownloadMedia(message, force);
  }
}

enum DownloadMediaTypes {
  video,
  image,
}

Map<String, List<String>> defaultAutoDownloadOptions = {
  ConnectivityResult.mobile.name: [],
  ConnectivityResult.wifi.name: [
    DownloadMediaTypes.video.name,
    DownloadMediaTypes.image.name
  ]
};

Future<bool> isAllowedToDownload(bool isVideo) async {
  final List<ConnectivityResult> connectivityResult =
      await (Connectivity().checkConnectivity());

  final user = await getUser();
  final options = user!.autoDownloadOptions ?? defaultAutoDownloadOptions;

  if (connectivityResult.contains(ConnectivityResult.mobile)) {
    if (isVideo) {
      if (options[ConnectivityResult.mobile.name]!
          .contains(DownloadMediaTypes.video.name)) {
        return true;
      }
    } else if (options[ConnectivityResult.mobile.name]!
        .contains(DownloadMediaTypes.image.name)) {
      return true;
    }
  }
  if (connectivityResult.contains(ConnectivityResult.wifi)) {
    if (isVideo) {
      if (options[ConnectivityResult.wifi.name]!
          .contains(DownloadMediaTypes.video.name)) {
        return true;
      }
    } else if (options[ConnectivityResult.wifi.name]!
        .contains(DownloadMediaTypes.image.name)) {
      return true;
    }
  }
  return false;
}

Future handleDownloadStatusUpdate(TaskStatusUpdate update) async {
  bool failed = false;
  int messageId = int.parse(update.task.taskId.replaceAll("download_", ""));

  if (update.status == TaskStatus.failed ||
      update.status == TaskStatus.canceled) {
    Log.error("Download failed: ${update.status}");
    failed = true;
  } else if (update.status == TaskStatus.complete) {
    if (update.responseStatusCode == 200) {
      Log.info("Download was successfully for $messageId");
      await handleEncryptedFile(messageId);
    } else {
      Log.error(
          "Got invalid response status code: ${update.responseStatusCode}");
    }
  }

  if (failed) {
    Message? message = await twonlyDB.messagesDao
        .getMessageByMessageId(messageId)
        .getSingleOrNull();
    if (message != null) {
      await handleMediaError(message);
    }
  }
}

Future startDownloadMedia(Message message, bool force,
    {int retryCounter = 0}) async {
  if (message.contentJson == null) return;
  if (downloadStartedForMediaReceived[message.messageId] != null &&
      retryCounter == 0) {
    DateTime started = downloadStartedForMediaReceived[message.messageId]!;
    Duration elapsed = DateTime.now().difference(started);
    if (elapsed <= Duration(seconds: 60)) {
      Log.error("Download already started...");
      return;
    }
  }

  final content =
      MessageContent.fromJson(message.kind, jsonDecode(message.contentJson!));

  if (content is! MediaMessageContent) return;
  if (content.downloadToken == null) return;

  var media = await twonlyDB.mediaDownloadsDao
      .getMediaDownloadById(message.messageId)
      .getSingleOrNull();
  if (media == null) {
    await twonlyDB.mediaDownloadsDao.insertMediaDownload(
      MediaDownloadsCompanion(
        messageId: Value(message.messageId),
        downloadToken: Value(content.downloadToken!),
      ),
    );
    media = await twonlyDB.mediaDownloadsDao
        .getMediaDownloadById(message.messageId)
        .getSingleOrNull();
  }

  if (media == null) return;

  if (!force && !await isAllowedToDownload(content.isVideo)) {
    return;
  }

  if (message.downloadState != DownloadState.downloaded) {
    await twonlyDB.messagesDao.updateMessageByMessageId(
      message.messageId,
      MessagesCompanion(
        downloadState: Value(DownloadState.downloading),
      ),
    );
  }

  // int offset = 0;
  // Uint8List? bytes = await readMediaFile(media.messageId, "encrypted");
  // if (bytes != null && bytes.isNotEmpty) {
  //   offset = bytes.length;

  downloadStartedForMediaReceived[message.messageId] = DateTime.now();

  String downloadToken = uint8ListToHex(content.downloadToken!);

  String apiUrl =
      "http${apiService.apiSecure}://${apiService.apiHost}/api/download/$downloadToken";

  try {
    final task = DownloadTask(
      url: apiUrl,
      taskId: "download_${media.messageId}",
      directory: "media/received/",
      baseDirectory: BaseDirectory.applicationSupport,
      filename: "${media.messageId}.encrypted",
      priority: 0,
      retries: 10,
    );

    Log.info(
        "Got media file. Starting download: ${downloadToken.substring(0, 10)}");

    final result = await FileDownloader().enqueue(task);

    return result;
  } catch (e) {
    Log.error("Exception during upload: $e");
  }
}

Future handleEncryptedFile(int messageId) async {
  Message? msg = await twonlyDB.messagesDao
      .getMessageByMessageId(messageId)
      .getSingleOrNull();
  if (msg == null) {
    Log.error("Not message for downloaded file found: $messageId");
    return;
  }

  Uint8List? encryptedBytes = await readMediaFile(msg.messageId, "encrypted");

  if (encryptedBytes == null) {
    Log.error("encrypted bytes are not found for ${msg.messageId}");
    return;
  }

  MediaMessageContent content =
      MediaMessageContent.fromJson(jsonDecode(msg.contentJson!));

  final xchacha20 = Xchacha20.poly1305Aead();
  SecretKeyData secretKeyData = SecretKeyData(content.encryptionKey!);

  SecretBox secretBox = SecretBox(
    encryptedBytes,
    nonce: content.encryptionNonce!,
    mac: Mac(content.encryptionMac!),
  );

  try {
    final plaintextBytes =
        await xchacha20.decrypt(secretBox, secretKey: secretKeyData);
    var imageBytes = Uint8List.fromList(plaintextBytes);

    if (content.isVideo) {
      final extractedBytes = extractUint8Lists(imageBytes);
      imageBytes = extractedBytes[0];
      await writeMediaFile(msg.messageId, "mp4", extractedBytes[1]);
    }

    await writeMediaFile(msg.messageId, "png", imageBytes);
  } catch (e) {
    Log.error(
        "could not decrypt the media file in the second try. reporting error to user: $e");
    handleMediaError(msg);
    return;
  }

  await twonlyDB.messagesDao.updateMessageByMessageId(
    msg.messageId,
    MessagesCompanion(downloadState: Value(DownloadState.downloaded)),
  );

  await deleteMediaFile(msg.messageId, "encrypted");

  apiService.downloadDone(content.downloadToken!);
}

Future<Uint8List?> getImageBytes(int mediaId) async {
  return await readMediaFile(mediaId, "png");
}

Future<File?> getVideoPath(int mediaId) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  return File("$basePath.mp4");
}

/// --- helper functions ---

Future<Uint8List?> readMediaFile(int mediaId, String type) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  File file = File("$basePath.$type");
  Log.info("Reading: ${file}");
  if (!await file.exists()) {
    return null;
  }
  return await file.readAsBytes();
}

Future<bool> existsMediaFile(int mediaId, String type) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  File file = File("$basePath.$type");
  return await file.exists();
}

Future<void> writeMediaFile(int mediaId, String type, Uint8List data) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  File file = File("$basePath.$type");
  await file.writeAsBytes(data);
}

Future<void> deleteMediaFile(int mediaId, String type) async {
  String basePath = await getMediaFilePath(mediaId, "received");
  File file = File("$basePath.$type");
  try {
    if (await file.exists()) {
      await file.delete();
    }
  } catch (e) {
    Log.error("Error deleting: $e");
  }
}

Future<void> purgeReceivedMediaFiles() async {
  final basedir = await getApplicationSupportDirectory();
  final directory = Directory(join(basedir.path, 'media', "received"));
  await purgeMediaFiles(directory);
}

Future<void> purgeMediaFiles(Directory directory) async {
  // Check if the directory exists
  if (await directory.exists()) {
    // List all files in the directory
    List<FileSystemEntity> files = directory.listSync();

    // Iterate over each file
    for (var file in files) {
      // Get the filename
      String filename = file.uri.pathSegments.last;

      // Use a regular expression to extract the integer part
      final match = RegExp(r'(\d+)').firstMatch(filename);
      if (match != null) {
        // Parse the integer and add it to the list
        int fileId = int.parse(match.group(0)!);

        try {
          if (directory.path.endsWith("send")) {
            List<Message> messages =
                await twonlyDB.messagesDao.getMessagesByMediaUploadId(fileId);
            bool canBeDeleted = true;

            for (final message in messages) {
              try {
                MediaMessageContent content = MediaMessageContent.fromJson(
                  jsonDecode(message.contentJson!),
                );

                DateTime oneDayAgo = DateTime.now().subtract(Duration(days: 1));

                if (((message.openedAt == null ||
                        oneDayAgo.isBefore(message.openedAt!)) &&
                    !message.errorWhileSending)) {
                  canBeDeleted = false;
                } else if (message.mediaStored) {
                  if (!file.path.contains(".original.") &&
                      !file.path.contains(".encrypted")) {
                    canBeDeleted = false;
                  }
                }
                if (message.acknowledgeByServer) {
                  // preserve images which can be stored by the other person...
                  if (content.maxShowTime != gMediaShowInfinite) {
                    canBeDeleted = true;
                  }
                  // encrypted or upload data can be removed when acknowledgedByServer
                  if (file.path.contains(".upload") ||
                      file.path.contains(".encrypted")) {
                    canBeDeleted = true;
                  }
                }
              } catch (e) {}
            }
            if (canBeDeleted) {
              Log.info("purged media file ${file.path} ");
              file.deleteSync();
            }
          } else {
            Message? message = await twonlyDB.messagesDao
                .getMessageByMessageId(fileId)
                .getSingleOrNull();
            if ((message == null) ||
                (message.openedAt != null &&
                    !message.mediaStored &&
                    message.acknowledgeByServer == true) ||
                message.errorWhileSending) {
              file.deleteSync();
            }
          }
        } catch (e) {
          Log.error("$e");
        }
      }
    }
  }
}

// /data/user/0/eu.twonly.testing/files/media/received/27.encrypted
// /data/user/0/eu.twonly.testing/app_flutter/data/user/0/eu.twonly.testing/files/media/received/27.encrypted
