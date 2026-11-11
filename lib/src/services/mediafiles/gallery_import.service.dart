import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:exif/exif.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/services/android_photo_picker.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';

/// Something the user picked to import.
sealed class GalleryImportSource {
  const GalleryImportSource();
}

/// An asset from the photo library (iOS, or Android via `photo_manager`).
final class GalleryAssetSource extends GalleryImportSource {
  const GalleryAssetSource(this.asset);
  final AssetEntity asset;
}

/// A content URI returned by the Android system photo picker.
final class AndroidUriSource extends GalleryImportSource {
  const AndroidUriSource(this.uri);
  final String uri;
}

@immutable
class GalleryImportProgress {
  const GalleryImportProgress({
    required this.total,
    this.imported = 0,
    this.failed = 0,
    this.cancelled = false,
    this.finished = false,
  });

  final int total;
  final int imported;
  final int failed;

  /// The user asked to stop; items already in flight still complete.
  final bool cancelled;
  final bool finished;

  int get processed => imported + failed;
  double get fraction => total == 0 ? 1 : processed / total;

  GalleryImportProgress copyWith({
    int? imported,
    int? failed,
    bool? cancelled,
    bool? finished,
  }) => GalleryImportProgress(
    total: total,
    imported: imported ?? this.imported,
    failed: failed ?? this.failed,
    cancelled: cancelled ?? this.cancelled,
    finished: finished ?? this.finished,
  );
}

/// Imports gallery items into twonly with several items in flight at once.
///
/// Reading a file out of the photo library, hashing it and parsing its EXIF
/// data run in parallel (the CPU-heavy parts in background isolates), so the
/// Rust thumbnail step — which only renders one preview at a time — is no
/// longer waiting on the slow Dart work in front of it.
class GalleryImportJob {
  GalleryImportJob(this.sources)
    : _progress = GalleryImportProgress(total: sources.length);

  /// Enough to keep reading, hashing and thumbnail rendering overlapped
  /// without decoding many full-resolution photos at the same time.
  static final int concurrency = Platform.numberOfProcessors.clamp(2, 4);

  final List<GalleryImportSource> sources;

  /// Called on every progress change.
  void Function(GalleryImportProgress progress)? onProgress;

  GalleryImportProgress _progress;
  GalleryImportProgress get progress => _progress;

  /// Content hashes this run already handled, so the same picture picked
  /// twice is not inserted twice by two parallel workers.
  final Set<String> _claimedHashes = {};

  Future<GalleryImportProgress>? _run;

  void _update(GalleryImportProgress next) {
    _progress = next;
    onProgress?.call(next);
  }

  /// Stops picking up new items. Items already being imported still finish
  /// so no half-written media file is left behind.
  void cancel() {
    if (_progress.cancelled || _progress.finished) return;
    _update(_progress.copyWith(cancelled: true));
  }

  Future<GalleryImportProgress> run() => _run ??= _runAll();

  Future<GalleryImportProgress> _runAll() async {
    Directory? scratch;
    if (sources.any((s) => s is AndroidUriSource)) {
      final temp = await getTemporaryDirectory();
      scratch = await Directory(
        p.join(temp.path, 'gallery_import'),
      ).create(recursive: true).then((dir) => dir.createTemp());
    }

    var next = 0;
    Future<void> worker() async {
      while (!_progress.cancelled && next < sources.length) {
        final index = next++;
        var imported = false;
        try {
          imported = await _importOne(sources[index], scratch, index);
        } catch (e) {
          Log.error('Gallery import of item $index failed: $e');
        }
        _update(
          imported
              ? _progress.copyWith(imported: _progress.imported + 1)
              : _progress.copyWith(failed: _progress.failed + 1),
        );
      }
    }

    try {
      await Future.wait([
        for (var i = 0; i < min(concurrency, sources.length); i++) worker(),
      ]);
    } finally {
      try {
        await scratch?.delete(recursive: true);
      } catch (_) {}
      // photo_manager keeps every file it exported in its cache. Nothing
      // else in the app uses it, and the imported copies are in storage now.
      if (sources.any((s) => s is GalleryAssetSource)) {
        try {
          await PhotoManager.clearFileCache();
        } catch (_) {}
      }
    }

    _update(_progress.copyWith(finished: true));
    return _progress;
  }

