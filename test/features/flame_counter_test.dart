import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/user.service.dart';

Future<void> expectFlame(DateTime time, String groupId, int counter) async {
  await withClock(
    Clock.fixed(time),
    () async {
      final group = (await twonlyDB.groupsDao.getGroup(groupId))!;
      expect(
        getFlameCounterFromGroup(group).counter,
        counter,
        reason: StackTrace.current.toString(),
      );
    },
  );
}

Future<void> expectFlameExpiring(
  DateTime time,
  String groupId, {
  required int counter,
  required bool isExpiring,
}) async {
  await withClock(
    Clock.fixed(time),
    () async {
      final group = (await twonlyDB.groupsDao.getGroup(groupId))!;
      final result = getFlameCounterFromGroup(group);
      expect(
        result.counter,
        counter,
        reason: 'counter mismatch — ${StackTrace.current}',
      );
      expect(
        result.isExpiring,
        isExpiring,
        reason: 'isExpiring mismatch — ${StackTrace.current}',
      );
    },
  );
}

void main() {
  final mutex = Mutex();
  var usedUserIds = 0;

  Future<int> getAndCreateUserId() async {
    return mutex.protect<int>(() async {
      final userId = usedUserIds += 1;
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion(userId: Value(userId), username: Value('$userId')),
      );
      return userId;
    });
  }

  setUp(() async {
    await locator.reset();
    locator
      ..registerSingleton<TwonlyDB>(
        TwonlyDB.forTesting(
          DatabaseConnection(
            NativeDatabase.memory(),
            // Recommended for widget tests to avoid test errors.
            closeStreamsSynchronously: true,
          ),
        ),
      )
      ..registerSingleton<UserService>(UserService());

    userService.currentUser = UserData(
      userId: 0x133337,
      username: 'test_user',
      displayName: 'Test User',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
    )..appVersion = 62;
  });

  test('test flame counter', () async {
    final contactId = await getAndCreateUserId();
    final contact = (await twonlyDB.contactsDao.getContactById(contactId))!;
    await twonlyDB.groupsDao.createNewDirectChat(
      contactId,
      GroupsCompanion(
        groupName: Value(
          getContactDisplayName(contact),
        ),
      ),
    );

    final group = (await twonlyDB.groupsDao.getDirectChat(contactId))!;

    await expectFlame(DateTime(2026, 2, 3, 16), group.groupId, 0);

    await withClock(
      Clock.fixed(DateTime(2026, 2, 2, 16)),
      () async {
        await incFlameCounter(group.groupId, true, DateTime(2026, 2, 2, 10));
        await incFlameCounter(group.groupId, false, DateTime(2026, 2, 2, 15));
      },
    );

    await expectFlame(DateTime(2026, 2, 2, 18), group.groupId, 1);
    await expectFlame(DateTime(2026, 2, 3, 16), group.groupId, 1);
    await expectFlame(DateTime(2026, 2, 4, 16), group.groupId, 1);
    await expectFlame(DateTime(2026, 2, 5, 16), group.groupId, 0);

    await withClock(
      Clock.fixed(DateTime(2026, 2, 5, 16)),
      () async {
        await incFlameCounter(group.groupId, true, DateTime(2026, 2, 5, 17));
        await incFlameCounter(group.groupId, false, DateTime(2026, 2, 5, 18));
      },
    );

    await expectFlame(DateTime(2026, 2, 5, 19), group.groupId, 1);

    await withClock(
      Clock.fixed(DateTime(2026, 2, 6, 1)),
      () async {
        await incFlameCounter(group.groupId, true, DateTime(2026, 2, 6, 1));
        await incFlameCounter(group.groupId, false, DateTime(2026, 2, 6, 2));
      },
    );

    await expectFlame(DateTime(2026, 2, 6, 19), group.groupId, 2);
    await expectFlame(DateTime(2026, 3, 1, 19), group.groupId, 0);

    // ── isExpiring tests ──────────────────────────────────────────────────────
    // After the Feb-5/Feb-6 exchanges the flame is 2.
    // On Feb-7 no exchange has happened yet → isExpiring should be true.
    await expectFlameExpiring(
      DateTime(2026, 2, 7, 10),
      group.groupId,
      counter: 2,
      isExpiring: false,
    );
    // Once both sides exchange on Feb-7, isExpiring becomes false.
    await withClock(
      Clock.fixed(DateTime(2026, 2, 7, 12)),
      () async {
        await incFlameCounter(group.groupId, true, DateTime(2026, 2, 7, 10));
        await incFlameCounter(group.groupId, false, DateTime(2026, 2, 7, 11));
      },
    );
    await expectFlameExpiring(
      DateTime(2026, 2, 7, 13),
      group.groupId,
      counter: 3,
      isExpiring: false,
    );
    // On Feb-8, before any exchange, isExpiring is true again.
    await expectFlameExpiring(
      DateTime(2026, 2, 8, 9),
      group.groupId,
      counter: 3,
      isExpiring: false,
    );
    // On Feb-9, last exchange was Feb-7 — still within the two-day window,
    // so the flame is still alive but expiring.
    await expectFlameExpiring(
      DateTime(2026, 2, 9, 9),
      group.groupId,
      counter: 3,
      isExpiring: true,
    );
    // On Feb-10, last exchange (Feb-7) is now before twoDaysAgo → flame is gone.
    await expectFlameExpiring(
      DateTime(2026, 2, 10, 9),
      group.groupId,
      counter: 0,
      isExpiring: false,
    );

    for (var i = 1; i <= 20; i++) {
      await withClock(
        Clock.fixed(DateTime(2026, 3, i, 1)),
        () async {
          await incFlameCounter(group.groupId, true, DateTime(2026, 3, i, 2));
          await incFlameCounter(group.groupId, false, DateTime(2026, 3, i, 3));
        },
      );
    }

    await expectFlame(DateTime(2026, 3, 20, 19), group.groupId, 20);
    await expectFlame(DateTime(2026, 3, 23, 19), group.groupId, 0);

    await withClock(
      Clock.fixed(DateTime(2026, 3, 24, 19)),
      () async {
        final group2 = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
        expect(isItPossibleToRestoreFlames(group2), true);
      },
    );
    await withClock(
      Clock.fixed(DateTime(2026, 3, 25, 19)),
      () async {
        final group2 = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
        expect(isItPossibleToRestoreFlames(group2), true);
      },
    );
    await withClock(
      Clock.fixed(DateTime(2026, 3, 26, 19)),
      () async {
        final group2 = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
        expect(isItPossibleToRestoreFlames(group2), true);
      },
    );
    await withClock(
      Clock.fixed(DateTime(2026, 3, 27, 19)),
      () async {
        final group2 = (await twonlyDB.groupsDao.getGroup(group.groupId))!;
        expect(isItPossibleToRestoreFlames(group2), false);
      },
    );
  });

  tearDown(() async {
    await twonlyDB.close();
  });
}
