import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/services/user.service.dart';

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

    userService.currentUser = UserData(
      userId: 1,
      username: 'test_user',
      displayName: 'Test User',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 100,
    );
    userService.isUserCreated = true;
  });

  tearDown(() async {
    await twonlyDB.close();
  });

  test('purgeMessageTable preserves unopened messages and deletes expired ones', () async {
    final now = clock.now();
    const retentionMs = 7200000; // 2 hours
    final deletionLimit = now.subtract(const Duration(milliseconds: retentionMs));

    // 1. Insert a group with 2 hour retention policy
    await twonlyDB.groupsDao.createNewGroup(
      GroupsCompanion.insert(
        groupId: 'test_group',
        groupName: 'Test Group',
        deleteMessagesAfterMilliseconds: const Value(retentionMs),
      ),
    );

    // 2. Insert test messages:
    // Msg A: Unopened (openedByAll is null)
    await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion.insert(
        messageId: 'msg_a_unopened',
        groupId: 'test_group',
        type: 'text',
        createdAt: Value(deletionLimit.subtract(const Duration(minutes: 5))), // older than deletion threshold
      ),
    );

    // Msg B: Opened long ago (openedByAll is older than deletion threshold)
    await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion.insert(
        messageId: 'msg_b_opened_expired',
        groupId: 'test_group',
        type: 'text',
        openedByAll: Value(deletionLimit.subtract(const Duration(minutes: 5))),
        createdAt: Value(deletionLimit.subtract(const Duration(minutes: 30))),
      ),
    );

    // Msg C: Opened recently (openedByAll is newer than deletion threshold)
    await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion.insert(
        messageId: 'msg_c_opened_recent',
        groupId: 'test_group',
        type: 'text',
        openedByAll: Value(deletionLimit.add(const Duration(minutes: 5))),
        createdAt: Value(deletionLimit.subtract(const Duration(minutes: 10))),
      ),
    );

    // Msg D: Deleted from sender, older than threshold
    await twonlyDB.messagesDao.insertMessage(
      MessagesCompanion.insert(
        messageId: 'msg_d_sender_deleted_expired',
        groupId: 'test_group',
        type: 'text',
        isDeletedFromSender: const Value(true),
        createdAt: Value(deletionLimit.subtract(const Duration(minutes: 5))),
      ),
    );

    // Run purge
    await twonlyDB.messagesDao.purgeMessageTable();

    // Verify database state
    final allMessages = await twonlyDB.select(twonlyDB.messages).get();
    final remainingIds = allMessages.map((m) => m.messageId).toList();

    // msg_a_unopened should be preserved because it was never opened (openedByAll was null)
    expect(remainingIds.contains('msg_a_unopened'), isTrue);

    // msg_b_opened_expired should be deleted because openedByAll < deletionLimit
    expect(remainingIds.contains('msg_b_opened_expired'), isFalse);

    // msg_c_opened_recent should be preserved because openedByAll >= deletionLimit
    expect(remainingIds.contains('msg_c_opened_recent'), isTrue);

    // msg_d_sender_deleted_expired should be deleted because isDeletedFromSender is true and createdAt < deletionLimit
    expect(remainingIds.contains('msg_d_sender_deleted_expired'), isFalse);
  });
}
