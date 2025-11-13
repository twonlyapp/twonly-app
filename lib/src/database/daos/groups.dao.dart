import 'package:drift/drift.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

part 'groups.dao.g.dart';

@DriftAccessor(
  tables: [
    Groups,
    GroupMembers,
    GroupHistories,
  ],
)
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

  Future<void> deleteGroup(String groupId) async {
    await (delete(groups)..where((t) => t.groupId.equals(groupId))).go();
  }

  Future<void> updateGroup(
    String groupId,
    GroupsCompanion updates,
  ) async {
    await (update(groups)..where((c) => c.groupId.equals(groupId)))
        .write(updates);
  }

  Future<List<GroupMember>> getGroupNonLeftMembers(String groupId) async {
    return (select(groupMembers)
          ..where(
            (t) =>
                t.groupId.equals(groupId) &
                (t.memberState.equals(MemberState.leftGroup.name).not() |
                    t.memberState.isNull()),
          ))
        .get();
  }

  Future<List<GroupMember>> getAllGroupMembers(String groupId) async {
    return (select(groupMembers)..where((t) => t.groupId.equals(groupId)))
        .get();
  }

  Future<GroupMember?> getGroupMemberByPublicKey(Uint8List publicKey) async {
    return (select(groupMembers)
          ..where((t) => t.groupPublicKey.equals(publicKey)))
        .getSingleOrNull();
  }

  Future<Group?> createNewGroup(GroupsCompanion group) async {
    return _insertGroup(group);
  }

  Future<void> insertOrUpdateGroupMember(GroupMembersCompanion members) async {
    await into(groupMembers).insertOnConflictUpdate(members);
  }

  Future<void> insertGroupAction(GroupHistoriesCompanion action) async {
    var insertAction = action;
    if (!action.groupHistoryId.present) {
      insertAction = action.copyWith(
        groupHistoryId: Value(uuid.v4()),
      );
    }
    await into(groupHistories).insert(insertAction);
  }

  Stream<List<GroupHistory>> watchGroupActions(String groupId) {
    return (select(groupHistories)
          ..where((t) => t.groupId.equals(groupId))
          ..orderBy([(t) => OrderingTerm.asc(t.actionAt)]))
        .watch();
  }

  Future<void> updateMember(
    String groupId,
    int contactId,
    GroupMembersCompanion updates,
  ) async {
    await (update(groupMembers)
          ..where(
            (c) => c.groupId.equals(groupId) & c.contactId.equals(contactId),
          ))
        .write(updates);
  }

  Future<void> removeMember(String groupId, int contactId) async {
    await (delete(groupMembers)
          ..where(
            (c) => c.groupId.equals(groupId) & c.contactId.equals(contactId),
          ))
        .go();
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
      joinedGroup: const Value(true),
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
      await into(groups).insert(group);
      return await (select(groups)
            ..where((t) => t.groupId.equals(group.groupId.value)))
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
        useColumns: false,
      ),
    ])
      ..orderBy([OrderingTerm.desc(groupMembers.lastMessage)])
      ..where(groupMembers.groupId.equals(groupId)));
    return query.map((row) => row.readTable(contacts)).get();
  }

  Stream<List<Contact>> watchGroupContact(String groupId) {
    final query = (select(contacts).join([
      leftOuterJoin(
        groupMembers,
        groupMembers.contactId.equalsExp(contacts.userId),
        useColumns: false,
      ),
    ])
      ..orderBy([OrderingTerm.desc(groupMembers.lastMessage)])
      ..where(groupMembers.groupId.equals(groupId)));
    return query.map((row) => row.readTable(contacts)).watch();
  }

  Stream<List<(Contact, GroupMember)>> watchGroupMembers(String groupId) {
    final query =
        (select(groupMembers)..where((t) => t.groupId.equals(groupId))).join([
      leftOuterJoin(
        contacts,
        contacts.userId.equalsExp(groupMembers.contactId),
      ),
    ]);
    return query
        .map((row) => (row.readTable(contacts), row.readTable(groupMembers)))
        .watch();
  }

  Stream<List<Group>> watchGroupsForShareImage() {
    return (select(groups)
          ..where(
            (g) => g.leftGroup.equals(false) & g.deletedContent.equals(false),
          ))
        .watch();
  }

  Stream<Group?> watchGroup(String groupId) {
    return (select(groups)..where((t) => t.groupId.equals(groupId)))
        .watchSingleOrNull();
  }

  Stream<Group?> watchDirectChat(int contactId) {
    final groupId = getUUIDforDirectChat(contactId, gUser.userId);
    return (select(groups)..where((t) => t.groupId.equals(groupId)))
        .watchSingleOrNull();
  }

  Stream<List<Group>> watchGroupsForChatList() {
    return (select(groups)
          ..where((t) => t.deletedContent.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lastMessageExchange)]))
        .watch();
  }

  Stream<List<Group>> watchGroupsForStartNewChat() {
    return (select(groups)
          ..where((t) => t.isDirectChat.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.groupName)]))
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

  Future<List<Group>> getAllNotJoinedGroups() {
    return (select(groups)
          ..where(
            (t) => t.joinedGroup.equals(false) & t.isDirectChat.equals(false),
          ))
        .get();
  }

  Future<List<GroupMember>> getAllGroupMemberWithoutPublicKey() async {
    try {
      final query = ((select(groupMembers)
            ..where((t) => t.groupPublicKey.isNull()))
          .join([
        leftOuterJoin(
          groups,
          groups.groupId.equalsExp(groupMembers.groupId),
        ),
      ])
        ..where(groups.isDirectChat.isNull()));
      return query.map((row) => row.readTable(groupMembers)).get();
    } catch (e) {
      Log.error(e);
      return [];
    }
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

    final totalMediaCounter = group.totalMediaCounter + (received ? 0 : 1);
    var flameCounter = group.flameCounter;
    var maxFlameCounter = group.maxFlameCounter;
    var maxFlameCounterFrom = group.maxFlameCounterFrom;

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
          // Overwrite max flame counter either the current is bigger or the th max flame counter is older then 4 days
          if (flameCounter >= maxFlameCounter ||
              maxFlameCounterFrom == null ||
              maxFlameCounterFrom
                  .isBefore(DateTime.now().subtract(const Duration(days: 5)))) {
            maxFlameCounter = flameCounter;
            maxFlameCounterFrom = DateTime.now();
          }
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
        maxFlameCounter: Value(maxFlameCounter),
        maxFlameCounterFrom: Value(maxFlameCounterFrom),
      ),
    );
  }

  Stream<int> watchSumTotalMediaCounter() {
    final query = selectOnly(groups)
      ..addColumns([groups.totalMediaCounter.sum()]);
    return query.watch().map((rows) {
      final expr = rows.first.read(groups.totalMediaCounter.sum());
      return expr ?? 0;
    });
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
