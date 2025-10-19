import 'package:drift/drift.dart';
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
      final rowId = await into(mediaFiles).insert(mediaFile);

      return await (select(mediaFiles)..where((t) => t.rowId.equals(rowId)))
          .getSingle();
    } catch (e) {
      Log.error('Could not insert media file: $e');
      return null;
    }
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
}