  Future<bool> _importOne(
    GalleryImportSource source,
    Directory? scratch,
    int index,
  ) async {
    switch (source) {
      case GalleryAssetSource(:final asset):
        // twonly names its gallery exports after the media id. When that
        // media is still stored there is nothing to import, so skip exporting
        // and hashing the file altogether.
        final known = Platform.isIOS ? await _mediaNamedLike(asset) : null;
        if (known != null && MediaFileService(known).storedPath.existsSync()) {
          return true;
        }
        final file = await _assetFile(asset);
        if (file == null || !file.existsSync()) return false;
        return _importFile(file, asset: asset, knownMedia: known);

      case AndroidUriSource(:final uri):
        final file = File(p.join(scratch!.path, 'item_$index'));
        try {
          if (!await AndroidPhotoPickerService.copyUriToFile(uri, file.path)) {
            return false;
          }
          return await _importFile(file, ownsFile: true);
        } finally {
          try {
            if (file.existsSync()) await file.delete();
          } catch (_) {}
        }
    }
  }

  /// On iOS `asset.file` decodes the photo and re-encodes it as a maximum
  /// quality JPEG, which is slow, inflates HEIC photos several times, drops the
  /// EXIF data and flattens animated GIFs. The original resource (with the
  /// user's edits applied) is a plain copy instead.
  static Future<File?> _assetFile(AssetEntity asset) async {
    if (Platform.isIOS && asset.type == AssetType.image) {
      try {
        final origin = await asset.originFile;
        if (origin != null) return origin;
      } catch (e) {
        Log.warn('Could not load original of ${asset.id}, using export: $e');
      }
    }
    return asset.file;
  }

  /// [ownsFile] means [file] is a scratch copy that may be moved instead of
  /// copied into twonly's storage. [knownMedia] is the media this asset was
  /// exported from, if its file is gone and can be restored in place.
  Future<bool> _importFile(
    File file, {
    AssetEntity? asset,
    MediaFile? knownMedia,
    bool ownsFile = false,
  }) async {
    final isVideo = asset?.type == AssetType.video;
    final analysis = await _analyzeInBackground(file.path, readExif: !isVideo);
    final hash = analysis.hash;

    if (!_claimedHashes.add(hex.encode(hash))) {
      // Same content picked twice in this run; the other copy imports it.
      return true;
    }

    final existing = await rust_mediafiles.listMediaFiles(
      input: db_mediafiles.MediaQuery(
        filter: db_mediafiles.MediaFilter.byHash,
        hash: hash,
      ),
      transaction: currentDatabaseSession(),
    );
    if (existing.isNotEmpty) {
      // Already known: only restore the stored file in case it went missing.
      await _placeFile(file, MediaFileService(existing.first), ownsFile);
      return true;
    }

    final MediaType type;
    if (isVideo) {
      type = MediaType.video;
    } else if (analysis.isGif || file.path.toLowerCase().endsWith('.gif')) {
      type = MediaType.gif;
    } else {
      type = MediaType.image;
    }

    final createdAt = _oldest([
      ?asset?.createDateTime,
      ?analysis.exifDate,
    ]);

    var mediaFile = knownMedia != null
        ? await _markRestored(knownMedia.mediaId, hash)
        : null;

    mediaFile ??= await rust_mediafiles.upsertMediaFile(
      patch: MediaFilePatch(
        type: type.name,
        createdAt: databaseSeconds(createdAt ?? DateTime.now()),
        storedFileHash: NullableBytes(value: hash),
        stored: true,
      ),
      transaction: currentDatabaseSession(),
    );

    final mediaService = MediaFileService(mediaFile);
    await _placeFile(file, mediaService, ownsFile);
    await mediaService.refreshStoredMetadata();
    await mediaService.createThumbnail();

    // Cropping decodes the whole picture again; only formats that can carry
    // transparency can have borders to trim.
    if (type == MediaType.image && analysis.mayHaveAlpha) {
      await mediaService.cropTransparentBorders();
    }
    return true;
  }

  /// twonly saves media to the gallery named after its media id. Returns that
  /// media if the asset is such an export and the id is still known.
  static Future<MediaFile?> _mediaNamedLike(AssetEntity asset) async {
    try {
      final assetName = await asset.titleAsync;
      final dotIndex = assetName.lastIndexOf('.');
      final baseName = dotIndex != -1
          ? assetName.substring(0, dotIndex)
          : assetName;
      if (!_uuidRegex.hasMatch(baseName)) return null;

      return await rust_mediafiles.getMediaFile(
        id: baseName,
        transaction: currentDatabaseSession(),
      );
    } catch (e) {
      Log.error('Error checking iOS asset UUID name: $e');
      return null;
    }
  }

