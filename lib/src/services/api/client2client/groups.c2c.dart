import 'dart:async';

import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/utils/log.dart';

Future<void> handleGroupCreate(
  int fromUserId,
  String groupId,
  EncryptedContent_GroupCreate newGroup,
) async {
  // 1. Store the new group -> e.g. store the stateKey and groupPublicKey
  // 2. Call function that should fetch all jobs
  //    1. This function is also called in the main function, in case the state stored on the server could not be loaded
  //    2. This function will also send the GroupJoin to all members -> so they get there public key
  // 3. Finished

  final myGroupKey = generateIdentityKeyPair();

  // Group state is joinedGroup -> As the current state has not yet been downloaded.
  final group = await twonlyDB.groupsDao.createNewGroup(
    GroupsCompanion(
      groupId: Value(groupId),
      stateVersionId: const Value(1),
      stateEncryptionKey: Value(Uint8List.fromList(newGroup.stateKey)),
      myGroupPrivateKey: Value(myGroupKey.getPrivateKey().serialize()),
    ),
  );

  if (group == null) {
    Log.error(
      'Could not create new group. Probably because the group already existed.',
    );
    return;
  }

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

  await twonlyDB.groupsDao.insertGroupMember(
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
}

Future<void> handleGroupUpdate(
  int fromUserId,
  String groupId,
  EncryptedContent_GroupUpdate update,
) async {}

Future<void> handleGroupJoin(
  int fromUserId,
  String groupId,
  EncryptedContent_GroupJoin join,
) async {}
