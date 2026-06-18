import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/user.service.dart';

void main() {
  if (!Platform.isMacOS) {
    return;
  }

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
      ..registerSingleton<UserService>(UserService())
      ..registerSingleton<ApiService>(ApiService());

    // isUserDiscoveryEnabled defaults to false, so no Rust bridge calls happen
    // in addKeyVerification / deleteKeyVerification.
    userService.currentUser = UserData(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 100,
    );
    userService.isUserCreated = true;
    AppEnvironment.initTesting();
  });

  tearDown(() async {
    await twonlyDB.close();
  });

  // ─── Helpers ────────────────────────────────────────────────────────────────

  Future<void> insertContact(int userId, {String? username}) async {
    await twonlyDB.contactsDao.insertContact(
      ContactsCompanion.insert(
        userId: Value(userId),
        username: username ?? 'user$userId',
      ),
    );
  }

  Future<void> addDirectVerification(
    int contactId,
    VerificationType type,
  ) async {
    await twonlyDB.keyVerificationDao.addKeyVerification(contactId, type);
  }

  Future<void> addSharedVerification(
    int contactId,
    int sharedByContactId,
  ) async {
    await twonlyDB.keyVerificationDao.addKeyVerification(
      contactId,
      VerificationType.contactSharedByVerified,
      verifiedBy: sharedByContactId,
    );
  }

  // ─── Verification Tokens ────────────────────────────────────────────────────

  group('KeyVerificationDao – Verification Tokens', () {
    test(
      'insertVerificationToken stores token; getRecentVerificationTokens returns it',
      () async {
        final token = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
        await twonlyDB.keyVerificationDao.insertVerificationToken(token);

        final tokens = await twonlyDB.keyVerificationDao
            .getRecentVerificationTokens();
        expect(tokens.length, 1);
        expect(tokens.first.token, token);
      },
    );

    test('multiple tokens are all returned when recent', () async {
      final t1 = Uint8List.fromList(List.generate(16, (i) => i));
      final t2 = Uint8List.fromList(List.generate(16, (i) => i + 16));
      await twonlyDB.keyVerificationDao.insertVerificationToken(t1);
      await twonlyDB.keyVerificationDao.insertVerificationToken(t2);

      final tokens = await twonlyDB.keyVerificationDao
          .getRecentVerificationTokens();
      expect(tokens.length, 2);
    });
  });

  // ─── Direct Verification ────────────────────────────────────────────────────

  group('KeyVerificationDao – Direct Verification', () {
    test(
      'addKeyVerification stores an entry; getContactVerification returns it',
      () async {
        await insertContact(10);
        await addDirectVerification(10, VerificationType.secretQrToken);

        final verifications = await twonlyDB.keyVerificationDao
            .getContactVerification(10);
        expect(verifications.length, 1);
        expect(verifications.first.type, VerificationType.secretQrToken);
        expect(verifications.first.contactId, 10);
        expect(verifications.first.verifiedBy, isNull);
      },
    );

    test('isContactVerified returns true for secretQrToken', () async {
      await insertContact(10);
      await addDirectVerification(10, VerificationType.secretQrToken);

      expect(await twonlyDB.keyVerificationDao.isContactVerified(10), true);
    });

    test('isContactVerified returns true for qrScanned', () async {
      await insertContact(10);
      await addDirectVerification(10, VerificationType.qrScanned);

      expect(await twonlyDB.keyVerificationDao.isContactVerified(10), true);
    });

    test('isContactVerified returns true for link', () async {
      await insertContact(10);
      await addDirectVerification(10, VerificationType.link);

      expect(await twonlyDB.keyVerificationDao.isContactVerified(10), true);
    });

    test(
      'isContactVerified returns false when no verification exists',
      () async {
        await insertContact(10);

        expect(await twonlyDB.keyVerificationDao.isContactVerified(10), false);
      },
    );

    test('multiple direct verifications are stored independently', () async {
      await insertContact(10);
      await addDirectVerification(10, VerificationType.secretQrToken);
      await addDirectVerification(10, VerificationType.link);

      final verifications = await twonlyDB.keyVerificationDao
          .getContactVerification(10);
      expect(verifications.length, 2);
    });
  });

  // ─── Shared / Transitive Verification (Blue Badge) ──────────────────────────

  group('KeyVerificationDao – Transitive Trust (Blue Badge)', () {
    // Scenario setup:
    //   alice (userId=2) – may or may not be directly verified
    //   bob   (userId=3) – shared by alice (contactSharedByVerified, verifiedBy=2)
    //
    // Rule: bob's shared verification only "counts" if alice is herself verified.

    test(
      'isContactVerified is false when sharer (alice) is NOT verified',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'bob');

        // Bob shared by Alice, but Alice is not verified
        await addSharedVerification(3, 2);

        expect(await twonlyDB.keyVerificationDao.isContactVerified(3), false);
      },
    );

    test(
      'isContactVerified is true (blue badge) when sharer (alice) IS verified',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'bob');

        // Alice verified directly
        await addDirectVerification(2, VerificationType.secretQrToken);
        // Bob shared by verified Alice
        await addSharedVerification(3, 2);

        expect(await twonlyDB.keyVerificationDao.isContactVerified(3), true);
      },
    );

    test(
      'isContactVerified updates reactively when sharer becomes verified',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'bob');

        await addSharedVerification(3, 2);
        // Bob not yet verified (alice not verified)
        expect(await twonlyDB.keyVerificationDao.isContactVerified(3), false);

        // Alice gets verified
        await addDirectVerification(2, VerificationType.qrScanned);
        // Now Bob is transitively verified
        expect(await twonlyDB.keyVerificationDao.isContactVerified(3), true);
      },
    );

    test(
      'direct verification takes precedence regardless of sharer state',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'bob');

        // Bob has both a direct and a shared (unverified sharer) verification
        await addDirectVerification(3, VerificationType.link);
        await addSharedVerification(3, 2); // alice not verified

        // Direct verification makes bob verified
        expect(await twonlyDB.keyVerificationDao.isContactVerified(3), true);
      },
    );
  });

  // ─── watchContactVerification ───────────────────────────────────────────────

  group('KeyVerificationDao – watchContactVerification', () {
    test(
      'emits the direct verification entry with no verifier contact',
      () async {
        await insertContact(10, username: 'alice');
        await addDirectVerification(10, VerificationType.secretQrToken);

        final entries = await twonlyDB.keyVerificationDao
            .watchContactVerification(10)
            .first;

        expect(entries.length, 1);
        final (kv, verifierContact) = entries.first;
        expect(kv.type, VerificationType.secretQrToken);
        expect(verifierContact, isNull);
      },
    );

    test(
      'filters out shared verification when sharer is NOT verified',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'bob');

        await addSharedVerification(3, 2); // alice not verified

        final entries = await twonlyDB.keyVerificationDao
            .watchContactVerification(3)
            .first;

        expect(entries, isEmpty);
      },
    );

    test(
      'returns shared verification entry with verifier contact when sharer IS verified',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'bob');

        await addDirectVerification(2, VerificationType.secretQrToken);
        await addSharedVerification(3, 2);

        final entries = await twonlyDB.keyVerificationDao
            .watchContactVerification(3)
            .first;

        expect(entries.length, 1);
        final (kv, verifierContact) = entries.first;
        expect(kv.type, VerificationType.contactSharedByVerified);
        expect(verifierContact, isNotNull);
        expect(verifierContact!.username, 'alice');
      },
    );

    test(
      'emits mixed entries: direct (no filter) + shared (filtered by verifier state)',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'charlie');
        await insertContact(4, username: 'bob');

        // Bob has a direct verification
        await addDirectVerification(4, VerificationType.link);
        // Bob is also shared by Alice (unverified) – should NOT appear
        await addSharedVerification(4, 2);
        // Bob is also shared by Charlie (verified) – SHOULD appear
        await addDirectVerification(3, VerificationType.qrScanned);
        await addSharedVerification(4, 3);

        final entries = await twonlyDB.keyVerificationDao
            .watchContactVerification(4)
            .first;

        // Expect: direct + shared-by-charlie (2 entries, shared-by-alice filtered)
        expect(entries.length, 2);
        final types = entries.map((e) => e.$1.type).toSet();
        expect(types, contains(VerificationType.link));
        expect(types, contains(VerificationType.contactSharedByVerified));
      },
    );

    test('emits empty list for contact with no verifications', () async {
      await insertContact(10);

      final entries = await twonlyDB.keyVerificationDao
          .watchContactVerification(10)
          .first;

      expect(entries, isEmpty);
    });
  });

  // ─── getFirstVerificationTypeByContacts ─────────────────────────────────────

  group('KeyVerificationDao – getFirstVerificationTypeByContacts', () {
    test(
      'returns a map with the earliest verification type per contact',
      () async {
        await insertContact(10);
        await insertContact(20);

        await addDirectVerification(10, VerificationType.secretQrToken);
        await addDirectVerification(20, VerificationType.link);

        final map = await twonlyDB.keyVerificationDao
            .getFirstVerificationTypeByContacts();

        expect(map[10], VerificationType.secretQrToken);
        expect(map[20], VerificationType.link);
      },
    );

    test('returns an empty map when no verifications exist', () async {
      final map = await twonlyDB.keyVerificationDao
          .getFirstVerificationTypeByContacts();
      expect(map, isEmpty);
    });

    test(
      'returns only the first verification type when multiple exist',
      () async {
        await insertContact(10);

        // Insert two types for the same contact
        await addDirectVerification(10, VerificationType.secretQrToken);
        await addDirectVerification(10, VerificationType.link);

        final map = await twonlyDB.keyVerificationDao
            .getFirstVerificationTypeByContacts();

        // Only the first-inserted (earliest createdAt) should be in the map
        expect(map.length, 1);
        expect(map.containsKey(10), true);
        // The first inserted was secretQrToken
        expect(map[10], VerificationType.secretQrToken);
      },
    );
  });

  // ─── deleteKeyVerification ───────────────────────────────────────────────────

  group('KeyVerificationDao – deleteKeyVerification', () {
    test('removes all verifications for a contact', () async {
      await insertContact(10);
      await addDirectVerification(10, VerificationType.secretQrToken);
      await addDirectVerification(10, VerificationType.link);

      expect(
        await twonlyDB.keyVerificationDao.getContactVerification(10),
        hasLength(2),
      );

      await twonlyDB.keyVerificationDao.deleteKeyVerification(10);

      expect(
        await twonlyDB.keyVerificationDao.getContactVerification(10),
        isEmpty,
      );
    });

    test(
      'isContactVerified returns false after deleteKeyVerification',
      () async {
        await insertContact(10);
        await addDirectVerification(10, VerificationType.secretQrToken);
        expect(await twonlyDB.keyVerificationDao.isContactVerified(10), true);

        await twonlyDB.keyVerificationDao.deleteKeyVerification(10);
        expect(await twonlyDB.keyVerificationDao.isContactVerified(10), false);
      },
    );

    test('deleting one contact does not affect other contacts', () async {
      await insertContact(10);
      await insertContact(20);
      await addDirectVerification(10, VerificationType.secretQrToken);
      await addDirectVerification(20, VerificationType.qrScanned);

      await twonlyDB.keyVerificationDao.deleteKeyVerification(10);

      expect(await twonlyDB.keyVerificationDao.isContactVerified(10), false);
      expect(await twonlyDB.keyVerificationDao.isContactVerified(20), true);
    });

    test(
      'deleting sharer invalidates transitive trust for shared contacts',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'bob');

        await addDirectVerification(2, VerificationType.secretQrToken);
        await addSharedVerification(3, 2);

        expect(await twonlyDB.keyVerificationDao.isContactVerified(3), true);

        // Remove Alice's verification
        await twonlyDB.keyVerificationDao.deleteKeyVerification(2);

        // Bob's transitive trust should now be invalid
        expect(await twonlyDB.keyVerificationDao.isContactVerified(3), false);
      },
    );
  });

  // ─── deleteKeyVerificationById ───────────────────────────────────────────────

  group('KeyVerificationDao – deleteKeyVerificationById', () {
    test('removes only the specified verification entry', () async {
      await insertContact(10);
      await addDirectVerification(10, VerificationType.secretQrToken);
      await addDirectVerification(10, VerificationType.link);

      var verifications = await twonlyDB.keyVerificationDao
          .getContactVerification(10);
      expect(verifications.length, 2);

      final idToDelete = verifications.first.verificationId;
      await twonlyDB.keyVerificationDao.deleteKeyVerificationById(
        idToDelete,
        10,
      );

      verifications = await twonlyDB.keyVerificationDao.getContactVerification(
        10,
      );
      expect(verifications.length, 1);
      expect(verifications.first.verificationId, isNot(idToDelete));
    });

    test(
      'isContactVerified remains true if another direct verification exists',
      () async {
        await insertContact(10);
        await addDirectVerification(10, VerificationType.secretQrToken);
        await addDirectVerification(10, VerificationType.link);

        final verifications = await twonlyDB.keyVerificationDao
            .getContactVerification(10);
        await twonlyDB.keyVerificationDao.deleteKeyVerificationById(
          verifications.first.verificationId,
          10,
        );

        expect(await twonlyDB.keyVerificationDao.isContactVerified(10), true);
      },
    );

    test(
      'isContactVerified returns false after deleting the last verification',
      () async {
        await insertContact(10);
        await addDirectVerification(10, VerificationType.secretQrToken);

        final verifications = await twonlyDB.keyVerificationDao
            .getContactVerification(10);
        await twonlyDB.keyVerificationDao.deleteKeyVerificationById(
          verifications.first.verificationId,
          10,
        );

        expect(await twonlyDB.keyVerificationDao.isContactVerified(10), false);
      },
    );
  });

  // ─── watchAllGroupMembersVerified ───────────────────────────────────────────

  group('KeyVerificationDao – watchAllGroupMembersVerified', () {
    const groupId = 'test-group-abc';

    Future<void> setupGroup(List<int> memberIds) async {
      await twonlyDB.groupsDao.createNewGroup(
        GroupsCompanion.insert(
          groupId: groupId,
          groupName: 'Trust Test Group',
        ),
      );
      for (final id in memberIds) {
        await twonlyDB.groupsDao.insertOrUpdateGroupMember(
          GroupMembersCompanion.insert(groupId: groupId, contactId: id),
        );
      }
    }

    test('notTrusted when no member is verified', () async {
      await insertContact(10);
      await insertContact(20);
      await setupGroup([10, 20]);

      final status = await twonlyDB.keyVerificationDao
          .watchAllGroupMembersVerified(groupId)
          .first;

      expect(status, VerificationStatus.notTrusted);
    });

    test('trusted when all members are directly verified', () async {
      await insertContact(10);
      await insertContact(20);
      await addDirectVerification(10, VerificationType.secretQrToken);
      await addDirectVerification(20, VerificationType.qrScanned);
      await setupGroup([10, 20]);

      final status = await twonlyDB.keyVerificationDao
          .watchAllGroupMembersVerified(groupId)
          .first;

      expect(status, VerificationStatus.trusted);
    });

    test('notTrusted for empty group', () async {
      await twonlyDB.groupsDao.createNewGroup(
        GroupsCompanion.insert(groupId: groupId, groupName: 'Empty Group'),
      );

      final status = await twonlyDB.keyVerificationDao
          .watchAllGroupMembersVerified(groupId)
          .first;

      expect(status, VerificationStatus.notTrusted);
    });

    test(
      'single member group – trusted when that member is verified',
      () async {
        await insertContact(10);
        await addDirectVerification(10, VerificationType.link);
        await setupGroup([10]);

        final status = await twonlyDB.keyVerificationDao
            .watchAllGroupMembersVerified(groupId)
            .first;

        expect(status, VerificationStatus.trusted);
      },
    );
  });

  // ─── Full Transitive Trust Scenario ─────────────────────────────────────────

  group('KeyVerificationService – Full Transitive Trust Scenario', () {
    // Simulates the complete "blue badge" flow:
    //   1. Alice (2) is directly verified by me via QR code.
    //   2. Alice shares Bob (3) – addKeyVerification(3, contactSharedByVerified, verifiedBy: 2)
    //   3. Bob should receive the blue verification badge (isContactVerified = true)
    //      because Alice (the sharer) is herself verified.
    //
    //   4. Charlie (4) is shared by Dave (5) who is NOT verified.
    //   5. Charlie should NOT receive a badge.
    //
    //   6. Eve (6) is shared by both Dave (5, unverified) and Alice (2, verified).
    //   7. Eve should receive a badge (at least one verified sharer).

    test('bob gets blue badge because alice (sharer) is verified', () async {
      await insertContact(2, username: 'alice');
      await insertContact(3, username: 'bob');

      await addDirectVerification(2, VerificationType.secretQrToken);
      await addSharedVerification(3, 2);

      expect(await twonlyDB.keyVerificationDao.isContactVerified(3), true);
    });

    test(
      'charlie gets no badge because dave (sharer) is NOT verified',
      () async {
        await insertContact(4, username: 'charlie');
        await insertContact(5, username: 'dave');

        await addSharedVerification(4, 5);

        expect(await twonlyDB.keyVerificationDao.isContactVerified(4), false);
      },
    );

    test(
      'eve gets blue badge because alice (one of her sharers) is verified',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(5, username: 'dave');
        await insertContact(6, username: 'eve');

        await addDirectVerification(2, VerificationType.secretQrToken);
        // Dave is NOT verified
        await addSharedVerification(6, 5); // dave shares eve (does not count)
        await addSharedVerification(6, 2); // alice shares eve (counts!)

        expect(await twonlyDB.keyVerificationDao.isContactVerified(6), true);
      },
    );

    test(
      'watchContactVerification shows alice as verifier for bob (blue badge)',
      () async {
        await insertContact(2, username: 'alice');
        await insertContact(3, username: 'bob');

        await addDirectVerification(2, VerificationType.secretQrToken);
        await addSharedVerification(3, 2);

        final entries = await twonlyDB.keyVerificationDao
            .watchContactVerification(3)
            .first;

        expect(entries.length, 1);
        final (kv, verifierContact) = entries.first;
        expect(kv.type, VerificationType.contactSharedByVerified);
        expect(verifierContact?.username, 'alice');
      },
    );

    test(
      'watchContactVerification shows no entries for charlie (sharer unverified)',
      () async {
        await insertContact(4, username: 'charlie');
        await insertContact(5, username: 'dave');

        await addSharedVerification(4, 5);

        final entries = await twonlyDB.keyVerificationDao
            .watchContactVerification(4)
            .first;

        expect(entries, isEmpty);
      },
    );

    test('removing alice revokes bob blue badge transitively', () async {
      await insertContact(2, username: 'alice');
      await insertContact(3, username: 'bob');

      await addDirectVerification(2, VerificationType.secretQrToken);
      await addSharedVerification(3, 2);

      // Confirm bob is verified
      expect(await twonlyDB.keyVerificationDao.isContactVerified(3), true);

      // Revoke alice's verification
      await twonlyDB.keyVerificationDao.deleteKeyVerification(2);

      // Bob should lose the blue badge
      expect(await twonlyDB.keyVerificationDao.isContactVerified(3), false);

      // watchContactVerification should also be empty for bob
      final entries = await twonlyDB.keyVerificationDao
          .watchContactVerification(3)
          .first;
      expect(entries, isEmpty);
    });
  });
}
