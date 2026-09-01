import 'package:drift/drift.dart';
import 'package:twonly/src/database/tables/contact_groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';

part 'contact_groups.dao.g.dart';

@DriftAccessor(tables: [ContactGroups, ContactGroupMembers])
class ContactGroupsDao extends DatabaseAccessor<TwonlyDB>
    with _$ContactGroupsDaoMixin {
  ContactGroupsDao(super.db);

  Stream<List<ContactGroup>> watchAllContactGroups() {
    return (select(
      contactGroups,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  Stream<List<ContactGroup>> watchShortcutContactGroups() {
    return (select(contactGroups)
          ..where((t) => t.showAsShortcut.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.usageCounter)]))
        .watch();
  }

  Stream<List<ContactGroup>> watchVisibleGroupsForUser(int userId) {
    final query =
        select(contactGroupMembers).join([
            innerJoin(
              contactGroups,
              contactGroups.id.equalsExp(contactGroupMembers.contactGroupId),
            ),
          ])
          ..where(
            contactGroupMembers.userId.equals(userId) &
                contactGroups.showAsLabel.equals(true),
          )
          ..orderBy([OrderingTerm.asc(contactGroups.name)]);
    return query.map((row) => row.readTable(contactGroups)).watch();
  }

  Stream<List<ContactGroup>> watchVisibleGroupsForGroup(String groupId) {
    final query =
        select(contactGroupMembers).join([
            innerJoin(
              contactGroups,
              contactGroups.id.equalsExp(contactGroupMembers.contactGroupId),
            ),
          ])
          ..where(
            contactGroupMembers.groupId.equals(groupId) &
                contactGroups.showAsLabel.equals(true),
          )
          ..orderBy([OrderingTerm.asc(contactGroups.name)]);
    return query.map((row) => row.readTable(contactGroups)).watch();
  }

  Stream<List<(int, ContactGroup)>> watchAllVisibleUserGroups() {
    final query =
        select(contactGroupMembers).join([
          innerJoin(
            contactGroups,
            contactGroups.id.equalsExp(contactGroupMembers.contactGroupId),
          ),
        ])..where(
          contactGroupMembers.userId.isNotNull() &
              contactGroups.showAsLabel.equals(true),
        );
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              row.readTable(contactGroupMembers).userId!,
              row.readTable(contactGroups),
            ),
          )
          .toList(),
    );
  }

  Stream<List<(String, ContactGroup)>> watchAllVisibleChatGroups() {
    final query =
        select(contactGroupMembers).join([
          innerJoin(
            contactGroups,
            contactGroups.id.equalsExp(contactGroupMembers.contactGroupId),
          ),
        ])..where(
          contactGroupMembers.groupId.isNotNull() &
              contactGroups.showAsLabel.equals(true),
        );
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              row.readTable(contactGroupMembers).groupId!,
              row.readTable(contactGroups),
            ),
          )
          .toList(),
    );
  }

  Stream<Set<int>> watchContactGroupIdsForUser(int userId) {
    return (select(contactGroupMembers)..where((t) => t.userId.equals(userId)))
        .watch()
        .map((rows) => rows.map((row) => row.contactGroupId).toSet());
  }

  Stream<Set<int>> watchContactGroupIdsForGroup(String groupId) {
    return (select(
      contactGroupMembers,
    )..where((t) => t.groupId.equals(groupId))).watch().map(
      (rows) => rows.map((row) => row.contactGroupId).toSet(),
    );
  }

  Future<ContactGroup?> getContactGroup(int id) {
    return (select(
      contactGroups,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<ContactGroupMember>> getMembers(int contactGroupId) {
    return (select(
      contactGroupMembers,
    )..where((t) => t.contactGroupId.equals(contactGroupId))).get();
  }

  Future<int> createContactGroup({
    required String name,
    required int textColor,
    required int backgroundColor,
    required bool showAsShortcut,
    required bool showAsLabel,
    String? emoji,
  }) {
    return into(contactGroups).insert(
      ContactGroupsCompanion.insert(
        name: _sanitizeName(name),
        emoji: Value(_sanitizeEmoji(emoji)),
        textColor: textColor,
        backgroundColor: backgroundColor,
        showAsShortcut: Value(showAsShortcut),
        showAsLabel: Value(showAsLabel),
      ),
    );
  }

  Future<bool> updateContactGroup({
    required int id,
    required String name,
    required int textColor,
    required int backgroundColor,
    required bool showAsShortcut,
    required bool showAsLabel,
    String? emoji,
  }) {
    return (update(contactGroups)..where((t) => t.id.equals(id)))
        .write(
          ContactGroupsCompanion(
            name: Value(_sanitizeName(name)),
            emoji: Value(_sanitizeEmoji(emoji)),
            textColor: Value(textColor),
            backgroundColor: Value(backgroundColor),
            showAsShortcut: Value(showAsShortcut),
            showAsLabel: Value(showAsLabel),
          ),
        )
        .then((rows) => rows > 0);
  }

  Future<void> setUserMembership(
    int contactGroupId,
    int userId,
    bool selected,
  ) async {
    await transaction(() async {
      await (delete(contactGroupMembers)..where(
            (t) =>
                t.contactGroupId.equals(contactGroupId) &
                t.userId.equals(userId),
          ))
          .go();
      if (selected) {
        await into(contactGroupMembers).insert(
          ContactGroupMembersCompanion.insert(
            contactGroupId: contactGroupId,
            userId: Value(userId),
          ),
        );
      }
    });
  }

  Future<void> setGroupMembership(
    int contactGroupId,
    String groupId,
    bool selected,
  ) async {
    if (selected) {
      final group =
          await (select(attachedDatabase.groups)..where(
                (group) =>
                    group.groupId.equals(groupId) &
                    group.isDirectChat.equals(false),
              ))
              .getSingleOrNull();
      // Direct chats carry their labels through the contact instead.
      if (group == null) return;
    }
    await transaction(() async {
      await (delete(contactGroupMembers)..where(
            (t) =>
                t.contactGroupId.equals(contactGroupId) &
                t.groupId.equals(groupId),
          ))
          .go();
      if (selected) {
        await into(contactGroupMembers).insert(
          ContactGroupMembersCompanion.insert(
            contactGroupId: contactGroupId,
            groupId: Value(groupId),
          ),
        );
      }
    });
  }

  Future<void> replaceMembers(
    int contactGroupId, {
    required Iterable<int> userIds,
    required Iterable<String> groupIds,
  }) async {
    final requestedUserIds = userIds.toSet();
    final requestedGroupIds = groupIds.toSet();
    final validGroupIds = requestedGroupIds.isEmpty
        ? const <String>[]
        : await (select(attachedDatabase.groups)..where(
                (group) =>
                    group.groupId.isIn(requestedGroupIds) &
                    group.isDirectChat.equals(false),
              ))
              .map((group) => group.groupId)
              .get();
    await transaction(() async {
      await (delete(
        contactGroupMembers,
      )..where((t) => t.contactGroupId.equals(contactGroupId))).go();
      final members = [
        ...requestedUserIds.map(
          (userId) => ContactGroupMembersCompanion.insert(
            contactGroupId: contactGroupId,
            userId: Value(userId),
          ),
        ),
        ...validGroupIds.map(
          (groupId) => ContactGroupMembersCompanion.insert(
            contactGroupId: contactGroupId,
            groupId: Value(groupId),
          ),
        ),
      ];
      if (members.isNotEmpty) {
        await batch(
          (batch) => batch.insertAll(contactGroupMembers, members),
        );
      }
    });
  }

  Future<void> incrementUsage(int contactGroupId) async {
    await customStatement(
      'UPDATE contact_groups '
      'SET usage_counter = usage_counter + 1 WHERE id = ?',
      [contactGroupId],
    );
    notifyUpdates({
      TableUpdate.onTable(contactGroups, kind: UpdateKind.update),
    });
  }

  Future<int> deleteContactGroup(int id) {
    return (delete(contactGroups)..where((t) => t.id.equals(id))).go();
  }

  static String _sanitizeName(String name) {
    final trimmed = name.trim();
    return trimmed.length > 24 ? trimmed.substring(0, 24) : trimmed;
  }

  static String? _sanitizeEmoji(String? emoji) {
    final trimmed = emoji?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