  /// Marks known media whose file went missing as stored again, so the
  /// gallery copy restores it in place instead of creating a duplicate.
  static Future<MediaFile?> _markRestored(
    String mediaId,
    Uint8List hash,
  ) async {
    try {
      await rust_mediafiles.updateMediaFiles(
        id: mediaId,
        patch: MediaFilePatch(
          storedFileHash: NullableBytes(value: hash),
          stored: true,
        ),
        transaction: currentDatabaseSession(),
      );
      return await rust_mediafiles.getMediaFile(
        id: mediaId,
        transaction: currentDatabaseSession(),
      );
    } catch (e) {
      Log.error('Could not restore media $mediaId: $e');
      return null;
    }
  }

  static Future<void> _placeFile(
    File source,
    MediaFileService mediaService,
    bool ownsFile,
  ) async {
    final target = mediaService.storedPath;
    await target.parent.create(recursive: true);
    if (ownsFile) {
      try {
        await source.rename(target.path);
        return;
      } on FileSystemException {
        // Different file system; fall back to copying.
      }
    }
    await source.copy(target.path);
  }
}

final _uuidRegex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

DateTime? _oldest(List<DateTime> dates) =>
    dates.isEmpty ? null : dates.reduce((a, b) => a.isBefore(b) ? a : b);

class _FileAnalysis {
  const _FileAnalysis({
    required this.hash,
    required this.exifDate,
    required this.isGif,
    required this.mayHaveAlpha,
  });

  final Uint8List hash;
  final DateTime? exifDate;
  final bool isGif;

  /// False for formats that never carry transparency (JPEG, HEIC/AVIF).
  final bool mayHaveAlpha;
}

/// Kept top-level so the isolate closure captures nothing but its arguments.
Future<_FileAnalysis> _analyzeInBackground(
  String path, {
  required bool readExif,
}) => Isolate.run(() => _analyzeFile(path, readExif: readExif));

Future<_FileAnalysis> _analyzeFile(
  String path, {
  required bool readExif,
}) async {
  final file = File(path);

  final sink = AccumulatorSink<Digest>();
  final hasher = sha256.startChunkedConversion(sink);
  final magic = <int>[];
  await for (final chunk in file.openRead()) {
    if (magic.length < 16) magic.addAll(chunk.take(16 - magic.length));
    hasher.add(chunk);
  }
  hasher.close();

  bool startsWith(List<int> prefix, [int offset = 0]) {
    if (magic.length < offset + prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (magic[offset + i] != prefix[i]) return false;
    }
    return true;
  }

  final isJpeg = startsWith([0xFF, 0xD8, 0xFF]);
  final isIsoMedia = startsWith('ftyp'.codeUnits, 4); // HEIC, AVIF
  final isGif = startsWith('GIF8'.codeUnits);

  return _FileAnalysis(
    hash: Uint8List.fromList(sink.events.single.bytes),
    exifDate: readExif ? await _exifCreationTime(file) : null,
    isGif: isGif,
    mayHaveAlpha: !isJpeg && !isIsoMedia,
  );
}

final _exifDateFormat = DateFormat('yyyy:MM:dd HH:mm:ss');

/// The oldest plausible date stored in the EXIF data, if any.
Future<DateTime?> _exifCreationTime(File file) async {
  final dates = <DateTime>[];
  try {
    final data = await readExifFromFile(file, details: false);
    for (final MapEntry(:key, :value) in data.entries) {
      if (!key.toLowerCase().contains('datetime') && !key.contains('Time')) {
        continue;
      }
      try {
        final date = _exifDateFormat.parseStrict(value.printable.trim());
        // Cameras without a clock write "0000:00:00 00:00:00" and similar.
        if (date.year >= 1990 && date.isBefore(DateTime.now())) {
          dates.add(date);
        }
      } catch (_) {
        // Not a date (e.g. ExposureTime).
      }
    }
  } catch (_) {
    // No or unreadable EXIF data.
  }
  return _oldest(dates);
}
