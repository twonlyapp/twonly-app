import 'dart:async';

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

  Future<void> addValidRelations() async {
    for (final friendId in [10, 11, 12]) {
      await addRelation(friendId);
    }
  }

  for (final contactState in [
    (
      name: 'accepted',
      accepted: true,
      deleted: false,
      blocked: false,
      accountDeleted: false,
      expected: 0,
    ),
    (
      name: 'accepted and deleted',
      accepted: true,
      deleted: true,
      blocked: false,
      accountDeleted: false,
      expected: 0,
    ),
    (
      name: 'pending',
      accepted: false,
      deleted: false,
      blocked: false,
      accountDeleted: false,
      expected: 0,
    ),
    (
      name: 'deleted',
      accepted: false,
      deleted: true,
      blocked: false,
      accountDeleted: false,
      expected: 1,
    ),
    (
      name: 'blocked and deleted',
      accepted: false,
      deleted: true,
      blocked: true,
      accountDeleted: false,
      expected: 0,
    ),
    (
      name: 'account deleted',
      accepted: false,
      deleted: true,
      blocked: false,
      accountDeleted: true,
      expected: 0,
    ),
  ]) {
    test(
      '${contactState.name} contact filters suggestions and badge',
      () async {
        await addValidRelations();
        await twonlyDB.contactsDao.insertOnConflictUpdate(
          ContactsCompanion.insert(
            userId: const Value(99),
            username: 'suggested',
            accepted: Value(contactState.accepted),
            deletedByUser: Value(contactState.deleted),
            blocked: Value(contactState.blocked),
            accountDeleted: Value(contactState.accountDeleted),
            requested: const Value(true),
          ),
        );

        expect(
          await twonlyDB.userDiscoveryDao
              .watchNewAnnouncedUsersWithRelations()
              .first,
          hasLength(contactState.expected),
        );
        expect(
          await twonlyDB.userDiscoveryDao
              .watchNewAnnouncementsWithDataCount()
              .first,
          contactState.expected,
        );
        if (contactState.accepted) {
          expect(
            await twonlyDB.contactsDao.watchNotAcceptedContacts().first,
            isEmpty,
          );
          expect(
            await twonlyDB.contactsDao.watchContactsRequestedCount().first,
            0,
          );
        }
      },
    );
  }

  test(
    'accepting a rediscovered contact updates active lists and badges',
    () async {
      await addValidRelations();
      await twonlyDB.contactsDao.insertOnConflictUpdate(
        ContactsCompanion.insert(
          userId: const Value(99),
          username: 'suggested',
          deletedByUser: const Value(true),
        ),
      );

      final suggestions = StreamIterator(
        twonlyDB.userDiscoveryDao.watchNewAnnouncedUsersWithRelations(),
      );
      final announcements = StreamIterator(
        twonlyDB.userDiscoveryDao.watchNewAnnouncementsWithDataCount(),
      );
      final requests = StreamIterator(
        twonlyDB.contactsDao.watchNotAcceptedContacts(),
      );
      final requestCount = StreamIterator(
        twonlyDB.contactsDao.watchContactsRequestedCount(),
      );
      addTearDown(suggestions.cancel);
      addTearDown(announcements.cancel);
      addTearDown(requests.cancel);
      addTearDown(requestCount.cancel);

      await Future.wait([
        suggestions.moveNext(),
        announcements.moveNext(),
        requests.moveNext(),
        requestCount.moveNext(),
      ]);
      expect(suggestions.current, hasLength(1));
      expect(announcements.current, 1);
      expect(requests.current, isEmpty);
      expect(requestCount.current, 0);

      await twonlyDB.contactsDao.updateContact(
        99,
        const ContactsCompanion(
          deletedByUser: Value(false),
          requested: Value(true),
        ),
      );
      await Future.wait([
        suggestions.moveNext(),
        announcements.moveNext(),
        requests.moveNext(),
        requestCount.moveNext(),
      ]);
      expect(suggestions.current, isEmpty);
      expect(announcements.current, 0);
      expect(requests.current.map((contact) => contact.userId), [99]);
      expect(requestCount.current, 1);

      // A stale requested flag must not keep an accepted contact in the badge.
      await twonlyDB.contactsDao.updateContact(
        99,
        const ContactsCompanion(accepted: Value(true)),
      );
      await Future.wait([
        suggestions.moveNext(),
        announcements.moveNext(),
        requests.moveNext(),
        requestCount.moveNext(),
      ]);
      expect(suggestions.current, isEmpty);
      expect(announcements.current, 0);
      expect(requests.current, isEmpty);
      expect(requestCount.current, 0);
    },
  );

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
