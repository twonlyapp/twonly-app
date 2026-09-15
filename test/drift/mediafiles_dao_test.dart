import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  late TwonlyDB database;

  setUp(() {
    database = TwonlyDB(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test(
    'chat media includes empty groups and deduplicates message references',
    () async {
      await database.customStatement(
        "INSERT INTO groups(group_id, group_name) VALUES('chat-1', 'Friends')",
      );
      await database.customStatement(
        "INSERT INTO groups(group_id, group_name) VALUES('chat-2', 'Family')",
      );
      await database.customStatement(
        "INSERT INTO groups(group_id, group_name) VALUES('chat-3', 'Empty')",
      );
      await database.customStatement(
        "INSERT INTO media_files(media_id, type, stored, size_in_bytes) "
        "VALUES('not-stored', 'image', 0, 100)",
      );
      await database.customStatement(
        "INSERT INTO media_files(media_id, type, stored, size_in_bytes) "
        "VALUES('stored', 'video', 1, 200)",
      );
      await database.customStatement(
        "INSERT INTO messages(group_id, message_id, type, media_id) "
        "VALUES('chat-1', 'message-1', 'media', 'not-stored')",
      );
      await database.customStatement(
        "INSERT INTO messages(group_id, message_id, type, media_id) "
        "VALUES('chat-1', 'message-2', 'media', 'not-stored')",
      );
      await database.customStatement(
        "INSERT INTO messages(group_id, message_id, type, media_id) "
        "VALUES('chat-2', 'message-3', 'media', 'stored')",
      );

      final chats = await database.mediaFilesDao.watchMediaFilesByChat().first;

      expect(chats, hasLength(3));
      final friends = chats.singleWhere(
        (chat) => chat.group.groupId == 'chat-1',
      );
      expect(friends.mediaFiles, hasLength(1));
      expect(friends.mediaFiles.single.mediaId, 'not-stored');
      expect(friends.mediaFiles.single.stored, isFalse);
      final empty = chats.singleWhere(
        (chat) => chat.group.groupId == 'chat-3',
      );
      expect(empty.mediaFiles, isEmpty);
    },
  );
}
