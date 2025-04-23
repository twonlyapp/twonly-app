import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/media_uploads_table.dart';

@DataClassName('MediaDownload')
class MediaDownloads extends Table {
  IntColumn get messageId => integer()();
  TextColumn get downloadToken => text().map(IntListTypeConverter())();
}
