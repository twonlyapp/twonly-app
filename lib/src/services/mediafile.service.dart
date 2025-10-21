import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/thumbnail.service.dart';
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

  Future<void> updateFromDB() async {
    final updated =
        await twonlyDB.mediaFilesDao.getMediaFileById(mediaFile.mediaId);
    if (updated != null) {
      mediaFile = updated;
    }
  }

  Future<void> createThumbnail() async {
    if (!storedPath.existsSync()) {
      Log.error('Could not create Thumbnail as stored media does not exists.');
      return;
    }
    switch (mediaFile.type) {
      case MediaType.image:
        await createThumbnailsForImage(storedPath, thumbnailPath);
      case MediaType.video:
        await createThumbnailsForVideo(storedPath, thumbnailPath);
      case MediaType.gif:
        Log.error('Thumbnail for .gif is not implemented yet');
    }
  }

  void fullMediaRemoval() {
    if (tempPath.existsSync()) {
      tempPath.deleteSync();
    }
    if (encryptedPath.existsSync()) {
      encryptedPath.deleteSync();
    }
    if (storedPath.existsSync()) {
      storedPath.deleteSync();
    }
    if (thumbnailPath.existsSync()) {
      thumbnailPath.deleteSync();
    }
  }

  Future<void> storeMediaFile() async {
    Log.info('Storing media file ${mediaFile.mediaId}');
    await twonlyDB.mediaFilesDao.updateMedia(
      mediaFile.mediaId,
      const MediaFilesCompanion(
        stored: Value(true),
      ),
    );
    await tempPath.copy(storedPath.path);
    await updateFromDB();
  }

  File _buildFilePath(
    String directory, {
    String namePrefix = '',
    String extensionParam = '',
  }) {
    final mediaBaseDir = Directory(join(
      applicationSupportDirectory.path,
      'mediafiles',
      directory,
    ));
    if (!mediaBaseDir.existsSync()) {
      mediaBaseDir.createSync(recursive: true);
    }
    var extension = extensionParam;
    if (extension == '') {
      switch (mediaFile.type) {
        case MediaType.image:
          extension = 'webp';
        case MediaType.video:
          extension = 'mp4';
        case MediaType.gif:
          extension = 'gif';
      }
    }
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
}
