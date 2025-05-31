import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/media_uploads_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/log.dart';

part 'media_uploads_dao.g.dart';

@DriftAccessor(tables: [MediaUploads])
class MediaUploadsDao extends DatabaseAccessor<TwonlyDatabase>
    with _$MediaUploadsDaoMixin {
  MediaUploadsDao(super.db);

  Future<List<MediaUpload>> getMediaUploadsForRetry() {
    return (select(mediaUploads)
          ..where(
              (t) => t.state.equals(UploadState.receiverNotified.name).not()))
        .get();
  }

  Future updateMediaUpload(
      int mediaUploadId, MediaUploadsCompanion updatedValues) {
    return (update(mediaUploads)
          ..where((c) => c.mediaUploadId.equals(mediaUploadId)))
        .write(updatedValues);
  }

  Future<int?> insertMediaUpload(MediaUploadsCompanion values) async {
    try {
      return await into(mediaUploads).insert(values);
    } catch (e) {
      Log.error("Error while inserting media upload: $e");
      return null;
    }
  }

  Future deleteMediaUpload(int mediaUploadId) {
    return (delete(mediaUploads)
          ..where((t) => t.mediaUploadId.equals(mediaUploadId)))
        .go();
  }

  SingleOrNullSelectable<MediaUpload> getMediaUploadById(int mediaUploadId) {
    return select(mediaUploads)
      ..where((t) => t.mediaUploadId.equals(mediaUploadId));
  }
}
