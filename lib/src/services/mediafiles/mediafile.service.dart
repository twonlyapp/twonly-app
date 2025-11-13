import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/compression.service.dart';
import 'package:twonly/src/services/mediafiles/thumbnail.service.dart';
import 'package:twonly/src/utils/log.dart';

class MediaFileService {
  MediaFileService(this.mediaFile, {required this.applicationSupportDirectory});
  MediaFile mediaFile;

  final Directory applicationSupportDirectory;

  static Future<MediaFileService> fromMedia(MediaFile media) async {
    return MediaFileService(
      media,
      applicationSupportDirectory: await getApplicationSupportDirectory(),
    );
  }

  static Future<MediaFileService?> fromMediaId(String mediaId) async {
    final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(mediaId);
    if (mediaFile == null) return null;
    return MediaFileService(
      mediaFile,
      applicationSupportDirectory: await getApplicationSupportDirectory(),
    );
  }

  static Future<void> purgeTempFolder() async {
    final tempDirectory = MediaFileService._buildDirectoryPath(
      'tmp',
      await getApplicationSupportDirectory(),
    );

    final files = tempDirectory.listSync();
    for (final file in files) {
      final mediaId = basename(file.path).split('.').first;

      var delete = true;

      final service = await MediaFileService.fromMediaId(mediaId);

      if (service == null) {
        Log.error(
          'Purging media file, as it is not in the database $mediaId.',
        );
      } else {
        if (service.mediaFile.isDraftMedia) {
          delete = false;
        }

        final messages =
            await twonlyDB.messagesDao.getMessagesByMediaId(mediaId);

        // in case messages in empty the file will be deleted, as delete is true by default

        for (final message in messages) {
          if (message.senderId == null) {
            // Media was send by me
            if (message.openedAt == null) {
              // Message was not yet opened from all persons, so wait...
              delete = false;
            } else if (service.mediaFile.requiresAuthentication ||
                service.mediaFile.displayLimitInMilliseconds != null) {
              // Message was opened by all persons, and they can not reopen the image.
              // delete = true; // do not overwrite a previous delete = false
              // this is just to make it easier to understand :)
            } else if (message.openedAt!
                .isAfter(DateTime.now().subtract(const Duration(days: 2)))) {
              // Message was opened by all persons, as it can be reopened and then stored by a other person keep it for
              // two day just to be sure.
              delete = false;
            }
          } else {
            // this media was received from another person
            if (message.openedAt == null) {
              // Message was not yet opened, so do not remove it.
              delete = false;
            }
            if (service.mediaFile.type == MediaType.audio) {
              delete = false; // do not delete voice messages
            }
          }
        }
      }

      if (delete) {
        Log.info('Purging media file $mediaId');
        file.deleteSync();
      }
    }
  }

  Future<void> updateFromDB() async {
    final updated =
        await twonlyDB.mediaFilesDao.getMediaFileById(mediaFile.mediaId);
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
        displayLimitInMilliseconds:
            requiresAuthentication ? const Value(12000) : const Value.absent(),
      ),
    );
    await updateFromDB();
  }

  Future<void> createThumbnail() async {
    if (!storedPath.existsSync()) {
      Log.error('Could not create Thumbnail as stored media does not exists.');
      return;
    }
    switch (mediaFile.type) {
      case MediaType.gif:
      case MediaType.audio:
      case MediaType.image:
        // all images are already compress..
        break;
      case MediaType.video:
        await createThumbnailsForVideo(storedPath, thumbnailPath);
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

  bool get imagePreviewAvailable =>
      thumbnailPath.existsSync() || storedPath.existsSync();

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
    } else {
      Log.error(
        'Could not store image neither as tempPath does not exists.',
      );
    }
    unawaited(createThumbnail());
    await updateFromDB();
  }

  static Directory _buildDirectoryPath(
    String directory,
    Directory applicationSupportDirectory,
  ) {
    final mediaBaseDir = Directory(
      join(
        applicationSupportDirectory.path,
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
    final mediaBaseDir =
        _buildDirectoryPath(directory, applicationSupportDirectory);
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
}
