import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/media_download_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/log.dart';

part 'media_downloads_dao.g.dart';

@DriftAccessor(tables: [MediaDownloads])
class MediaDownloadsDao extends DatabaseAccessor<TwonlyDatabase>
    with _$MediaDownloadsDaoMixin {
  MediaDownloadsDao(super.db);

  Future<void> updateMediaDownload(
      int messageId, MediaDownloadsCompanion updatedValues) {
    return (update(mediaDownloads)..where((c) => c.messageId.equals(messageId)))
        .write(updatedValues);
  }

  Future<int?> insertMediaDownload(MediaDownloadsCompanion values) async {
    try {
      return await into(mediaDownloads).insert(values);
    } catch (e) {
      Log.error("Error while inserting media upload: $e");
      return null;
    }
  }

  Future<void> deleteMediaDownload(int messageId) {
    return (delete(mediaDownloads)..where((t) => t.messageId.equals(messageId)))
        .go();
  }

  SingleOrNullSelectable<MediaDownload> getMediaDownloadById(int messageId) {
    return select(mediaDownloads)..where((t) => t.messageId.equals(messageId));
  }

  SingleOrNullSelectable<MediaDownload> getMediaDownloadByDownloadToken(
      List<int> downloadToken) {
    return select(mediaDownloads)
      ..where((t) => t.downloadToken.equals(json.encode(downloadToken)));
  }
}
