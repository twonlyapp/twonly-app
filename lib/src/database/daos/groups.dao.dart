import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

part 'groups.dao.g.dart';

@DriftAccessor(tables: [Groups, GroupMembers])
class GroupsDao extends DatabaseAccessor<TwonlyDB> with _$GroupsDaoMixin {
  // this constructor is required so that the main database can create an instance
  // of this object.
  // ignore: matching_super_parameters
  GroupsDao(super.db);

  Future<bool> isContactInGroup(int contactId, String groupId) async {
    final entry = await (select(groupMembers)..where(
            // ignore: require_trailing_commas
            (t) => t.contactId.equals(contactId) & t.groupId.equals(groupId)))
        .getSingleOrNull();
    return entry != null;
  }

  Future<void> updateGroup(
    String groupId,
    GroupsCompanion updates,
  ) async {
    await (update(groups)..where((c) => c.groupId.equals(groupId)))
        .write(updates);
  }

  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    return (select(groupMembers)..where((t) => t.groupId.equals(groupId)))
        .get();
  }

  Future<Group?> createNewGroup(GroupsCompanion group) async {
    final insertGroup = group.copyWith(
      groupId: Value(uuid.v4()),
      isGroupAdmin: const Value(true),
    );
    return _insertGroup(insertGroup);
  }

  Future<Group?> createNewDirectChat(
    int contactId,
    GroupsCompanion group,
  ) async {
    final groupIdDirectChat = getUUIDforDirectChat(contactId, gUser.userId);
    final insertGroup = group.copyWith(
      groupId: Value(groupIdDirectChat),
      isDirectChat: const Value(true),
      isGroupAdmin: const Value(true),
    );

    final result = await _insertGroup(insertGroup);
    if (result != null) {
      await into(groupMembers).insert(
        GroupMembersCompanion(
          groupId: Value(result.groupId),
          contactId: Value(
            contactId,
          ),
        ),
      );
    }
    return result;
  }

  Future<Group?> _insertGroup(GroupsCompanion group) async {
    try {
      final rowId = await into(groups).insert(group);
      return await (select(groups)..where((t) => t.rowId.equals(rowId)))
          .getSingle();
    } catch (e) {
      Log.error('Could not insert group: $e');
      return null;
    }
  }

  Future<List<Contact>> getGroupContact(String groupId) async {
    final query = (select(contacts).join([
      leftOuterJoin(
        groupMembers,
        groupMembers.contactId.equalsExp(contacts.userId),
      ),
    ])
      ..where(groupMembers.groupId.equals(groupId)));
    return query.map((row) => row.readTable(contacts)).get();
  }

  Stream<List<Group>> watchGroups() {
    return select(groups).watch();
  }

  Stream<Group?> watchGroup(String groupId) {
    return (select(groups)..where((t) => t.groupId.equals(groupId)))
        .watchSingleOrNull();
  }

  Stream<List<Group>> watchGroupsForChatList() {
    return (select(groups)
          ..where((t) => t.archived.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageExchange)]))
        .watch();
  }

  Future<Group?> getGroup(String groupId) {
    return (select(groups)..where((t) => t.groupId.equals(groupId)))
        .getSingleOrNull();
  }

  Stream<int> watchFlameCounter(String groupId) {
    return (select(groups)
          ..where(
            (u) =>
                u.groupId.equals(groupId) &
                u.lastMessageReceived.isNotNull() &
                u.lastMessageSend.isNotNull(),
          ))
        .watchSingleOrNull()
        .asyncMap(getFlameCounterFromGroup);
  }

  Future<List<Group>> getAllDirectChats() {
    return (select(groups)..where((t) => t.isDirectChat.equals(true))).get();
  }

  Future<Group?> getDirectChat(int userId) async {
    final query =
        ((select(groups)..where((t) => t.isDirectChat.equals(true))).join([
      leftOuterJoin(
        groupMembers,
        groupMembers.groupId.equalsExp(groups.groupId),
      ),
    ])
          ..where(groupMembers.contactId.equals(userId)));

    return query.map((row) => row.readTable(groups)).getSingleOrNull();
  }

  Future<void> incFlameCounter(
    String groupId,
    bool received,
    DateTime timestamp,
  ) async {
    final group = await (select(groups)
          ..where((t) => t.groupId.equals(groupId)))
        .getSingle();

    final totalMediaCounter = group.totalMediaCounter + 1;
    var flameCounter = group.flameCounter;

    if (group.lastMessageReceived != null && group.lastMessageSend != null) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final twoDaysAgo = startOfToday.subtract(const Duration(days: 2));
      if (group.lastMessageSend!.isBefore(twoDaysAgo) ||
          group.lastMessageReceived!.isBefore(twoDaysAgo)) {
        flameCounter = 0;
      }
    }

    var lastMessageSend = const Value<DateTime?>.absent();
    var lastMessageReceived = const Value<DateTime?>.absent();
    var lastFlameCounterChange = const Value<DateTime?>.absent();

    if (group.lastFlameCounterChange != null) {
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);

      if (group.lastFlameCounterChange!.isBefore(startOfToday)) {
        // last flame update was yesterday. check if it can be updated.
        var updateFlame = false;
        if (received) {
          if (group.lastMessageSend != null &&
              group.lastMessageSend!.isAfter(startOfToday)) {
            // today a message was already send -> update flame
            updateFlame = true;
          }
        } else if (group.lastMessageReceived != null &&
            group.lastMessageReceived!.isAfter(startOfToday)) {
          // today a message was already received -> update flame
          updateFlame = true;
        }
        if (updateFlame) {
          flameCounter += 1;
          lastFlameCounterChange = Value(timestamp);
        }
      }
    } else {
      // There where no message until no...
      lastFlameCounterChange = Value(timestamp);
    }

    if (received) {
      lastMessageReceived = Value(timestamp);
    } else {
      lastMessageSend = Value(timestamp);
    }

    await (update(groups)..where((t) => t.groupId.equals(groupId))).write(
      GroupsCompanion(
        totalMediaCounter: Value(totalMediaCounter),
        lastFlameCounterChange: lastFlameCounterChange,
        lastMessageReceived: lastMessageReceived,
        lastMessageSend: lastMessageSend,
        flameCounter: Value(flameCounter),
      ),
    );
  }

  Future<void> increaseLastMessageExchange(
    String groupId,
    DateTime newLastMessage,
  ) async {
    await (update(groups)
          ..where(
            (t) =>
                t.groupId.equals(groupId) &
                (t.lastMessageExchange.isSmallerThanValue(newLastMessage)),
          ))
        .write(GroupsCompanion(lastMessageExchange: Value(newLastMessage)));
  }
}

int getFlameCounterFromGroup(Group? group) {
  if (group == null) return 0;
  if (group.lastMessageSend == null || group.lastMessageReceived == null) {
    return 0;
  }
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final twoDaysAgo = startOfToday.subtract(const Duration(days: 2));
  if (group.lastMessageSend!.isAfter(twoDaysAgo) &&
      group.lastMessageReceived!.isAfter(twoDaysAgo)) {
    return group.flameCounter + 1;
  } else {
    return 0;
  }
}
