import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
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
    await twonlyDB.groupsDao.insertGroupMember(
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

Future<(int, EncryptedGroupState)?> fetchGroupState(Group group) async {
  try {
    var isSuccess = true;

    final response = await http
        .get(
          Uri.parse('${getGroupStateUrl()}/${group.groupId}'),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      Log.error(
        'Could not load group state. Got status code ${response.statusCode} from server.',
      );
      return null;
    }

    final groupStateServer = GroupState.fromBuffer(response.bodyBytes);
    final envelope = EncryptedGroupStateEnvelop.fromBuffer(
      groupStateServer.encryptedGroupState,
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

    final encryptedGroupState =
        EncryptedGroupState.fromBuffer(encryptedGroupStateRaw);

    if (group.stateVersionId >= groupStateServer.versionId.toInt()) {
      Log.info(
        'Group ${group.groupId} has already newest group state from the server!',
      );
      return (groupStateServer.versionId.toInt(), encryptedGroupState);
    }

    final isGroupAdmin = encryptedGroupState.adminIds
            .firstWhereOrNull((t) => t.toInt() == gUser.userId) !=
        null;

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
        await twonlyDB.groupsDao.getGroupMembers(group.groupId);

    // First find and insert NEW members
    for (final memberId in encryptedGroupState.memberIds) {
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
        await twonlyDB.groupsDao.insertGroupMember(
          GroupMembersCompanion(
            groupId: Value(group.groupId),
            contactId: Value(memberId.toInt()),
            memberState: const Value(MemberState.normal),
          ),
        );
      }
    }

    // check if there is a member which is not in the server list...

    // update the current members list
    currentGroupMembers =
        await twonlyDB.groupsDao.getGroupMembers(group.groupId);

    for (final member in currentGroupMembers) {
      // Member is not any more in the members list
      if (!encryptedGroupState.memberIds.contains(Int64(member.contactId))) {
        await twonlyDB.groupsDao.removeMember(group.groupId, member.contactId);
        continue;
      }

      MemberState? newMemberState;

      if (encryptedGroupState.adminIds.contains(Int64(member.contactId))) {
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
  return true;
}

Future<bool> updateGroupState(Group group, EncryptedGroupState state) async {
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

    final publicKey = uint8ListToHex(keyPair.getPublicKey().serialize());

    final responseNonce = await http
        .get(
          Uri.parse('${getGroupChallengeUrl()}/$publicKey'),
        )
        .timeout(const Duration(seconds: 10));

    if (responseNonce.statusCode != 200) {
      Log.error(
        'Could not load nonce. Got status code ${responseNonce.statusCode} from server.',
      );
      return false;
    }

    final updateTBS = UpdateGroupState_UpdateTBS(
      versionId: Int64(group.stateVersionId + 1),
      encryptedGroupState: encryptedGroupState.writeToBuffer(),
      publicKey: keyPair.getPublicKey().serialize(),
      nonce: responseNonce.bodyBytes,
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

  // Update database to the newest state
  return (await fetchGroupState(group)) != null;
}

Future<bool> updateGroupeName(Group group, String groupName) async {
  // ensure the latest state is used
  final currentState = await fetchGroupState(group);
  if (currentState == null) return false;
  final (versionId, state) = currentState;

  state.groupName = groupName;

  // send new state to the server
  if (!await updateGroupState(group, state)) {
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

  return true;
}
