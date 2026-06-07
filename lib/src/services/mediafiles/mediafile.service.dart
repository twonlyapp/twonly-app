import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/compression.service.dart';
import 'package:twonly/src/services/mediafiles/thumbnail.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

class MediaFileService {
  MediaFileService(this.mediaFile);
  MediaFile mediaFile;

  static Future<MediaFileService?> fromMediaId(String mediaId) async {
    final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(mediaId);
    if (mediaFile == null) return null;
    return MediaFileService(
      mediaFile,
    );
  }

  static Future<void> purgeTempFolder() async {
    try {
      final tempDirectory = MediaFileService.buildDirectoryPath(
        'tmp',
        AppEnvironment.supportDir,
      );

      final files = tempDirectory.listSync();
      if (files.isEmpty) return;

      final mediaIdToFile = <String, List<FileSystemEntity>>{};
      for (final file in files) {
        final mediaId = basename(file.path).split('.').first;
        mediaIdToFile.putIfAbsent(mediaId, () => []).add(file);
      }

      final mediaIds = mediaIdToFile.keys.toList();

      // Bulk fetch media files and messages
      final allMediaFiles = await twonlyDB.mediaFilesDao.getMediaFilesByIds(
        mediaIds,
      );
      final allMessages = await twonlyDB.messagesDao.getMessagesByMediaIds(
        mediaIds,
      );

      final mediaFileMap = {for (final m in allMediaFiles) m.mediaId: m};
      final messageMap = <String, List<Message>>{};
      for (final msg in allMessages) {
        if (msg.mediaId != null) {
          messageMap.putIfAbsent(msg.mediaId!, () => []).add(msg);
        }
      }

      for (final mediaId in mediaIds) {
        // in case the mediaID is unknown the file will be deleted
        var delete = true;

        final mediaFile = mediaFileMap[mediaId];

        if (mediaFile != null) {
          if (mediaFile.isDraftMedia) {
            delete = false;
          }

          // Never purge temp files while an upload is still in progress.
          // The temp file is actively needed for encryption/upload.
          if (mediaFile.uploadState != UploadState.uploaded &&
              mediaFile.uploadState != UploadState.fileLimitReached) {
            delete = false;
          }

          final messages = messageMap[mediaId] ?? [];

          // in case messages in empty the file will be deleted, as delete is true by default

          for (final message in messages) {
            if (mediaFile.type == MediaType.audio) {
              delete = false; // do not delete voice messages
            }

            if (message.openedAt == null) {
              // Message was not yet opened from all persons, so wait...
              delete = false;
            } else if (message.openedAt!.isAfter(
              clock.now().subtract(const Duration(minutes: 3)),
            )) {
              // When the message was opened in the last two minutes, do not purge.
              // Bug: When the user opens an image immediately after starting the app, there is a race condition:
              //      The message is marked as opened, but then purgeTempFolder is run
              //      (it is unawaited) and deletes the file. Thi gives a grace period:
              //      The image must have been opened within the last two minutes, otherwise do not delete it.
              delete = false;
            } else if (mediaFile.requiresAuthentication ||
                mediaFile.displayLimitInMilliseconds != null) {
              // Message was opened by all persons, and they can not reopen the image.
            } else if (message.openedAt!.isAfter(
              clock.now().subtract(const Duration(days: 2)),
            )) {
              // In case the image was opened, but send with unlimited time or no authentication.
              if (message.senderId == null) {
                delete = false;
              } else {
                // Check weather the image was send in a group. Then the images is preserved for two days in case another person stores the image.
                // This also allows to reopen this image for two days.
                final group = await twonlyDB.groupsDao.getGroup(
                  message.groupId,
                );
                if (group != null && !group.isDirectChat) {
                  delete = false;
                }
              }
              // In case the app was send in a direct chat, then it can be deleted.
            }
          }
        }

        if (delete) {
          Log.info('Purging media file $mediaId');
          final filesToPurge = mediaIdToFile[mediaId] ?? [];
          for (final file in filesToPurge) {
            try {
              if (file.existsSync()) {
                file.deleteSync();
              }
            } catch (e) {
              Log.error('Error deleting file ${file.path}: $e');
            }
          }
        }
      }
    } catch (e) {
      Log.error('Error in purgeTempFolder: $e');
    }
  }

