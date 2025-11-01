import 'dart:math';
import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
import 'package:hashlib/random.dart';
import 'package:http/http.dart' as http;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/http/http_requests.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/groups.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pbserver.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

String getGroupStateUrl() {
  return 'http${apiService.apiSecure}://${apiService.apiHost}/api/group/state';
}

Future<bool> createNewGroup(String groupName, List<Contact> members) async {
  // First: Upload new State to the server.....
  // if (groupName) return;

  final groupId = uuid.v4();

  final memberIds = members.map((x) => Int64(x.userId)).toList();

  final groupState = EncryptedGroupState(
    memberIds: memberIds,
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
      myGroupPrivateKey: Value(myGroupKey.getPrivateKey().serialize()),
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
    null,
  );

  return true;
}

Future<void> fetchGroupStatesForUnjoinedGroups() async {
  final groups = await twonlyDB.groupsDao.getAllNotJoinedGroups();

  for (final group in groups) {}
}

Future<GroupState?> fetchGroupState(Group group) async {
  try {
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
        groupStateServer.encryptedGroupState);
    final chacha20 = FlutterChacha20.poly1305Aead();

    final secretBox = SecretBox(envelope.encryptedGroupState,
        nonce: envelope.nonce, mac: Mac(envelope.mac));

    final encryptedGroupStateRaw = await chacha20.decrypt(secretBox,
        secretKey: SecretKey(group.stateEncryptionKey!));

    final encryptedGroupState =
        EncryptedGroupState.fromBuffer(encryptedGroupStateRaw);

    encryptedGroupState.adminIds;
    encryptedGroupState.memberIds;
    encryptedGroupState.groupName;
    encryptedGroupState.deleteMessagesAfterMilliseconds;
    encryptedGroupState.deleteMessagesAfterMilliseconds;
    groupStateServer.versionId;
  } catch (e) {
    Log.error(e);
    return null;
  }
}
