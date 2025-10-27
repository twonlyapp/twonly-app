import 'dart:async';
import 'dart:io';
import 'package:background_downloader/background_downloader.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:mutex/mutex.dart';
import 'package:path/path.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

Future<void> tryDownloadAllMediaFiles({bool force = false}) async {
  // This is called when WebSocket is newly connected, so allow all downloads to be restarted.
  final mediaFiles =
      await twonlyDB.mediaFilesDao.getAllMediaFilesPendingDownload();

  for (final mediaFile in mediaFiles) {
    await startDownloadMedia(mediaFile, force);
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

Future<bool> isAllowedToDownload({required bool isVideo}) async {
  final connectivityResult = await Connectivity().checkConnectivity();

  final options = gUser.autoDownloadOptions ?? defaultAutoDownloadOptions;

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
  final mediaId = update.task.taskId.replaceAll('download_', '');
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
    Log.info('Got ${update.status} for $mediaId');
    return;
  }

  if (failed) {
    Log.error('Background media upload failed: ${update.status}');
    await requestMediaReupload(mediaId);
  } else {
    await handleEncryptedFile(mediaId);
  }
}

Mutex protectDownload = Mutex();

Future<void> startDownloadMedia(MediaFile media, bool force) async {
  final mediaService = await MediaFileService.fromMedia(media);

  if (mediaService.encryptedPath.existsSync()) {
    await handleEncryptedFile(media.mediaId);
    return;
  }

  if (!force &&
      !await isAllowedToDownload(isVideo: media.type == MediaType.video)) {
    Log.warn(
      'Download blocked for ${media.mediaId} because of network state.',
    );
    return;
  }

  final isBlocked = await protectDownload.protect<bool>(() async {
    final msg = await twonlyDB.mediaFilesDao.getMediaFileById(media.mediaId);

    if (msg == null || msg.downloadState != DownloadState.pending) {
      return true;
    }

    await twonlyDB.mediaFilesDao.updateMedia(
      msg.mediaId,
      const MediaFilesCompanion(
        downloadState: Value(DownloadState.downloading),
      ),
    );

    return false;
  });

  if (isBlocked) {
    Log.info('Download for ${media.mediaId} already started.');
    return;
  }

  if (media.downloadToken == null) {
    Log.info('Download token for ${media.mediaId} not found.');
    return;
  }

  final downloadToken = uint8ListToHex(media.downloadToken!);

  final apiUrl =
      'http${apiService.apiSecure}://${apiService.apiHost}/api/download/$downloadToken';

  try {
    final task = DownloadTask(
      url: apiUrl,
      taskId: 'download_${media.mediaId}',
      directory: mediaService.encryptedPath.parent.path,
      baseDirectory: BaseDirectory.root,
      filename: basename(mediaService.encryptedPath.path),
      priority: 0,
      retries: 10,
    );

    Log.info(
      'Downloading ${media.mediaId} to ${mediaService.encryptedPath}',
    );

    try {
      await downloadFileFast(media, apiUrl, mediaService.encryptedPath);
    } catch (e) {
      Log.error('Fast download failed: $e');
      await FileDownloader().enqueue(task);
    }
  } catch (e) {
    Log.error('Exception during download: $e');
  }
}

Future<void> downloadFileFast(
  MediaFile media,
  String apiUrl,
  File filePath,
) async {
  final response =
      await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 10));

  if (response.statusCode == 200) {
    await filePath.writeAsBytes(response.bodyBytes);
    Log.info('Fast Download successful: $filePath');
    await handleEncryptedFile(media.mediaId);
    return;
  } else {
    if (response.statusCode == 404 ||
        response.statusCode == 403 ||
        response.statusCode == 400) {
      Log.error(
        'Got ${response.statusCode} from server. Requesting upload again',
      );
      // Message was deleted from the server. Requesting it again from the sender to upload it again...
      await requestMediaReupload(media.mediaId);
      return;
    }
    // Will be tried again using the slow method...
    throw Exception('Fast download failed with status: ${response.statusCode}');
  }
}

Future<void> requestMediaReupload(String mediaId) async {
  final messages = await twonlyDB.messagesDao.getMessagesByMediaId(mediaId);
  if (messages.length != 1 || messages.first.senderId == null) {
    Log.error(
      'Media file has none or more than one sender. That is not possible',
    );
    return;
  }

  await sendCipherText(
    messages.first.senderId!,
    EncryptedContent(
      mediaUpdate: EncryptedContent_MediaUpdate(
        type: EncryptedContent_MediaUpdate_Type.DECRYPTION_ERROR,
        targetMessageId: messages.first.messageId,
      ),
    ),
  );

  await twonlyDB.mediaFilesDao.updateMedia(
    mediaId,
    const MediaFilesCompanion(
      downloadState: Value(DownloadState.reuploadRequested),
    ),
  );
}

Future<void> handleEncryptedFile(String mediaId) async {
  final mediaService = await MediaFileService.fromMediaId(mediaId);
  if (mediaService == null) {
    Log.error('Media file $mediaId not found in database.');
    return;
  }

  await twonlyDB.mediaFilesDao.updateMedia(
    mediaId,
    const MediaFilesCompanion(
      downloadState: Value(DownloadState.downloaded),
    ),
  );

  late Uint8List encryptedBytes;
  try {
    encryptedBytes = await mediaService.encryptedPath.readAsBytes();
  } catch (e) {
    Log.error('Could not read encrypted media file: $mediaId. $e');
    await requestMediaReupload(mediaId);
    return;
  }

  try {
    final chacha20 = FlutterChacha20.poly1305Aead();
    final secretKeyData = SecretKeyData(mediaService.mediaFile.encryptionKey!);

    final secretBox = SecretBox(
      encryptedBytes,
      nonce: mediaService.mediaFile.encryptionNonce!,
      mac: Mac(mediaService.mediaFile.encryptionMac!),
    );

    final plaintextBytes =
        await chacha20.decrypt(secretBox, secretKey: secretKeyData);

    final rawMediaBytes = Uint8List.fromList(plaintextBytes);

    await mediaService.tempPath.writeAsBytes(rawMediaBytes);
  } catch (e) {
    Log.error(
      'Could not decrypt the media file. Requesting a new upload.',
    );
    await requestMediaReupload(mediaId);
    return;
  }

  await twonlyDB.mediaFilesDao.updateMedia(
    mediaId,
    const MediaFilesCompanion(
      downloadState: Value(DownloadState.ready),
    ),
  );

  Log.info('Decryption of $mediaId was successful');

  mediaService.encryptedPath.deleteSync();

  unawaited(apiService.downloadDone(mediaService.mediaFile.downloadToken!));
}