  Future<void> updateFromDB() async {
    final updated = await twonlyDB.mediaFilesDao.getMediaFileById(
      mediaFile.mediaId,
    );
    if (updated != null) {
      mediaFile = updated;
    }
  }

  Future<void> setDisplayLimit(int? displayLimitInMilliseconds) async {
    await twonlyDB.mediaFilesDao.updateMedia(
      mediaFile.mediaId,
      MediaFilesCompanion(
        displayLimitInMilliseconds: Value(displayLimitInMilliseconds),
      ),
    );
    await updateFromDB();
  }

  bool get removeAudio => mediaFile.removeAudio ?? false;

  Future<void> toggleRemoveAudio() async {
    // var removeAudio = false;
    // if (mediaFile.removeAudio != null) {
    //   removeAudio = !mediaFile.removeAudio!;
    // }
    await twonlyDB.mediaFilesDao.updateMedia(
      mediaFile.mediaId,
      MediaFilesCompanion(
        removeAudio: Value(!removeAudio),
      ),
    );
    await updateFromDB();
  }

  Future<void> setUploadState(UploadState uploadState) async {
    await twonlyDB.mediaFilesDao.updateMedia(
      mediaFile.mediaId,
      MediaFilesCompanion(
        uploadState: Value(uploadState),
      ),
    );
    await updateFromDB();
  }

  Future<void> setEncryptedMac(Uint8List encryptionMac) async {
    await twonlyDB.mediaFilesDao.updateMedia(
      mediaFile.mediaId,
      MediaFilesCompanion(
        encryptionMac: Value(encryptionMac),
      ),
    );
    await updateFromDB();
  }

  Future<void> setRequiresAuth(bool requiresAuthentication) async {
    await twonlyDB.mediaFilesDao.updateMedia(
      mediaFile.mediaId,
      MediaFilesCompanion(
        requiresAuthentication: Value(requiresAuthentication),
        displayLimitInMilliseconds: requiresAuthentication
            ? const Value(12000)
            : const Value.absent(),
      ),
    );
    await updateFromDB();
  }

