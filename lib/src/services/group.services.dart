import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:hashlib/random.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/ecc/ed25519.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/http/http_requests.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/groups.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

String getGroupStateUrl() {
  return 'http${apiService.apiSecure}://${apiService.apiHost}/api/group/state';
}

String getGroupChallengeUrl() {
  return 'http${apiService.apiSecure}://${apiService.apiHost}/api/group/challenge';
}

Future<bool> createNewGroup(String groupName, List<Contact> members) async {
  // First: Upload new State to the server.....
  // if (groupName) return;

  final groupId = uuid.v4();

  final memberIds = members.map((x) => Int64(x.userId)).toList();

  final groupState = EncryptedGroupState(
    memberIds: [Int64(gUser.userId)] + memberIds,
    adminIds: [Int64(gUser.userId)],
    groupName: groupName,
    deleteMessagesAfterMilliseconds:
        Int64(defaultDeleteMessagesAfterMilliseconds),
    padding: List<int>.generate(Random().nextInt(80), (_) => 0),
  );

  final stateEncryptionKey = getRandomUint8List(32);
  final chacha20 = FlutterChacha20.poly1305Aead();
  final encryptionNonce = chacha20.newNonce();

  final secretBox = await chacha20.encrypt(
    groupState.writeToBuffer(),
    secretKey: SecretKey(stateEncryptionKey),
    nonce: encryptionNonce,
  );

  final encryptedGroupState = EncryptedGroupStateEnvelop(
    nonce: encryptionNonce,
    encryptedGroupState: secretBox.cipherText,
    mac: secretBox.mac.bytes,
  );

  final myGroupKey = generateIdentityKeyPair();

  {
    // Upload the group state, if this fails, the group can not be created.

    final newGroupState = NewGroupState(
      groupId: groupId,
      versionId: Int64(1),
      encryptedGroupState: encryptedGroupState.writeToBuffer(),
      publicKey: myGroupKey.getPublicKey().serialize(),
    );

    final response = await http
        .post(
          Uri.parse(getGroupStateUrl()),
          body: newGroupState.writeToBuffer(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      Log.error(
        'Could not upload group state. Got status code ${response.statusCode} from server.',
      );
      return false;
    }
  }

  final group = await twonlyDB.groupsDao.createNewGroup(
    GroupsCompanion(
      groupId: Value(groupId),
      groupName: Value(groupName),
      isGroupAdmin: const Value(true),
      stateEncryptionKey: Value(stateEncryptionKey),
      stateVersionId: const Value(1),
      myGroupPrivateKey: Value(myGroupKey.serialize()),
      joinedGroup: const Value(true),
    ),
  );

  if (group == null) {
    Log.error('Could not insert group into database.');
    return false;
  }

  Log.info('Created new group: ${group.groupId}');

  for (final member in members) {
    await twonlyDB.groupsDao.insertOrUpdateGroupMember(
      GroupMembersCompanion(
        groupId: Value(group.groupId),
        contactId: Value(member.userId),
        memberState: const Value(MemberState.normal),
      ),
    );
  }

  await twonlyDB.groupsDao.insertGroupAction(
    GroupHistoriesCompanion(
      groupId: Value(groupId),
      type: const Value(GroupActionType.createdGroup),
    ),
  );

  // Notify members about the new group :)

  await sendCipherTextToGroup(
    group.groupId,
    EncryptedContent(
      groupCreate: EncryptedContent_GroupCreate(
        stateKey: stateEncryptionKey,
        groupPublicKey: myGroupKey.getPublicKey().serialize(),
      ),
    ),
  );

  return true;
}

Future<void> fetchGroupStatesForUnjoinedGroups() async {
  final groups = await twonlyDB.groupsDao.getAllNotJoinedGroups();

  for (final group in groups) {
    await fetchGroupState(group);
  }
}

Future<void> fetchMissingGroupPublicKey() async {
  final members = await twonlyDB.groupsDao.getAllGroupMemberWithoutPublicKey();

  for (final member in members) {
    if (member.lastMessage == null) continue;
    // only request if the users has send a message in the last two days.
    if (member.lastMessage!
        .isAfter(DateTime.now().subtract(const Duration(days: 2)))) {
      await sendCipherText(
        member.contactId,
        EncryptedContent(
          groupId: member.groupId,
          resendGroupPublicKey: EncryptedContent_ResendGroupPublicKey(),
        ),
      );
    }
  }
}

Future<List<int>?> _decryptEnvelop(
  Group group,
  List<int> encryptedGroupState,
) async {
  try {
    final envelope = EncryptedGroupStateEnvelop.fromBuffer(
      encryptedGroupState,
    );
    final chacha20 = FlutterChacha20.poly1305Aead();

    final secretBox = SecretBox(
      envelope.encryptedGroupState,
      nonce: envelope.nonce,
      mac: Mac(envelope.mac),
    );

    final encryptedGroupStateRaw = await chacha20.decrypt(
      secretBox,
      secretKey: SecretKey(group.stateEncryptionKey!),
    );

    return encryptedGroupStateRaw;
  } catch (e) {
    Log.error(e);
    return null;
  }
}

Future<(int, EncryptedGroupState)?> fetchGroupState(Group group) async {
  try {
    var isSuccess = true;

    final response = await http
        .get(
          Uri.parse('${getGroupStateUrl()}/${group.groupId}'),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      if (response.statusCode == 404) {
        // group does not exists any more.
        await twonlyDB.groupsDao.updateGroup(
          group.groupId,
          const GroupsCompanion(
            leftGroup: Value(true),
          ),
        );
      }
      Log.error(
        'Could not load group state. Got status code ${response.statusCode} from server.',
      );
      return null;
    }

    final groupStateServer = GroupState.fromBuffer(response.bodyBytes);

    final encryptedStateRaw =
        await _decryptEnvelop(group, groupStateServer.encryptedGroupState);
    if (encryptedStateRaw == null) return null;

    final encryptedGroupState =
        EncryptedGroupState.fromBuffer(encryptedStateRaw);

    if (group.stateVersionId >= groupStateServer.versionId.toInt()) {
      Log.info(
        'Group ${group.groupId} has already newest group state from the server!',
      );
    }

    final memberIds = List<Int64>.from(encryptedGroupState.memberIds);
    final adminIds = List<Int64>.from(encryptedGroupState.adminIds);

    for (final appendedState in groupStateServer.appendedGroupStates) {
      final identityKey = IdentityKey.fromBytes(
        Uint8List.fromList(appendedState.appendTBS.publicKey),
        0,
      );

      final valid = Curve.verifySignature(
        identityKey.publicKey,
        appendedState.appendTBS.writeToBuffer(),
        Uint8List.fromList(appendedState.signature),
      );

      if (!valid) {
        Log.error('Invalid signature for the appendedState');
        continue;
      }

      final encryptedStateRaw = await _decryptEnvelop(
        group,
        appendedState.appendTBS.encryptedGroupStateAppend,
      );
      if (encryptedStateRaw == null) continue;

      final appended =
          EncryptedAppendedGroupState.fromBuffer(encryptedStateRaw);
      if (appended.type == EncryptedAppendedGroupState_Type.LEFT_GROUP) {
        final keyPair =
            IdentityKeyPair.fromSerialized(group.myGroupPrivateKey!);

        final appendedPubKey = appendedState.appendTBS.publicKey;
        final myPubKey = keyPair.getPublicKey().serialize().toList();

        if (listEquals(appendedPubKey, myPubKey)) {
          adminIds.remove(Int64(gUser.userId));
          memberIds
              .remove(Int64(gUser.userId)); // -> Will remove the user later...
        } else {
          Log.info('A non admin left the group!!!');

          final member = await twonlyDB.groupsDao
              .getGroupMemberByPublicKey(Uint8List.fromList(appendedPubKey));
          if (member == null) {
            Log.error('Member is already not in this group...');
            continue;
          }
          adminIds.remove(Int64(member.contactId));
          memberIds.remove(Int64(member.contactId));
        }
      }
    }

    if (!memberIds.contains(Int64(gUser.userId))) {
      // OH no, I am no longer a member of this group...
      // Return from the group...
      await twonlyDB.groupsDao.updateGroup(
        group.groupId,
        const GroupsCompanion(
          leftGroup: Value(true),
        ),
      );
      return (groupStateServer.versionId.toInt(), encryptedGroupState);
    }

    final isGroupAdmin =
        adminIds.firstWhereOrNull((t) => t.toInt() == gUser.userId) != null;

    if (!listEquals(memberIds, encryptedGroupState.memberIds)) {
      if (isGroupAdmin) {
        try {
          // this removes the appended_group_state from the server and merges the changes into the main group state
          final newState = EncryptedGroupState(
            groupName: encryptedGroupState.groupName,
            deleteMessagesAfterMilliseconds:
                encryptedGroupState.deleteMessagesAfterMilliseconds,
            memberIds: memberIds,
            adminIds: adminIds,
            padding: List<int>.generate(Random().nextInt(80), (_) => 0),
          );
          // send new state to the server
          if (!await _updateGroupState(
            group,
            newState,
            versionId: groupStateServer.versionId.toInt() + 1,
          )) {
            // could not update the group state...
            Log.error('Update the state to remove the appended state...');
            return null;
          }
          // the state is now updated and the appended_group_state should be removed on the server, so just call this
          // function again, to sync the local database
          return fetchGroupState(group);
        } catch (e) {
          Log.error(e);
          return null;
        }
      }
      // in case this is not an admin, just work with the new memberIds and adminIds...
    }

    await twonlyDB.groupsDao.updateGroup(
      group.groupId,
      GroupsCompanion(
        groupName: Value(encryptedGroupState.groupName),
        deleteMessagesAfterMilliseconds: Value(
          encryptedGroupState.deleteMessagesAfterMilliseconds.toInt(),
        ),
        isGroupAdmin: Value(isGroupAdmin),
      ),
    );

    var currentGroupMembers =
        await twonlyDB.groupsDao.getGroupNonLeftMembers(group.groupId);

    // First find and insert NEW members
    for (final memberId in memberIds) {
      if (memberId == Int64(gUser.userId)) {
        continue;
      }
      if (currentGroupMembers.any((t) => t.contactId == memberId.toInt())) {
        // User is already in the database
        continue;
      }
      Log.info('New member in the GROUP state: $memberId');

      var inContacts = true;

      if (await twonlyDB.contactsDao.getContactById(memberId.toInt()) == null) {
        // User is not yet in the contacts, add him in the hidden. So he is not in the contact list / needs to be
        // requested separately.
        if (!await addNewHiddenContact(memberId.toInt())) {
          Log.error('Could not request member ID will retry later.');
          isSuccess = false;
          inContacts = false;
        }
      }
      if (inContacts) {
        // User is already a contact, so just add him to the group members list
        await twonlyDB.groupsDao.insertOrUpdateGroupMember(
          GroupMembersCompanion(
            groupId: Value(group.groupId),
            contactId: Value(memberId.toInt()),
            memberState: const Value(MemberState.normal),
          ),
        );
      }

      // Send the new user my public group key
      if (group.myGroupPrivateKey != null) {
        final keyPair =
            IdentityKeyPair.fromSerialized(group.myGroupPrivateKey!);
        await sendCipherText(
          memberId.toInt(),
          EncryptedContent(
            groupJoin: EncryptedContent_GroupJoin(
              groupPublicKey: keyPair.getPublicKey().serialize(),
            ),
          ),
        );
      }
    }

    // check if there is a member which is not in the server list...

    // update the current members list
    currentGroupMembers =
        await twonlyDB.groupsDao.getGroupNonLeftMembers(group.groupId);

    for (final member in currentGroupMembers) {
      // Member is not any more in the members list
      if (!encryptedGroupState.memberIds.contains(Int64(member.contactId))) {
        await twonlyDB.groupsDao.removeMember(group.groupId, member.contactId);
        continue;
      }

      MemberState? newMemberState;

      if (adminIds.contains(Int64(member.contactId))) {
        if (member.memberState == MemberState.normal) {
          // user was promoted
          newMemberState = MemberState.admin;
        }
      } else if (member.memberState == MemberState.admin) {
        // user was demoted
        newMemberState = MemberState.normal;
      }

      if (newMemberState != null) {
        await twonlyDB.groupsDao.updateMember(
          group.groupId,
          member.contactId,
          GroupMembersCompanion(
            memberState: Value(newMemberState),
          ),
        );
      }
    }

    if (isSuccess) {
      // in case not all members could be loaded from the server,
      // this will ensure it will be tried again later
      await twonlyDB.groupsDao.updateGroup(
        group.groupId,
        GroupsCompanion(
          stateVersionId: Value(groupStateServer.versionId.toInt()),
          joinedGroup: const Value(true),
        ),
      );
    }
    return (groupStateServer.versionId.toInt(), encryptedGroupState);
  } catch (e) {
    Log.error(e);
    return null;
  }
}

Future<bool> addNewHiddenContact(int contactId) async {
  final userData = await apiService.getUserById(contactId);
  if (userData == null) {
    Log.error('Could not load contact informations');
    return false;
  }
  await twonlyDB.contactsDao.insertOnConflictUpdate(
    ContactsCompanion(
      username: Value(utf8.decode(userData.username)),
      userId: Value(contactId),
      deletedByUser:
          const Value(true), // this will hide the contact in the contact list
    ),
  );
  await createNewSignalSession(userData);
  unawaited(setupNotificationWithUsers(forceContact: contactId));
  return true;
}

Future<bool> _updateGroupState(
  Group group,
  EncryptedGroupState state, {
  Uint8List? addAdmin,
  Uint8List? removeAdmin,
  int? versionId,
}) async {
  final chacha20 = FlutterChacha20.poly1305Aead();
  final encryptionNonce = chacha20.newNonce();

  final secretBox = await chacha20.encrypt(
    state.writeToBuffer(),
    secretKey: SecretKey(group.stateEncryptionKey!),
    nonce: encryptionNonce,
  );

  final encryptedGroupState = EncryptedGroupStateEnvelop(
    nonce: encryptionNonce,
    encryptedGroupState: secretBox.cipherText,
    mac: secretBox.mac.bytes,
  );

  {
    // Upload the group state, if this fails, the group can not be created.

    final keyPair = IdentityKeyPair.fromSerialized(group.myGroupPrivateKey!);

    final nonce = await getNonce(keyPair.getPublicKey().serialize());
    if (nonce == null) return false;

    final updateTBS = UpdateGroupState_UpdateTBS(
      versionId: Int64(versionId ?? group.stateVersionId + 1),
      encryptedGroupState: encryptedGroupState.writeToBuffer(),
      publicKey: keyPair.getPublicKey().serialize(),
      nonce: nonce,
      addAdmin: addAdmin,
      removeAdmin: removeAdmin,
    );

    final random = getRandomUint8List(32);
    final signature = sign(
      keyPair.getPrivateKey().serialize(),
      updateTBS.writeToBuffer(),
      random,
    );

    final newGroupState = UpdateGroupState(
      update: updateTBS,
      signature: signature,
    );

    final response = await http
        .patch(
          Uri.parse(getGroupStateUrl()),
          body: newGroupState.writeToBuffer(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      Log.error(
        'Could not patch group state. Got status code ${response.statusCode} from server.',
      );
      return false;
    }
  }
  return true;
}

Future<bool> manageAdminState(
  Group group,
  Uint8List groupPublicKey,
  int contactId,
  bool remove,
) async {
  // ensure the latest state is used
  final currentState = await fetchGroupState(group);
  if (currentState == null) return false;
  final (versionId, state) = currentState;

  final userId = Int64(contactId);

  Uint8List? addAdmin;
  Uint8List? removeAdmin;

  if (remove) {
    if (state.adminIds.contains(userId)) {
      state.adminIds.remove(userId);
      removeAdmin = groupPublicKey;
    } else {
      Log.info('User was already removed as admin.');
      return true;
    }
  } else {
    if (!state.adminIds.contains(userId)) {
      state.adminIds.add(userId);
      addAdmin = groupPublicKey;
    } else {
      Log.info('User is already admin.');
      return true;
    }
  }

  if (addAdmin == null && removeAdmin == null) {
    Log.info('User does not have a group public key.');
    return false;
  }

  // send new state to the server
  if (!await _updateGroupState(
    group,
    state,
    addAdmin: addAdmin,
    removeAdmin: removeAdmin,
  )) {
    return false;
  }

  final groupActionType =
      remove ? GroupActionType.demoteToMember : GroupActionType.promoteToAdmin;

  await sendCipherTextToGroup(
    group.groupId,
    EncryptedContent(
      groupUpdate: EncryptedContent_GroupUpdate(
        groupActionType: groupActionType.name,
        affectedContactId: Int64(contactId),
      ),
    ),
  );

  await twonlyDB.groupsDao.insertGroupAction(
    GroupHistoriesCompanion(
      groupId: Value(group.groupId),
      type: Value(groupActionType),
      affectedContactId: Value(contactId),
    ),
  );

  // Updates the memberState  :)
  return (await fetchGroupState(group)) != null;
}

Future<bool> updateGroupName(Group group, String groupName) async {
  // ensure the latest state is used
  final currentState = await fetchGroupState(group);
  if (currentState == null) return false;
  final (versionId, state) = currentState;

  state.groupName = groupName;

  // send new state to the server
  if (!await _updateGroupState(group, state)) {
    return false;
  }

  await sendCipherTextToGroup(
    group.groupId,
    EncryptedContent(
      groupUpdate: EncryptedContent_GroupUpdate(
        groupActionType: GroupActionType.updatedGroupName.name,
        newGroupName: groupName,
      ),
    ),
  );

  await twonlyDB.groupsDao.insertGroupAction(
    GroupHistoriesCompanion(
      groupId: Value(group.groupId),
      type: const Value(GroupActionType.updatedGroupName),
      oldGroupName: Value(group.groupName),
      newGroupName: Value(groupName),
    ),
  );

  // Updates the groupName  :)
  return (await fetchGroupState(group)) != null;
}

Future<bool> updateChatDeletionTime(
  Group group,
  int deleteMessagesAfterMilliseconds,
) async {
  // ensure the latest state is used
  final currentState = await fetchGroupState(group);
  if (currentState == null) return false;
  final (versionId, state) = currentState;

  state.deleteMessagesAfterMilliseconds =
      Int64(deleteMessagesAfterMilliseconds);

  // send new state to the server
  if (!await _updateGroupState(group, state)) {
    return false;
  }

  await sendCipherTextToGroup(
    group.groupId,
    EncryptedContent(
      groupUpdate: EncryptedContent_GroupUpdate(
        groupActionType: GroupActionType.changeDisplayMaxTime.name,
        newDeleteMessagesAfterMilliseconds: Int64(
          deleteMessagesAfterMilliseconds,
        ),
      ),
    ),
  );

  await twonlyDB.groupsDao.insertGroupAction(
    GroupHistoriesCompanion(
      groupId: Value(group.groupId),
      type: const Value(GroupActionType.changeDisplayMaxTime),
      newDeleteMessagesAfterMilliseconds:
          Value(deleteMessagesAfterMilliseconds),
    ),
  );

  // Updates the groupName  :)
  return (await fetchGroupState(group)) != null;
}

Future<bool> addNewGroupMembers(
  Group group,
  List<int> newGroupMemberIds,
) async {
  // ensure the latest state is used
  final currentState = await fetchGroupState(group);
  if (currentState == null) return false;
  final (versionId, state) = currentState;

  var memberIds = state.memberIds + newGroupMemberIds.map(Int64.new).toList();
  memberIds = memberIds.toSet().toList();

  final newState = EncryptedGroupState(
    groupName: state.groupName,
    deleteMessagesAfterMilliseconds: state.deleteMessagesAfterMilliseconds,
    memberIds: memberIds,
    adminIds: state.adminIds,
    padding: List<int>.generate(Random().nextInt(80), (_) => 0),
  );

  // send new state to the server
  if (!await _updateGroupState(group, newState)) {
    return false;
  }

  final keyPair = IdentityKeyPair.fromSerialized(group.myGroupPrivateKey!);

  for (final newMember in newGroupMemberIds) {
    await sendCipherTextToGroup(
      group.groupId,
      EncryptedContent(
        groupUpdate: EncryptedContent_GroupUpdate(
          groupActionType: GroupActionType.addMember.name,
          affectedContactId: Int64(newMember),
        ),
      ),
    );

    await twonlyDB.groupsDao.insertGroupAction(
      GroupHistoriesCompanion(
        groupId: Value(group.groupId),
        type: const Value(GroupActionType.addMember),
        affectedContactId: Value(newMember),
      ),
    );

    await sendCipherText(
      newMember,
      EncryptedContent(
        groupId: group.groupId,
        groupCreate: EncryptedContent_GroupCreate(
          stateKey: group.stateEncryptionKey,
          groupPublicKey: keyPair.getPublicKey().serialize(),
        ),
      ),
    );
  }

  // Updates the groupMembers table :)
  return (await fetchGroupState(group)) != null;
}

Future<bool> removeMemberFromGroup(
  Group group,
  Uint8List groupPublicKey,
  int removeContactId,
) async {
  // ensure the latest state is used
  final currentState = await fetchGroupState(group);
  if (currentState == null) return false;
  final (versionId, state) = currentState;

  final contactId = Int64(removeContactId);

  final membersIdSet = state.memberIds.toSet();
  final adminIdSet = state.adminIds.toSet();
  Uint8List? removeAdmin;
  if (!membersIdSet.contains(contactId)) {
    Log.info('User was already removed from the group!');
    return true;
  }
  if (adminIdSet.contains(contactId)) {
    // if (member.groupPublicKey == null) {
    //   // If the admin public key is not removed, that the user could potentially still update the group state. So only
    //   // allow the user removal, if this key is known. It is better the users can not remove the other user, then
    //   // the he can but the other user, could still update the group state.
    //   Log.error(
    //     'Could not remove user. User is admin, but groupPublicKey is unknown.',
    //   );
    //   return false;
    // }
    removeAdmin = groupPublicKey;
  }

  membersIdSet.remove(contactId);
  adminIdSet.remove(contactId);

  final newState = EncryptedGroupState(
    groupName: state.groupName,
    deleteMessagesAfterMilliseconds: state.deleteMessagesAfterMilliseconds,
    memberIds: membersIdSet.toList(),
    adminIds: adminIdSet.toList(),
    padding: List<int>.generate(Random().nextInt(80), (_) => 0),
  );

  // send new state to the server
  if (!await _updateGroupState(group, newState, removeAdmin: removeAdmin)) {
    return false;
  }

  await sendCipherTextToGroup(
    group.groupId,
    EncryptedContent(
      groupUpdate: EncryptedContent_GroupUpdate(
        groupActionType: GroupActionType.removedMember.name,
        affectedContactId: Int64(removeContactId),
      ),
    ),
  );

  await twonlyDB.groupsDao.insertGroupAction(
    GroupHistoriesCompanion(
      groupId: Value(group.groupId),
      type: const Value(GroupActionType.removedMember),
      affectedContactId: Value(
        removeContactId == gUser.userId ? null : removeContactId,
      ),
    ),
  );

  // Updates the groupMembers table :)
  return (await fetchGroupState(group)) != null;
}

Future<Uint8List?> getNonce(Uint8List publicKey) async {
  final publicKeyHex = uint8ListToHex(publicKey);

  final responseNonce = await http
      .get(
        Uri.parse('${getGroupChallengeUrl()}/$publicKeyHex'),
      )
      .timeout(const Duration(seconds: 10));

  if (responseNonce.statusCode != 200) {
    Log.error(
      'Could not load nonce. Got status code ${responseNonce.statusCode} from server.',
    );
    return null;
  }
  return responseNonce.bodyBytes;
}

Future<bool> leaveAsNonAdminFromGroup(Group group) async {
  final currentState = await fetchGroupState(group);
  if (currentState == null) {
    Log.error('Could not load current state');
    return false;
  }

  final (version, _) = currentState;
  if (group.stateVersionId != version) {
    Log.error('Version is not valid. Just retry.');
    return false;
  }

  final chacha20 = FlutterChacha20.poly1305Aead();
  final encryptionNonce = chacha20.newNonce();

  final state = EncryptedAppendedGroupState(
    type: EncryptedAppendedGroupState_Type.LEFT_GROUP,
  );

  final secretBox = await chacha20.encrypt(
    state.writeToBuffer(),
    secretKey: SecretKey(group.stateEncryptionKey!),
    nonce: encryptionNonce,
  );

  final encryptedGroupStateAppend = EncryptedGroupStateEnvelop(
    nonce: encryptionNonce,
    encryptedGroupState: secretBox.cipherText,
    mac: secretBox.mac.bytes,
  );

  {
    // Upload the group state, if this fails, the group can not be created.

    final keyPair = IdentityKeyPair.fromSerialized(group.myGroupPrivateKey!);

    final nonce = await getNonce(keyPair.getPublicKey().serialize());
    if (nonce == null) return false;

    final appendTBS = AppendGroupState_AppendTBS(
      publicKey: keyPair.getPublicKey().serialize(),
      encryptedGroupStateAppend: encryptedGroupStateAppend.writeToBuffer(),
      groupId: group.groupId,
      nonce: nonce,
    );

    final random = getRandomUint8List(32);
    final signature = sign(
      keyPair.getPrivateKey().serialize(),
      appendTBS.writeToBuffer(),
      random,
    );

    final newGroupState = AppendGroupState(
      versionId: Int64(group.stateVersionId + 1),
      appendTBS: appendTBS,
      signature: signature,
    );

    final response = await http
        .post(
          Uri.parse('${getGroupStateUrl()}/append'),
          body: newGroupState.writeToBuffer(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      Log.error(
        'Could not patch group state. Got status code ${response.statusCode} from server.',
      );
      return false;
    }
  }
  const groupActionType = GroupActionType.leftGroup;
  await sendCipherTextToGroup(
    group.groupId,
    EncryptedContent(
      groupUpdate: EncryptedContent_GroupUpdate(
        groupActionType: groupActionType.name,
        affectedContactId: Int64(gUser.userId),
      ),
    ),
  );

  await twonlyDB.groupsDao.insertGroupAction(
    GroupHistoriesCompanion(
      groupId: Value(group.groupId),
      type: const Value(groupActionType),
    ),
  );

  // Updates the table :)
  return (await fetchGroupState(group)) != null;
}
