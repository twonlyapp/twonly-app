import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
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

  test(
    'watchByGroupId stream emits updates when a new text message is inserted',
    () async {
      // 1. Create a group
      await twonlyDB.groupsDao.createNewGroup(
        GroupsCompanion.insert(
          groupId: 'test_group_stream',
          groupName: 'Test Group Stream',
        ),
      );

      // 2. Start watching
      final stream = await twonlyDB.messagesDao.watchByGroupId(
        'test_group_stream',
      );

      final emissions = <List<Message>>[];
      final subscription = stream.listen(emissions.add);

      // Wait briefly for initial empty emission
      await Future.delayed(const Duration(milliseconds: 100));

      expect(emissions, hasLength(1));
      expect(emissions.first, isEmpty);

      // 3. Insert a message
      await twonlyDB.messagesDao.insertMessage(
        MessagesCompanion.insert(
          messageId: 'msg_1',
          groupId: 'test_group_stream',
          type: 'text',
          content: const Value('Hello world'),
        ),
      );

      // Wait for the stream to propagate the event
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify it emitted the new list containing our message
      expect(emissions, hasLength(2));
      expect(emissions[1], hasLength(1));
      expect(emissions[1].first.messageId, equals('msg_1'));

      await subscription.cancel();
    },
  );

  test(
    'simulate sending flow with group updates and verify messages stream emits',
    () async {
      await twonlyDB.groupsDao.createNewGroup(
        GroupsCompanion.insert(
          groupId: 'test_group_2',
          groupName: 'Test Group 2',
        ),
      );

      final msgStream = await twonlyDB.messagesDao.watchByGroupId(
        'test_group_2',
      );
      final messagesEmissions = <List<Message>>[];
      final msgSub = msgStream.listen(messagesEmissions.add);

      final groupStream = twonlyDB.groupsDao.watchGroup('test_group_2');
      final groupEmissions = <Group?>[];
      final groupSub = groupStream.listen(groupEmissions.add);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(messagesEmissions, hasLength(1));
      expect(groupEmissions, hasLength(1));

      // Simulate sending:
      // 1. Update group draftMessage to null (as done in insertAndSendTextMessage)
      await twonlyDB.groupsDao.updateGroup(
        'test_group_2',
        const GroupsCompanion(
          draftMessage: Value(null),
        ),
      );

      // 2. Insert message
      final message = await twonlyDB.messagesDao.insertMessage(
        MessagesCompanion(
          groupId: const Value('test_group_2'),
          content: const Value('Hello from simulation'),
          type: Value(MessageType.text.name),
        ),
      );

      expect(message, isNotNull);

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify group stream received updates
      expect(groupEmissions.length, greaterThan(1));

      // Verify message stream received updates containing the new message
      expect(messagesEmissions.length, greaterThan(1));
      expect(
        messagesEmissions.last.any((m) => m.messageId == message!.messageId),
        isTrue,
      );

      await msgSub.cancel();
      await groupSub.cancel();
    },
  );
}
