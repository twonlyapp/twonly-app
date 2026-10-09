import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TwonlyDB db;
  setUp(() async {
    db = TwonlyDB.forTesting(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    await db
        .into(db.groups)
        .insert(GroupsCompanion.insert(groupId: 'chat', groupName: 'Group'));
    for (final (id, name) in [
      (1, 'Zebra'),
      (2, 'Alpha'),
      (3, 'Bob'),
      (4, 'Inactive'),
    ]) {
      await db
          .into(db.contacts)
          .insert(ContactsCompanion.insert(userId: Value(id), username: name));
      await db
          .into(db.groupMembers)
          .insert(
            GroupMembersCompanion.insert(
              groupId: 'chat',
              contactId: id,
              memberState: id == 4
                  ? const Value(MemberState.leftGroup)
                  : const Value.absent(),
            ),
          );
    }
    final migration = File(
      'rust/src/database/app/migrations/0034_group_avatar_activity.sql',
    ).readAsStringSync();
    await db.customStatement(
      migration.substring(migration.indexOf('CREATE TRIGGER')),
    );
  });
  tearDown(() async => db.close());

  test(
    'group avatars rank senders by activity and react to received messages',
    () async {
      final results = <List<int>>[];
      final stream = db.groupsDao
          .watchGroupContact('chat')
          .listen(
            (contacts) => results.add(contacts.map((c) => c.userId).toList()),
          );
      addTearDown(stream.cancel);
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              groupId: 'chat',
              messageId: 'first',
              type: 'text',
              senderId: const Value(1),
              createdAt: Value(
                DateTime.fromMillisecondsSinceEpoch(1700000200000),
              ),
            ),
          );
      expect(
        (await db.groupsDao.getGroupContact('chat')).map((c) => c.userId),
        [1, 2, 3],
      );
      await db
          .into(db.messages)
          .insert(
            MessagesCompanion.insert(
              groupId: 'chat',
              messageId: 'second',
              type: 'media',
              senderId: const Value(3),
              createdAt: Value(
                DateTime.fromMillisecondsSinceEpoch(1700000300000),
              ),
            ),
          );
      // Rust commits notify both tables because the trigger also updates members.
      db.notifyUpdates({TableUpdate.onTable(db.groupMembers)});
      expect(
        (await db.groupsDao.getGroupContact('chat')).map((c) => c.userId),
        [3, 1, 2],
      );
      await Future<void>.delayed(Duration.zero);
      expect(results.last, [3, 1, 2]);
    },
  );
}
