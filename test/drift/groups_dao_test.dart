import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  late TwonlyDB database;

  setUp(() async {
    database = TwonlyDB(NativeDatabase.memory());
    for (final statement in [
      "INSERT INTO contacts(user_id, username) VALUES (7, 'alice'), (8, 'bob'), (9, 'carol'), (10, 'former')",
      "INSERT INTO groups(group_id, group_name) VALUES ('group', 'Friends'), ('other', 'Other')",
      "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('direct', 'Alice', 1)",
      // Legacy (null), normal and admin members must all remain visible.
      'INSERT INTO group_members(group_id, contact_id, member_state, last_type_indicator) '
          "VALUES ('group', 7, NULL, 1), ('group', 8, 'normal', 1), ('group', 9, 'admin', 1), ('group', 10, 'leftGroup', 1)",
      "INSERT INTO group_members(group_id, contact_id) VALUES ('other', 7), ('direct', 7)",
      'INSERT INTO messages(group_id, message_id, sender_id, type, content) '
          "VALUES ('group', 'message', 7, 'text', 'Hello')",
      'INSERT INTO group_histories(group_history_id, group_id, affected_contact_id, type) '
          "VALUES ('removal', 'group', 7, 'removedMember')",
    ]) {
      await database.customStatement(statement);
    }
  });

  tearDown(() => database.close());

  Future<void> setMemberState(MemberState state) =>
      database.groupsDao.insertOrUpdateGroupMember(
        GroupMembersCompanion(
          groupId: const Value('group'),
          contactId: const Value(7),
          memberState: Value(state),
        ),
      );

  test(
    'removed members leave active queries while history is retained',
    () async {
      expect(
        (await database.groupsDao.getGroupContact(
          'group',
        )).map((c) => c.userId),
        unorderedEquals([7, 8, 9]),
      );

      await setMemberState(MemberState.leftGroup);

      expect(
        (await database.groupsDao.getGroupContact(
          'group',
        )).map((c) => c.userId),
        unorderedEquals([8, 9]),
      );
      expect(
        (await database.groupsDao.getGroupNonLeftMembers(
          'group',
        )).map((m) => m.contactId),
        unorderedEquals([8, 9]),
      );
      expect(
        await database.groupsDao.getAllGroupMembers('group'),
        hasLength(4),
      );
      expect(
        (await database.select(database.messages).get()).single.content,
        'Hello',
      );
      expect(
        (await database.groupsDao.watchGroupActions('group').first)
            .single
            .affectedContactId,
        7,
      );
      expect(
        (await database.groupsDao.getGroupContact('other')).single.userId,
        7,
      );
      expect(
        (await database.groupsDao.getGroupContact('direct')).single.userId,
        7,
      );
    },
  );

  final memberStreams = <String, Stream<List<int>> Function()>{
    'member list': () => database.groupsDao
        .watchGroupMembers('group')
        .map((rows) => rows.map((row) => row.$1.userId).toList()),
    'group contacts': () => database.groupsDao
        .watchGroupContact('group')
        .map((rows) => rows.map((row) => row.userId).toList()),
    'chat list members': () => database.groupsDao.watchAllGroupMembers().map(
      (rows) => rows
          .where((row) => row.$2.groupId == 'group')
          .map((row) => row.$1.userId)
          .toList(),
    ),
    'typing members': () => database.groupsDao.watchTypingGroupMembers().map(
      (rows) => rows.map((row) => row.contactId).toList(),
    ),
  };

  for (final entry in memberStreams.entries) {
    test('${entry.key} updates on removal and rejoining', () async {
      final stream = StreamIterator(entry.value());
      addTearDown(stream.cancel);
      expect(await stream.moveNext(), isTrue);
      expect(stream.current, unorderedEquals([7, 8, 9]));

      final removal = stream.moveNext();
      await setMemberState(MemberState.leftGroup);
      expect(await removal, isTrue);
      expect(stream.current, unorderedEquals([8, 9]));

      final rejoining = stream.moveNext();
      await setMemberState(MemberState.normal);
      expect(await rejoining, isTrue);
      expect(stream.current, unorderedEquals([7, 8, 9]));
    });
  }

  test('mutual groups update when a member is removed', () async {
    final stream = StreamIterator(
      database.groupsDao.watchNonDirectGroupsForMember(7),
    );
    addTearDown(stream.cancel);
    expect(await stream.moveNext(), isTrue);
    expect(
      stream.current.map((g) => g.groupId),
      unorderedEquals(['group', 'other']),
    );

    final removal = stream.moveNext();
    await setMemberState(MemberState.leftGroup);
    expect(await removal, isTrue);
    expect(stream.current.map((g) => g.groupId), ['other']);
  });
}
