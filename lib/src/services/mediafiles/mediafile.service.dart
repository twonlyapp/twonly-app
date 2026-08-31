import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart'
    show MemoriesCloudService;
import 'package:twonly/src/utils/log.dart';

class MediaFileService {
  MediaFileService(this._mediaFile);
  MediaFile _mediaFile;

  /// Built file paths, keyed by the `_buildFilePath` arguments. Resolving a
  /// path is pure string work plus a directory check, but the getters below are
  /// read from `build()` methods, so the result is memoised per instance.
  final Map<String, File> _pathCache = {};

  MediaFile get mediaFile => _mediaFile;

  set mediaFile(MediaFile value) {
    if (value.mediaId != _mediaFile.mediaId || value.type != _mediaFile.type) {
      _pathCache.clear();
    }
    _mediaFile = value;
  }

  static Future<MediaFileService?> fromMediaId(String mediaId) async {
    final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(mediaId);
    if (mediaFile == null) return null;
    return MediaFileService(
      mediaFile,
    );
  }

  /// Rust decides which temporary media a message is finished with; this only
  /// triggers the sweep.
  static Future<void> purgeTempFolder() => RustApi.purgeMediaTempFolder();

  Future<void> updateFromDB() async {
    final updated = await twonlyDB.mediaFilesDao.getMediaFileById(
      mediaFile.mediaId,
    );
    if (updated != null) {
      mediaFile = updated;
    }
  }

  Future<void> setDisplayLimit(int? displayLimitInMilliseconds) async {
    await RustApi.setMediaDisplayLimit(
      mediaId: mediaFile.mediaId,
      displayLimitInMilliseconds: displayLimitInMilliseconds,
    );
    await updateFromDB();
  }

  bool get removeAudio => mediaFile.removeAudio ?? false;

  Future<void> toggleRemoveAudio() async {
    await RustApi.toggleMediaRemoveAudio(mediaId: mediaFile.mediaId);
    await updateFromDB();
  }

  Future<void> setRequiresAuth(bool requiresAuthentication) async {
    await RustApi.setMediaRequiresAuthentication(
      mediaId: mediaFile.mediaId,
      requiresAuthentication: requiresAuthentication,
    );
    await updateFromDB();
  }

  /// Rust renders thumbnails, including the video frame grab, so this only
  /// asks it to refresh the one for this media file.
  Future<void> createThumbnail() async {
    await RustApi.mediaStepFinished(
      mediaId: mediaFile.mediaId,
      kind: 'thumbnail',
    );
    await updateFromDB();
  }

  /// Removes every file of this media item. The row is kept so a message that
  /// still references it keeps rendering.
  Future<void> fullMediaRemoval() =>
      RustApi.removeMediaFiles(mediaId: mediaFile.mediaId);

  // Media was send with unlimited display limit time and without auth required
  // and the temp media file still exists, then the media file can be reopened again...
  bool get canBeOpenedAgain =>
      !mediaFile.requiresAuthentication &&
      mediaFile.displayLimitInMilliseconds == null &&
      tempPath.existsSync();

  bool get imagePreviewAvailable =>
      mediaFile.hasThumbnail ||
      mediaFile.type == MediaType.audio ||
      ((mediaFile.type == MediaType.image || mediaFile.type == MediaType.gif) &&
          mediaFile.stored);

  /// Rust keeps the local copy, exports it to the gallery when the user asked
  /// for that, and recomputes size, hash and thumbnail state from the file it
  /// wrote.
  Future<void> storeMediaFile() async {
    Log.info('Storing media file ${mediaFile.mediaId}');
    await RustApi.storeMedia(mediaId: mediaFile.mediaId);
    await updateFromDB();
    await MemoriesCloudService().checkUploads();
  }

  /// Recomputes the size and content hash Rust keeps for the stored file.
  Future<void> refreshStoredMetadata() async {
    await RustApi.mediaStepFinished(mediaId: mediaFile.mediaId, kind: 'stored');
    await updateFromDB();
  }

  /// Exports this media file to the user's photo library.
  Future<void> saveToGallery() =>
      RustApi.saveMediaToGallery(mediaId: mediaFile.mediaId);

  /// Trimming transparent borders, and the size, hash and preview derived from
  /// the result, are all Rust-owned.
  Future<void> cropTransparentBorders() async {
    await RustApi.cropMediaTransparentBorders(mediaId: mediaFile.mediaId);
    await updateFromDB();
  }

  /// Directories this isolate has already created. The media folders are only
  /// ever created, never removed behind our back, so the `existsSync` probe
  /// only has to run once per directory instead of on every path lookup.
  static final Set<String> _ensuredDirectories = {};

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
    if (_ensuredDirectories.add(mediaBaseDir.path)) {
      if (!mediaBaseDir.existsSync()) {
        mediaBaseDir.createSync(recursive: true);
      }
    }
    return mediaBaseDir;
  }

  File _buildFilePath(
    String directory, {
    String namePrefix = '',
    String extensionParam = '',
  }) {
    final cacheKey = '$directory|$namePrefix|$extensionParam';
    final cached = _pathCache[cacheKey];
    if (cached != null) return cached;
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
    return _pathCache[cacheKey] = File(
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
  File get overlayImagePath => _buildFilePath(
    'tmp',
    namePrefix: '.overlay',
    extensionParam: 'png',
  );
}
