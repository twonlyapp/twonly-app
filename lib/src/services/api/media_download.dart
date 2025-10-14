import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/share_image_editor_view.dart';

Future<void> tryDownloadAllMediaFiles({bool force = false}) async {
  // This is called when WebSocket is newly connected, so allow all downloads to be restarted.
  final messages =
      await twonlyDB.messagesDao.getAllMessagesPendingDownloading();

  for (final message in messages) {
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
    DownloadMediaTypes.image.name,
  ],
};

Future<bool> isAllowedToDownload(bool isVideo) async {
  final connectivityResult = await Connectivity().checkConnectivity();

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

Future<void> handleDownloadStatusUpdate(TaskStatusUpdate update) async {
  final messageId = int.parse(update.task.taskId.replaceAll('download_', ''));
  var failed = false;

  if (update.status == TaskStatus.failed ||
      update.status == TaskStatus.canceled ||
      update.status == TaskStatus.notFound) {
    failed = true;
  } else if (update.status == TaskStatus.complete) {
    if (update.responseStatusCode == 200) {
      failed = false;
    } else {
      failed = true;
      Log.error(
        'Got invalid response status code: ${update.responseStatusCode}',
      );
    }
  } else {
    Log.info('Got ${update.status} for $messageId');
    return;
  }
  await handleDownloadStatusUpdateInternal(messageId, failed);
}

Future<void> handleDownloadStatusUpdateInternal(
  int messageId,
  bool failed,
) async {
  if (failed) {
    Log.error('Download failed for $messageId');
    final message = await twonlyDB.messagesDao
        .getMessageByMessageId(messageId)
        .getSingleOrNull();
    if (message != null && message.downloadState != DownloadState.downloaded) {
      await handleMediaError(message);
    }
  } else {
    Log.info('Download was successfully for $messageId');
    await handleEncryptedFile(messageId);
  }
}

Mutex protectDownload = Mutex();

Future<void> startDownloadMedia(Message message, bool force) async {
  Log.info(
    'Download blocked for ${message.messageId} because of network state.',
  );
  if (message.contentJson == null) {
    Log.error('Content of ${message.messageId} not found.');
    await handleMediaError(message);
    return;
  }

  final content = MessageContent.fromJson(
    message.kind,
    jsonDecode(message.contentJson!) as Map,
  );

  if (content is! MediaMessageContent) {
    Log.error('Content of ${message.messageId} is not media file.');
    await handleMediaError(message);
    return;
  }

  if (content.downloadToken == null) {
    Log.error('Download token not defined for ${message.messageId}.');
    await handleMediaError(message);
    return;
  }

  if (!force && !await isAllowedToDownload(content.isVideo)) {
    Log.warn(
      'Download blocked for ${message.messageId} because of network state.',
    );
    return;
  }

  final isBlocked = await protectDownload.protect<bool>(() async {
    final msg = await twonlyDB.messagesDao
        .getMessageByMessageId(message.messageId)
        .getSingleOrNull();

    if (msg == null) return true;

    if (msg.downloadState != DownloadState.pending) {
      Log.error(
        '${message.messageId} is already downloaded or is downloading.',
      );
      return true;
    }

    await twonlyDB.messagesDao.updateMessageByMessageId(
      message.messageId,
      const MessagesCompanion(
        downloadState: Value(DownloadState.downloading),
      ),
    );

    return false;
  });

  if (isBlocked) {
    Log.info('Download for ${message.messageId} already started.');
    return;
  }

  final downloadToken = uint8ListToHex(content.downloadToken!);

  final apiUrl =
      'http${apiService.apiSecure}://${apiService.apiHost}/api/download/$downloadToken';

  try {
    final task = DownloadTask(
      url: apiUrl,
      taskId: 'download_${message.messageId}',
      directory: 'media/received/',
      baseDirectory: BaseDirectory.applicationSupport,
      filename: '${message.messageId}.encrypted',
      priority: 0,
      retries: 10,
    );

    Log.info(
      'Got media file. Starting download: ${downloadToken.substring(0, 10)}',
    );

    try {
      await downloadFileFast(message.messageId, apiUrl);
    } catch (e) {
      Log.error('Fast download failed: $e');
      await FileDownloader().enqueue(task);
    }
  } catch (e) {
    Log.error('Exception during download: $e');
  }
}

Future<void> downloadFileFast(
  int messageId,
  String apiUrl,
) async {
  final directoryPath =
      '${(await getApplicationSupportDirectory()).path}/media/received/';
  final filename = '$messageId.encrypted';

  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    await directory.create(recursive: true);
  }

  final filePath = '${directory.path}/$filename';

  final response =
      await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    await File(filePath).writeAsBytes(response.bodyBytes);
    Log.info('Fast Download successful: $filePath');
    await handleDownloadStatusUpdateInternal(messageId, false);
    return;
  } else {
    if (response.statusCode == 404 || response.statusCode == 403) {
      await handleDownloadStatusUpdateInternal(messageId, true);
      return;
    }
    // can be tried again
    throw Exception('Fast download failed with status: ${response.statusCode}');
  }
}

