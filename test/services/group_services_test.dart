import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/services/user.service.dart';

class RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  if (!Platform.isMacOS) {
    return;
  }

  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = RealHttpOverrides();

  setUp(() async {
    await locator.reset();
    locator
      ..registerSingleton<TwonlyDB>(
        TwonlyDB.forTesting(
          DatabaseConnection(
            NativeDatabase.memory(),
            closeStreamsSynchronously: true,
          ),
        ),
      )
      ..registerSingleton<UserService>(UserService())
      ..registerSingleton<ApiService>(ApiService());

    userService.currentUser = UserData(
      userId: 1,
      username: 'test_user',
      displayName: 'Test User',
      subscriptionPlan: 'Free',
    )..appVersion = 100;
    userService.isUserCreated = true;
    AppEnvironment.initTesting();
    // Log.init();

    expect(apiService.apiHost, 'dev-api.twonly.eu');
  });

  tearDown(() async {
    await twonlyDB.close();
  });

  group('GroupServices Tests', () {
    Future<Group> createTestGroup() async {
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(
          userId: const Value(2),
          username: 'user2',
        ),
      );
      final members = <Contact>[
        (await twonlyDB.contactsDao.getContactById(2))!,
      ];
      final result = await createNewGroup('Test Group', members);
      expect(result, true);
      return (await twonlyDB.groupsDao.getAllGroups()).first;
    }

    test('Full Group Life Cycle', () async {
      late bool success;
      // 1. Create Group
      var group = await createTestGroup();

      // 2. Add New Member
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion.insert(
          userId: const Value(3),
          username: 'user3',
        ),
      );
      success = await addNewGroupMembers(group, [3]);
      expect(success, true);

      // 3. Upgrade to Admin
      // Generate a real-looking key
      group = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
      final dummyPubKey = Curve.generateKeyPair().publicKey.serialize();
      success = await manageAdminState(group, dummyPubKey, 2, false);
      expect(success, true);

      // 4. Change Time
      group = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
      success = await updateChatDeletionTime(group, 7200000);
      expect(success, true);

      // 5. Remove Member 3
      group = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
      success = await removeMemberFromGroup(group, dummyPubKey, 3);
      expect(success, true);

      // 6. Remove Member 2
      group = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
      success = await removeMemberFromGroup(group, dummyPubKey, 2);
      expect(success, true);

      // 7. Leave Group (Myself)
      final keyPair = IdentityKeyPair.fromSerialized(
        group.myGroupPrivateKey!,
      );
      group = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
      success = await removeMemberFromGroup(
        group,
        keyPair.getPublicKey().serialize(),
        userService.currentUser.userId,
      );
      expect(success, false);

      // Final verification of DB state
      final finalGroup = await twonlyDB.groupsDao.getGroup(group.groupId);
      expect(finalGroup, isNotNull);

      final history = await twonlyDB.groupsDao
          .watchGroupActions(group.groupId)
          .first;

      expect(history.length, 7);
      expect(history[0].type, GroupActionType.createdGroup);
      expect(history[1].type, GroupActionType.addMember);
      expect(history[2].type, GroupActionType.promoteToAdmin);
      expect(history[3].type, GroupActionType.changeDisplayMaxTime);
      expect(history[4].type, GroupActionType.removedMember);
      expect(history[5].type, GroupActionType.removedMember);
      expect(history[6].type, GroupActionType.removedMember);
    });
  });
}
