import 'dart:typed_data' show Uint8List;

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:twonly/core/bridge/groups.dart' as rust_groups;
import 'package:twonly/src/database/twonly.db.dart';

Future<bool> createNewGroup(String groupName, List<Contact> members) =>
    rust_groups.createNewGroup(
      groupName: groupName,
      memberIds: Int64List.fromList(
        members.map((contact) => contact.userId).toList(),
      ),
    );

Future<void> fetchGroupStatesForUnjoinedGroups() =>
    rust_groups.fetchGroupStatesForUnjoinedGroups();
Future<void> fetchMissingGroupPublicKey() =>
    rust_groups.fetchMissingGroupPublicKeys();
Future<bool> fetchGroupState(Group group) =>
    rust_groups.fetchGroupState(groupId: group.groupId);
Future<bool> addNewHiddenContact(int contactId) =>
    rust_groups.addHiddenContact(contactId: contactId);

Future<bool> manageAdminState(
  Group group,
  Uint8List key,
  int contactId,
  bool remove,
) => rust_groups.manageAdminState(
  groupId: group.groupId,
  groupPublicKey: key,
  contactId: contactId,
  remove: remove,
);
Future<bool> updateGroupName(Group group, String name) =>
    rust_groups.updateGroupName(groupId: group.groupId, groupName: name);
Future<bool> updateChatDeletionTime(Group group, int milliseconds) =>
    rust_groups.updateChatDeletionTime(
      groupId: group.groupId,
      deleteMessagesAfterMilliseconds: milliseconds,
    );
Future<bool> addNewGroupMembers(Group group, List<int> ids) =>
    rust_groups.addNewGroupMembers(
      groupId: group.groupId,
      memberIds: Int64List.fromList(ids),
    );
Future<bool> removeMemberFromGroup(Group group, Uint8List key, int contactId) =>
    rust_groups.removeMemberFromGroup(
      groupId: group.groupId,
      groupPublicKey: key,
      contactId: contactId,
    );
Future<bool> leaveGroup(Group group) =>
    rust_groups.leaveGroup(groupId: group.groupId);
Future<bool> leaveAsNonAdminFromGroup(Group group) => leaveGroup(group);