Future<void> handleEncryptedFile(int messageId) async {
  final msg = await twonlyDB.messagesDao
      .getMessageByMessageId(messageId)
      .getSingleOrNull();
  if (msg == null) {
    Log.error('Not message for downloaded file found: $messageId');
    return;
  }

  final encryptedBytes = await readMediaFile(msg.messageId, 'encrypted');

  if (encryptedBytes == null) {
    Log.error('encrypted bytes are not found for ${msg.messageId}');
    return;
  }

  final content =
      MediaMessageContent.fromJson(jsonDecode(msg.contentJson!) as Map);

  try {
    final chacha20 = FlutterChacha20.poly1305Aead();
    final secretKeyData = SecretKeyData(content.encryptionKey!);

    final secretBox = SecretBox(
      encryptedBytes,
      nonce: content.encryptionNonce!,
      mac: Mac(content.encryptionMac!),
    );

    // try {
    final plaintextBytes =
        await chacha20.decrypt(secretBox, secretKey: secretKeyData);
    var imageBytes = Uint8List.fromList(plaintextBytes);

    if (content.isVideo) {
      final extractedBytes = extractUint8Lists(imageBytes);
      imageBytes = extractedBytes[0];
      await writeMediaFile(msg.messageId, 'mp4', extractedBytes[1]);
    }

    await writeMediaFile(msg.messageId, 'png', imageBytes);
    // } catch (e) {
    //   Log.error(
    //       "could not decrypt the media file in the second try. reporting error to user: $e");
    //   handleMediaError(msg);
    //   return;
    // }
  } catch (e) {
    Log.error('$e');

    /// legacy support
    final chacha20 = Xchacha20.poly1305Aead();
    final secretKeyData = SecretKeyData(content.encryptionKey!);

    final secretBox = SecretBox(
      encryptedBytes,
      nonce: content.encryptionNonce!,
      mac: Mac(content.encryptionMac!),
    );

    try {
      final plaintextBytes =
          await chacha20.decrypt(secretBox, secretKey: secretKeyData);
      var imageBytes = Uint8List.fromList(plaintextBytes);

      if (content.isVideo) {
        final extractedBytes = extractUint8Lists(imageBytes);
        imageBytes = extractedBytes[0];
        await writeMediaFile(msg.messageId, 'mp4', extractedBytes[1]);
      }

      await writeMediaFile(msg.messageId, 'png', imageBytes);
    } catch (e) {
      Log.error(
        'could not decrypt the media file in the second try. reporting error to user: $e',
      );
      await handleMediaError(msg);
      return;
    }
  }

  await twonlyDB.messagesDao.updateMessageByMessageId(
    msg.messageId,
    const MessagesCompanion(downloadState: Value(DownloadState.downloaded)),
  );

  Log.info('Download and decryption of ${msg.messageId} was successful');

  await deleteMediaFile(msg.messageId, 'encrypted');

  unawaited(apiService.downloadDone(content.downloadToken!));
}

Future<Uint8List?> getImageBytes(int mediaId) async {
  return readMediaFile(mediaId, 'png');
}

Future<File?> getVideoPath(int mediaId) async {
  final basePath = await getMediaFilePath(mediaId, 'received');
  return File('$basePath.mp4');
}

