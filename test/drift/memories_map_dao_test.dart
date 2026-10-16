import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  late TwonlyDB database;
  setUp(() => database = TwonlyDB(NativeDatabase.memory()));
  tearDown(() => database.close());

  Future<void> insert(String id, String values) => database.customStatement(
    'INSERT INTO media_files(media_id, type, stored, cloud_state, '
    'is_draft_media, is_widget_media, is_favorite, location_latitude, '
    'location_longitude, stored_file_hash) VALUES(?, $values)',
    [id],
  );

  test(
    'map includes saved and cloud media without requiring thumbnails',
    () async {
      await insert('saved', "'image', 1, 'none', 0, 0, 0, 52, 13, NULL");
      await insert('cloud', "'video', 0, 'uploaded', 0, 0, 0, 48, 11, NULL");
      await insert('unsaved', "'image', 0, 'none', 0, 0, 0, 52, 13, NULL");
      await insert('draft', "'image', 1, 'none', 1, 0, 0, 52, 13, NULL");
      await insert('widget', "'image', 1, 'none', 0, 1, 0, 52, 13, NULL");
      await insert('audio', "'audio', 1, 'none', 0, 0, 0, 52, 13, NULL");
      await insert('missing', "'image', 1, 'none', 0, 0, 0, NULL, 13, NULL");
      await insert('invalid', "'image', 1, 'none', 0, 0, 0, 91, 13, NULL");
      await insert(
        'invalid-longitude',
        "'image', 1, 'none', 0, 0, 0, 52, 181, NULL",
      );
      final files = await database.mediaFilesDao.watchGeotaggedMemories().first;
      expect(files.map((f) => f.mediaId), unorderedEquals(['saved', 'cloud']));
      expect(files.every((f) => !f.hasThumbnail), isTrue);
    },
  );

  test(
    'filtering locations and favorites happens before deduplication',
    () async {
      await insert(
        'unlocated-copy',
        "'image', 1, 'none', 0, 0, 0, NULL, NULL, X'1234'",
      );
      await insert(
        'located-copy',
        "'image', 1, 'none', 0, 0, 0, 52, 13, X'1234'",
      );
      await insert(
        'favorite-copy',
        "'image', 1, 'none', 0, 0, 1, 52, 13, X'1234'",
      );
      final all = await database.mediaFilesDao.watchGeotaggedMemories().first;
      expect(all, hasLength(1));
      expect(all.single.locationLatitude, 52);
      final favorites = await database.mediaFilesDao
          .watchGeotaggedMemories(favoritesOnly: true)
          .first;
      expect(favorites.single.mediaId, 'favorite-copy');
    },
  );

  test('pending locations and deletions update the map stream', () async {
    await insert('pending', "'image', 1, 'none', 0, 0, 0, NULL, NULL, NULL");
    final emissions = <List<MediaFile>>[];
    final subscription = database.mediaFilesDao.watchGeotaggedMemories().listen(
      emissions.add,
    );
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    expect(emissions.last, isEmpty);
    await database.customStatement(
      "UPDATE media_files SET location_latitude=0, location_longitude=0 WHERE media_id='pending'",
    );
    database.markTablesUpdated({database.mediaFiles});
    await pumpEventQueue();
    expect(emissions.last.single.mediaId, 'pending');
    await database.mediaFilesDao.deleteMediaFile('pending');
    await pumpEventQueue();
    expect(emissions.last, isEmpty);
  });
}
