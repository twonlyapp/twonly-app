import 'dart:async';
import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleGroupCreate(
  int fromUserId,
  String groupId,
  EncryptedContent_GroupCreate newGroup,
) async {
  final user = await twonlyDB.contactsDao
      .getContactByUserId(fromUserId)
      .getSingleOrNull();
  if (user == null) {
    // Only contacts can invite other contacts, so this can (via the UI) not happen.
    Log.error(
      'User is not a contact. Aborting.',
    );
    return;
  }

  // 1. Store the new group -> e.g. store the stateKey and groupPublicKey
  // 2. Call function that should fetch all jobs
  //    1. This function is also called in the main function, in case the state stored on the server could not be loaded
  //    2. This function will also send the GroupJoin to all members -> so they get there public key
  // 3. Finished

  final myGroupKey = generateIdentityKeyPair();

  var group = await twonlyDB.groupsDao.getGroup(groupId);
  if (group == null) {
    // Group state is joinedGroup -> As the current state has not yet been downloaded.
    group = await twonlyDB.groupsDao.createNewGroup(
      GroupsCompanion(
        groupId: Value(groupId),
        stateVersionId: const Value(0),
        stateEncryptionKey: Value(Uint8List.fromList(newGroup.stateKey)),
        myGroupPrivateKey: Value(myGroupKey.serialize()),
        groupName: const Value(''),
        joinedGroup: const Value(false),
      ),
    );
  } else {
    // User was already in the group, so update leftGroup back to false
    await twonlyDB.groupsDao.updateGroup(
      groupId,
      GroupsCompanion(
        stateVersionId: const Value(0),
        stateEncryptionKey: Value(Uint8List.fromList(newGroup.stateKey)),
        myGroupPrivateKey: Value(myGroupKey.serialize()),
        groupName: const Value(''),
        joinedGroup: const Value(false),
        leftGroup: const Value(false),
        deletedContent: const Value(false),
      ),
    );
  }

  if (group == null) {
    Log.error(
      'Could not create new group. Probably because the group already existed.',
    );
    return;
  }

  await twonlyDB.groupsDao.insertGroupAction(
    GroupHistoriesCompanion(
      groupId: Value(groupId),
      contactId: Value(fromUserId),
      affectedContactId: const Value(null),
      type: const Value(GroupActionType.addMember),
    ),
  );

  await twonlyDB.groupsDao.insertOrUpdateGroupMember(
    GroupMembersCompanion(
      groupId: Value(groupId),
      contactId: Value(fromUserId),
      memberState: const Value(
        MemberState.admin, // is the group creator, so must be admin...
      ),
      groupPublicKey: Value(Uint8List.fromList(newGroup.groupPublicKey)),
    ),
  );

  // can be done in the background -> websocket message can be ACK
  unawaited(fetchGroupStatesForUnjoinedGroups());

  await sendCipherTextToGroup(
    groupId,
    EncryptedContent(
      groupJoin: EncryptedContent_GroupJoin(
        groupPublicKey: myGroupKey.getPublicKey().serialize(),
      ),
    ),
  );
}

Future<void> handleGroupUpdate(
  int fromUserId,
  String groupId,
  EncryptedContent_GroupUpdate update,
) async {
  Log.info('Got group update for $groupId from $fromUserId');

  final actionType = groupActionTypeFromString(update.groupActionType);
  if (actionType == null) {
    Log.error('Group action ${update.groupActionType} is unknown ignoring.');
    return;
  }

  final group = (await twonlyDB.groupsDao.getGroup(groupId))!;

  switch (actionType) {
    case GroupActionType.updatedGroupName:
      await twonlyDB.groupsDao.insertGroupAction(
        GroupHistoriesCompanion(
          groupId: Value(groupId),
          type: Value(actionType),
          oldGroupName: Value(group.groupName),
          newGroupName: Value(update.newGroupName),
          contactId: Value(fromUserId),
        ),
      );
    case GroupActionType.removedMember:
    case GroupActionType.addMember:
    case GroupActionType.leftGroup:
    case GroupActionType.promoteToAdmin:
    case GroupActionType.demoteToMember:
      int? affectedContactId = update.affectedContactId.toInt();

      if (affectedContactId == gUser.userId) {
        affectedContactId = null;
        if (actionType == GroupActionType.removedMember) {
          // Oh no, I just got removed from the group...
          // This state is handle this case in the fetchGroupState....
        }
      }

      await twonlyDB.groupsDao.insertGroupAction(
        GroupHistoriesCompanion(
          groupId: Value(groupId),
          type: Value(actionType),
          affectedContactId: Value(affectedContactId),
          contactId: Value(fromUserId),
        ),
      );
    case GroupActionType.createdGroup:
      break;
  }

  unawaited(fetchGroupState(group));
}

Future<bool> handleGroupJoin(
  int fromUserId,
  String groupId,
  EncryptedContent_GroupJoin join,
) async {
  if (await twonlyDB.contactsDao.getContactById(fromUserId) == null) {
    if (!await addNewHiddenContact(fromUserId)) {
      Log.error('Got group join, but could not load contact.');
      // This can happen in case the group join was received before the group create.
      // In this case return false, which will cause the receipt to fail and the user
      // will resend this message.
      return false;
    }
  }
  await twonlyDB.groupsDao.updateMember(
    groupId,
    fromUserId,
    GroupMembersCompanion(
      groupPublicKey: Value(Uint8List.fromList(join.groupPublicKey)),
    ),
  );
  return true;
}

Future<void> handleResendGroupPublicKey(
  int fromUserId,
  String groupId,
  EncryptedContent_GroupJoin join,
) async {
  final group = await twonlyDB.groupsDao.getGroup(groupId);
  if (group == null || group.myGroupPrivateKey == null) return;
  final keyPair = IdentityKeyPair.fromSerialized(group.myGroupPrivateKey!);
  await sendCipherText(
    fromUserId,
    EncryptedContent(
      groupId: groupId,
      groupJoin: EncryptedContent_GroupJoin(
        groupPublicKey: keyPair.getPublicKey().serialize(),
      ),
    ),
  );
}