/// --- helper functions ---

Future<Uint8List?> readMediaFile(int mediaId, String type) async {
  final basePath = await getMediaFilePath(mediaId, 'received');
  final file = File('$basePath.$type');
  Log.info('Reading: $file');
  if (!file.existsSync()) {
    return null;
  }
  return file.readAsBytes();
}

Future<bool> existsMediaFile(int mediaId, String type) async {
  final basePath = await getMediaFilePath(mediaId, 'received');
  final file = File('$basePath.$type');
  return file.existsSync();
}

Future<void> writeMediaFile(int mediaId, String type, Uint8List data) async {
  final basePath = await getMediaFilePath(mediaId, 'received');
  final file = File('$basePath.$type');
  await file.writeAsBytes(data);
}

Future<void> deleteMediaFile(int mediaId, String type) async {
  final basePath = await getMediaFilePath(mediaId, 'received');
  final file = File('$basePath.$type');
  try {
    if (file.existsSync()) {
      await file.delete();
    }
  } catch (e) {
    Log.error('Error deleting: $e');
  }
}

Future<void> purgeReceivedMediaFiles() async {
  final basedir = await getApplicationSupportDirectory();
  final directory = Directory(join(basedir.path, 'media', 'received'));
  await purgeMediaFiles(directory);
}

Future<void> purgeMediaFiles(Directory directory) async {
  // Check if the directory exists
  if (directory.existsSync()) {
    // List all files in the directory
    final files = directory.listSync();

    // Iterate over each file
    for (final file in files) {
      // Get the filename
      final filename = file.uri.pathSegments.last;

      // Use a regular expression to extract the integer part
      final match = RegExp(r'(\d+)').firstMatch(filename);
      if (match != null) {
        // Parse the integer and add it to the list
        final fileId = int.parse(match.group(0)!);

        try {
          if (directory.path.endsWith('send')) {
            final messages =
                await twonlyDB.messagesDao.getMessagesByMediaUploadId(fileId);
            var canBeDeleted = true;

            for (final message in messages) {
              try {
                final content = MediaMessageContent.fromJson(
                  jsonDecode(message.contentJson!) as Map,
                );

                final oneDayAgo =
                    DateTime.now().subtract(const Duration(days: 1));
                final twoDaysAgo =
                    DateTime.now().subtract(const Duration(days: 1));

                if ((message.openedAt == null ||
                        oneDayAgo.isBefore(message.openedAt!)) &&
                    !message.errorWhileSending) {
                  canBeDeleted = false;
                } else if (message.mediaStored) {
                  if (!file.path.contains('.original.') &&
                      !file.path.contains('.encrypted')) {
                    canBeDeleted = false;
                  }
                }

                /// In case the image is not yet opened but successfully uploaded
                /// to the server preserve the image for two days in case of an receiving error will happen
                ///  and then delete them as well.
                if (message.acknowledgeByServer &&
                    twoDaysAgo.isAfter(message.sendAt)) {
                  // Preserve images which can be stored by the other person...
                  if (content.maxShowTime != gMediaShowInfinite) {
                    canBeDeleted = true;
                  }
                  // Encrypted or upload data can be removed when acknowledgeByServer
                  if (file.path.contains('.upload') ||
                      file.path.contains('.encrypted')) {
                    canBeDeleted = true;
                  }
                }
              } catch (e) {
                Log.error(e);
              }
            }
            if (canBeDeleted) {
              Log.info('purged media file ${file.path} ');
              file.deleteSync();
            }
          } else {
            final message = await twonlyDB.messagesDao
                .getMessageByMessageId(fileId)
                .getSingleOrNull();
            if ((message == null) ||
                (message.openedAt != null &&
                    !message.mediaStored &&
                    message.acknowledgeByServer) ||
                message.errorWhileSending) {
              file.deleteSync();
            }
          }
        } catch (e) {
          Log.error('$e');
        }
      }
    }
  }
}

// /data/user/0/eu.twonly.testing/files/media/received/27.encrypted
// /data/user/0/eu.twonly.testing/app_flutter/data/user/0/eu.twonly.testing/files/media/received/27.encrypted
