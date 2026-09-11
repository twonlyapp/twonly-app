import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/user.service.dart';

import '../mocks/user_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      ..registerSingleton<UserService>(UserService());

    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'observer',
      displayName: 'Observer',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 119,
    );
    userService.isUserCreated = true;

    await twonlyDB.customStatement(
      "INSERT INTO user_discovery_announced_users "
      "(announced_user_id, announced_public_key, public_id, username) "
      "VALUES (99, x'01', 999, 'suggested')",
    );
    for (final id in [10, 11, 12]) {
      await twonlyDB.customStatement(
        'INSERT INTO contacts(user_id, username, accepted) '
        "VALUES ($id, 'friend$id', 1)",
      );
    }
  });

  tearDown(() async {
    await twonlyDB.close();
  });

  Future<void> addRelation(int friendId) {
    return twonlyDB.customStatement(
      'INSERT INTO user_discovery_user_relations '
      '(announced_user_id, from_contact_id) VALUES (99, $friendId)',
    );
  }

  test('suggestions and request context require three valid friends', () async {
    await addRelation(10);
    await addRelation(11);

    expect(
      await twonlyDB.userDiscoveryDao
          .watchNewAnnouncedUsersWithRelations()
          .first,
      isEmpty,
    );
    expect(
      await twonlyDB.userDiscoveryDao
          .watchAllAnnouncedUsersWithRelations()
          .first,
      isEmpty,
    );
    expect(
      await twonlyDB.userDiscoveryDao
          .watchNewAnnouncementsWithDataCount()
          .first,
      0,
    );

    await addRelation(12);

    expect(
      await twonlyDB.userDiscoveryDao
          .watchNewAnnouncedUsersWithRelations()
          .first,
      hasLength(1),
    );
    expect(
      await twonlyDB.userDiscoveryDao
          .watchAllAnnouncedUsersWithRelations()
          .first,
      hasLength(1),
    );
    expect(
      await twonlyDB.userDiscoveryDao
          .watchNewAnnouncementsWithDataCount()
          .first,
      1,
    );

    await twonlyDB.customStatement(
      'UPDATE contacts SET blocked = 1 WHERE user_id = 12',
    );

    expect(
      await twonlyDB.userDiscoveryDao
          .watchNewAnnouncedUsersWithRelations()
          .first,
      isEmpty,
    );
  });
}
