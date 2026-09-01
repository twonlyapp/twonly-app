import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/database/twonly.db.dart';

void main() {
  late TwonlyDB database;

  setUp(() {
    database = TwonlyDB(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('members use user ids and only non-direct group ids', () async {
    await database.customStatement(
      "INSERT INTO contacts(user_id, username) VALUES(7, 'alice')",
    );
    await database.customStatement(
      "INSERT INTO groups(group_id, group_name, is_direct_chat) "
      "VALUES('direct-1', 'Alice', 1)",
    );
    await database.customStatement(
      "INSERT INTO groups(group_id, group_name, is_direct_chat) "
      "VALUES('group-1', 'Friends', 0)",
    );
    final contactGroupId = await database.contactGroupsDao.createContactGroup(
      name: 'Favorites',
      emoji: '⭐',
      textColor: 0xFF000000,
      backgroundColor: 0,
      showAsShortcut: true,
      showAsLabel: true,
    );

    await database.contactGroupsDao.replaceMembers(
      contactGroupId,
      userIds: const [7],
      groupIds: const ['direct-1', 'group-1'],
    );

    final members = await database.contactGroupsDao.getMembers(contactGroupId);
    expect(members, hasLength(2));
    expect(members.where((member) => member.userId == 7), hasLength(1));
    expect(
      members.where((member) => member.groupId == 'group-1'),
      hasLength(1),
    );
    expect(members.any((member) => member.groupId == 'direct-1'), isFalse);
  });
}
