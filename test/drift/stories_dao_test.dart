import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  late TwonlyDB database;
  final now = DateTime(2026, 9, 27, 12);
  final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;

  setUp(() async {
    database = TwonlyDB(NativeDatabase.memory());
    for (final statement in [
      "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'anna', 1)",
      "INSERT INTO contacts(user_id, username, accepted) VALUES (8, 'ben', 1)",
      "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('anna', 'Anna', 1)",
      "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('ben', 'Ben', 1)",
      "INSERT INTO group_members(group_id, contact_id) VALUES ('anna', 7)",
      "INSERT INTO group_members(group_id, contact_id) VALUES ('ben', 8)",
      "INSERT INTO media_files(media_id, type) VALUES ('seen', 'image'), ('unseen', 'image'), ('old', 'image'), ('chat', 'image'), ('mine', 'video')",
      // Anna's story: one item seen, one not, one long expired.
      'INSERT INTO messages(group_id, message_id, sender_id, type, media_id, is_story, opened_at, created_at) '
          "VALUES ('anna', 'seen', 7, 'media', 'seen', 1, $nowSeconds, ${nowSeconds - 3600})",
      'INSERT INTO messages(group_id, message_id, sender_id, type, media_id, is_story, created_at) '
          "VALUES ('anna', 'unseen', 7, 'media', 'unseen', 1, ${nowSeconds - 60})",
      'INSERT INTO messages(group_id, message_id, sender_id, type, media_id, is_story, created_at) '
          "VALUES ('anna', 'old', 7, 'media', 'old', 1, ${nowSeconds - 2 * 86400})",
      // An ordinary snap in the same chat, older than the story.
      'INSERT INTO messages(group_id, message_id, sender_id, type, media_id, created_at) '
          "VALUES ('anna', 'chat', 7, 'media', 'chat', ${nowSeconds - 7200})",
      // The user's own story item went to both, and Ben opened it.
      'INSERT INTO messages(group_id, message_id, type, media_id, is_story, created_at) '
          "VALUES ('anna', 'mine-anna', 'media', 'mine', 1, ${nowSeconds - 600})",
      'INSERT INTO messages(group_id, message_id, type, media_id, is_story, opened_at, created_at) '
          "VALUES ('ben', 'mine-ben', 'media', 'mine', 1, $nowSeconds, ${nowSeconds - 600})",
      'INSERT INTO message_actions(message_id, contact_id, type, action_at) '
          "VALUES ('mine-ben', 8, 'openedAt', $nowSeconds)",
    ]) {
      await database.customStatement(statement);
    }
  });

  tearDown(() => database.close());

  test('received story items skip expired ones, oldest first', () async {
    final items = await withClock(
      Clock.fixed(now),
      () => database.storiesDao.getReceivedStoryItems(7),
    );
    expect(items.map((item) => item.message.messageId), ['seen', 'unseen']);
    expect(items.map((item) => item.seen), [true, false]);
  });

  test('own story items are grouped per media with their viewers', () async {
    final items = await withClock(
      Clock.fixed(now),
      () => database.storiesDao.watchOwnStoryItems().first,
    );
    expect(items, hasLength(1));
    expect(items.single.mediaFile.mediaId, 'mine');
    expect(items.single.recipientCount, 2);
    expect(items.single.viewerCount, 1);

    final viewers = await database.storiesDao.watchStoryViewers('mine').first;
    expect(viewers.map((viewer) => viewer.contact.userId), [8, 7]);
    expect(viewers.first.openedAt, isNotNull);
    expect(viewers.last.openedAt, isNull);
  });

  test('the chat list never shows an unsaved story row', () async {
    final latest = await database.messagesDao
        .watchLatestMessagesByGroup()
        .first;
    final byGroup = {for (final m in latest) m.groupId: m.messageId};
    // The story rows are newer, but the chat still ends at the snap.
    expect(byGroup['anna'], 'chat');
    expect(byGroup.containsKey('ben'), isFalse);

    final unopened = await database.messagesDao
        .watchAllMessagesNotOpened()
        .first;
    expect(unopened.map((m) => m.messageId), ['chat']);
  });

  test('a saved story shows in its chat like any stored media', () async {
    await database.customStatement(
      "UPDATE messages SET media_stored = 1 WHERE message_id = 'unseen'",
    );
    final latest = await database.messagesDao
        .watchLatestMessagesByGroup()
        .first;
    expect(
      latest.singleWhere((m) => m.groupId == 'anna').messageId,
      'unseen',
    );
  });

  test(
    'the chat retention purge leaves story rows to the story purge',
    () async {
      await database.customStatement(
        'UPDATE groups SET delete_messages_after_milliseconds = 1000',
      );
      await database.customStatement(
        'UPDATE messages SET opened_by_all = ${nowSeconds - 86400}',
      );
      await withClock(
        Clock.fixed(now),
        () => database.messagesDao.purgeMessageTable(),
      );
      final remaining = await database
          .customSelect('SELECT message_id FROM messages ORDER BY message_id')
          .map((row) => row.read<String>('message_id'))
          .get();
      expect(remaining, ['mine-anna', 'mine-ben', 'old', 'seen', 'unseen']);
    },
  );
}
