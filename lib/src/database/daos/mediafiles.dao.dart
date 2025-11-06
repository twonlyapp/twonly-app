import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

part 'mediafiles.dao.g.dart';

@DriftAccessor(tables: [MediaFiles])
class MediaFilesDao extends DatabaseAccessor<TwonlyDB>
    with _$MediaFilesDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  MediaFilesDao(super.db);

  Future<MediaFile?> insertMedia(MediaFilesCompanion mediaFile) async {
    try {
      var insertMediaFile = mediaFile;

      if (insertMediaFile.mediaId == const Value.absent()) {
        insertMediaFile = mediaFile.copyWith(
          mediaId: Value(uuid.v7()),
        );
      }

      final rowId = await into(mediaFiles).insert(insertMediaFile);

      return await (select(mediaFiles)..where((t) => t.rowId.equals(rowId)))
          .getSingle();
    } catch (e) {
      Log.error('Could not insert media file: $e');
      return null;
    }
  }

  Future<void> deleteMediaFile(String mediaId) async {
    await (delete(mediaFiles)
          ..where(
            (t) => t.mediaId.equals(mediaId),
          ))
        .go();
  }

  Future<void> updateMedia(
    String mediaId,
    MediaFilesCompanion updates,
  ) async {
    await (update(mediaFiles)..where((c) => c.mediaId.equals(mediaId)))
        .write(updates);
  }

  Future<MediaFile?> getMediaFileById(String mediaId) async {
    return (select(mediaFiles)..where((t) => t.mediaId.equals(mediaId)))
        .getSingleOrNull();
  }

  Stream<MediaFile?> watchMedia(String mediaId) {
    return (select(mediaFiles)..where((t) => t.mediaId.equals(mediaId)))
        .watchSingleOrNull();
  }

  Future<void> resetPendingDownloadState() async {
    await (update(mediaFiles)
          ..where(
            (c) => c.downloadState.equals(
              DownloadState.downloading.name,
            ),
          ))
        .write(
      const MediaFilesCompanion(
        downloadState: Value(DownloadState.pending),
      ),
    );
  }

  Future<List<MediaFile>> getAllMediaFilesPendingDownload() async {
    return (select(mediaFiles)
          ..where(
            (t) =>
                t.downloadState.equals(DownloadState.pending.name) |
                t.downloadState.equals(DownloadState.downloading.name),
          ))
        .get();
  }

  Future<List<MediaFile>> getAllMediaFilesPendingUpload() async {
    return (select(mediaFiles)
          ..where(
            (t) =>
                t.uploadState.equals(UploadState.initialized.name) |
                t.uploadState.equals(UploadState.uploadLimitReached.name) |
                t.uploadState.equals(UploadState.preprocessing.name),
          ))
        .get();
  }

  Stream<List<MediaFile>> watchAllStoredMediaFiles() {
    return (select(mediaFiles)..where((t) => t.stored.equals(true))).watch();
  }

  Stream<List<MediaFile>> watchNewestMediaFiles() {
    return (select(mediaFiles)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(100))
        .watch();
  }
}