  Future<void> createThumbnail() async {
    if (!storedPath.existsSync() || storedPath.lengthSync() == 0) {
      if (storedPath.existsSync() && storedPath.lengthSync() == 0) {
        try {
          storedPath.deleteSync();
        } catch (_) {}
      }
      if (mediaFile.stored &&
          mediaFile.createdAt.isBefore(
            clock.now().subtract(const Duration(days: 30)),
          )) {
        // media files does not exists any more so also delete the database entry
        await twonlyDB.mediaFilesDao.deleteMediaFile(mediaFile.mediaId);
        fullMediaRemoval();
      }
      return;
    }
    var success = false;
    switch (mediaFile.type) {
      case MediaType.gif:
        success = await createThumbnailsForGif(storedPath, thumbnailPath);
      case MediaType.image:
        success = await createThumbnailsForImage(storedPath, thumbnailPath);
      case MediaType.video:
        success = await createThumbnailsForVideo(storedPath, thumbnailPath);
      case MediaType.audio:
        break;
    }

    if (success) {
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(hasThumbnail: Value(true)),
      );
      await updateFromDB();
    }
  }

  Future<void> compressMedia() async {
    if (!originalPath.existsSync()) {
      Log.error('Could not compress as original media does not exists.');
      return;
    }

    switch (mediaFile.type) {
      case MediaType.image:
        await compressImage(originalPath, tempPath);
      case MediaType.video:
        await compressAndOverlayVideo(this);
      case MediaType.audio:
      case MediaType.gif:
        originalPath.copySync(tempPath.path);
    }
  }

  void fullMediaRemoval() {
    final pathsToRemove = [
      tempPath,
      encryptedPath,
      originalPath,
      storedPath,
      thumbnailPath,
      uploadRequestPath,
    ];

    for (final path in pathsToRemove) {
      if (path.existsSync()) {
        path.deleteSync();
      }
    }
  }

  // Media was send with unlimited display limit time and without auth required
  // and the temp media file still exists, then the media file can be reopened again...
  bool get canBeOpenedAgain =>
      !mediaFile.requiresAuthentication &&
      mediaFile.displayLimitInMilliseconds == null &&
      tempPath.existsSync();

  bool get imagePreviewAvailable =>
      mediaFile.hasThumbnail ||
      (thumbnailPath.existsSync() && thumbnailPath.lengthSync() > 0) ||
      mediaFile.type == MediaType.audio ||
      ((mediaFile.type == MediaType.image || mediaFile.type == MediaType.gif) &&
          storedPath.existsSync() && storedPath.lengthSync() > 0);

  Future<void> storeMediaFile() async {
    Log.info('Storing media file ${mediaFile.mediaId}');
    await twonlyDB.mediaFilesDao.updateMedia(
      mediaFile.mediaId,
      const MediaFilesCompanion(
        stored: Value(true),
      ),
    );

    if (originalPath.existsSync() && !tempPath.existsSync()) {
      await compressMedia();
    }
    if (tempPath.existsSync()) {
      await tempPath.copy(storedPath.path);
      if (userService.currentUser.storeMediaFilesInGallery) {
        if (mediaFile.type == MediaType.video) {
          await saveVideoToGallery(storedPath.path);
        } else {
          await saveImageToGallery(
            storedPath.readAsBytesSync(),
            createdAt: mediaFile.createdAt,
          );
        }
      }
    } else {
      Log.error(
        'Could not store image neither as ${tempPath.path} does not exists.',
      );
    }
    unawaited(createThumbnail());
    await calculateAndSaveSize();
    await hashMediaFile();
    // updateFromDb is done in hashStoredMedia()
  }

  Future<void> calculateAndSaveSize() async {
    if (storedPath.existsSync()) {
      final size = storedPath.lengthSync();
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        MediaFilesCompanion(
          sizeInBytes: Value(size),
        ),
      );
      await updateFromDB();
    }
  }

  Future<void> hashMediaFile() async {
    late final List<int> checksum;
    if (storedPath.existsSync()) {
      checksum = await sha256File(storedPath);
    } else if (tempPath.existsSync()) {
      checksum = await sha256File(tempPath);
    } else {
      return;
    }
    await twonlyDB.mediaFilesDao.updateMedia(
      mediaFile.mediaId,
      MediaFilesCompanion(
        storedFileHash: Value(Uint8List.fromList(checksum)),
      ),
    );
    await updateFromDB();
  }

  static Directory buildDirectoryPath(
    String directory,
    String applicationSupportDirectory,
  ) {
    final mediaBaseDir = Directory(
      join(
        applicationSupportDirectory,
        'mediafiles',
        directory,
      ),
    );
    if (!mediaBaseDir.existsSync()) {
      mediaBaseDir.createSync(recursive: true);
    }
    return mediaBaseDir;
  }

  File _buildFilePath(
    String directory, {
    String namePrefix = '',
    String extensionParam = '',
  }) {
    var extension = extensionParam;
    if (extension == '') {
      switch (mediaFile.type) {
        case MediaType.image:
          extension = 'webp';
        case MediaType.video:
          extension = 'mp4';
        case MediaType.gif:
          extension = 'gif';
        case MediaType.audio:
          extension = 'm4a';
      }
    }
    final mediaBaseDir = buildDirectoryPath(
      directory,
      AppEnvironment.supportDir,
    );
    return File(
      join(mediaBaseDir.path, '${mediaFile.mediaId}$namePrefix.$extension'),
    );
  }

  File get tempPath => _buildFilePath('tmp');
  File get storedPath => _buildFilePath('stored');
  File get thumbnailPath => _buildFilePath(
    'stored',
    namePrefix: '.thumbnail',
    extensionParam: 'webp',
  );
  File get encryptedPath => _buildFilePath(
    'tmp',
    namePrefix: '.encrypted',
  );
  File get uploadRequestPath => _buildFilePath(
    'tmp',
    namePrefix: '.upload',
  );
  File get originalPath => _buildFilePath(
    'tmp',
    namePrefix: '.original',
  );
  File get ffmpegOutputPath => _buildFilePath(
    'tmp',
    namePrefix: '.ffmpeg',
  );
  File get overlayImagePath => _buildFilePath(
    'tmp',
    namePrefix: '.overlay',
    extensionParam: 'png',
  );

  Future<void> cropTransparentBorders() async {
    if (mediaFile.type != MediaType.image) {
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(hasCropAnalyzed: Value(true)),
      );
      return;
    }

    if (!storedPath.existsSync() || storedPath.lengthSync() == 0) {
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(hasCropAnalyzed: Value(true)),
      );
      return;
    }

    try {
      final bytes = await storedPath.readAsBytes();
      final result = await compute(_processImageCrop, bytes);

      if (result.isCropped && result.pngBytes != null) {
        try {
          final webpBytes = await FlutterImageCompress.compressWithList(
            result.pngBytes!,
            format: CompressFormat.webp,
            quality: 90,
          );
          
          if (webpBytes.isNotEmpty) {
            await storedPath.writeAsBytes(webpBytes);
          } else {
            Log.warn('WebP compression returned empty, falling back to PNG');
            await storedPath.writeAsBytes(result.pngBytes!);
          }
        } catch (e) {
          Log.error('Error compressing to WebP, falling back to PNG: $e');
          await storedPath.writeAsBytes(result.pngBytes!);
        }

        if (thumbnailPath.existsSync()) {
          await thumbnailPath.delete();
        }
        await createThumbnail();
        final checksum = await sha256File(storedPath);
        await twonlyDB.mediaFilesDao.updateMedia(
          mediaFile.mediaId,
          MediaFilesCompanion(
            hasCropAnalyzed: const Value(true),
            storedFileHash: Value(Uint8List.fromList(checksum)),
          ),
        );
        await updateFromDB();
        return;
      }

      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(hasCropAnalyzed: Value(true)),
      );
      await updateFromDB();
    } catch (e) {
      Log.error(
        'Error auto-cropping transparent borders for mediaId ${mediaFile.mediaId}: $e',
      );
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaFile.mediaId,
        const MediaFilesCompanion(hasCropAnalyzed: Value(true)),
      );
      await updateFromDB();
    }
  }
}

class _CropResult {
  const _CropResult(this.pngBytes, this.isCropped);
  final Uint8List? pngBytes;
  final bool isCropped;
}

_CropResult _processImageCrop(Uint8List bytes) {
  final image = img.decodeImage(bytes);
  if (image == null) return const _CropResult(null, false);

  var minY = 0;
  var maxY = image.height - 1;
  var minX = 0;
  var maxX = image.width - 1;

  var found = false;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 10) {
        minY = y;
        found = true;
        break;
      }
    }
    if (found) break;
  }

  found = false;
  for (var y = image.height - 1; y >= minY; y--) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a > 10) {
        maxY = y;
        found = true;
        break;
      }
    }
    if (found) break;
  }

  found = false;
  for (var x = 0; x < image.width; x++) {
    for (var y = minY; y <= maxY; y++) {
      if (image.getPixel(x, y).a > 10) {
        minX = x;
        found = true;
        break;
      }
    }
    if (found) break;
  }

  found = false;
  for (var x = image.width - 1; x >= minX; x--) {
    for (var y = minY; y <= maxY; y++) {
      if (image.getPixel(x, y).a > 10) {
        maxX = x;
        found = true;
        break;
      }
    }
    if (found) break;
  }

  final newWidth = maxX - minX + 1;
  final newHeight = maxY - minY + 1;

  if (minY > 0 ||
      maxY < image.height - 1 ||
      minX > 0 ||
      maxX < image.width - 1) {
    if (newWidth > 10 && newHeight > 10) {
      final cropped = img.copyCrop(
        image,
        x: minX,
        y: minY,
        width: newWidth,
        height: newHeight,
      );
      final pngBytes = img.encodePng(cropped);
      return _CropResult(pngBytes, true);
    }
  }

  return const _CropResult(null, false);
}
