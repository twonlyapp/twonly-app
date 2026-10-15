import 'package:clock/clock.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
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
    'purgeMessageTable preserves unopened messages and deletes expired ones',
    () async {
      final now = clock.now();
      const retentionMs = 7200000; // 2 hours
      final deletionLimit = now.subtract(
        const Duration(milliseconds: retentionMs),
      );

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
          createdAt: Value(
            deletionLimit.subtract(const Duration(minutes: 5)),
          ), // older than deletion threshold
        ),
      );

      // Msg B: Opened long ago (openedByAll is older than deletion threshold)
      await twonlyDB.messagesDao.insertMessage(
        MessagesCompanion.insert(
          messageId: 'msg_b_opened_expired',
          groupId: 'test_group',
          type: 'text',
          openedByAll: Value(
            deletionLimit.subtract(const Duration(minutes: 5)),
          ),
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
    },
  );

  test(
    'widget messages expire from chats while received images remain available',
    () async {
      final now = clock.now();
      final expired = now.subtract(const Duration(hours: 3));
      final recent = now.subtract(const Duration(hours: 1));
      await twonlyDB.contactsDao.insertOnConflictUpdate(
        ContactsCompanion.insert(userId: const Value(2), username: 'sender'),
      );
      await twonlyDB.groupsDao.createNewGroup(
        GroupsCompanion.insert(
          groupId: 'widgets',
          groupName: 'Widgets',
          deleteMessagesAfterMilliseconds: const Value(7200000),
        ),
      );
      for (final fixture in [
        (id: 'received-widget-expired', sender: 2, widget: true, at: expired),
        (id: 'sent-widget-expired', sender: null, widget: true, at: expired),
        (id: 'received-media-expired', sender: 2, widget: false, at: expired),
        (id: 'sent-widget-recent', sender: null, widget: true, at: recent),
        (id: 'received-widget-recent', sender: 2, widget: true, at: recent),
      ]) {
        await twonlyDB.mediaFilesDao.insertOrUpdateMedia(
          MediaFilesCompanion.insert(
            mediaId: fixture.id,
            type: MediaType.image,
            isWidgetMedia: Value(fixture.widget),
            downloadState: const Value(DownloadState.ready),
          ),
        );
        await twonlyDB.messagesDao.insertMessage(
          MessagesCompanion.insert(
            messageId: fixture.id,
            groupId: 'widgets',
            senderId: Value(fixture.sender),
            type: 'media',
            mediaId: Value(fixture.id),
            isWidgetMedia: Value(fixture.widget),
            openedAt: Value(fixture.at),
            openedByAll: Value(fixture.at),
            createdAt: Value(fixture.at),
          ),
        );
      }

      final visible = await (await twonlyDB.messagesDao.watchByGroupId(
        'widgets',
      )).first;
      expect(
        visible.map((message) => message.messageId),
        unorderedEquals(['sent-widget-recent', 'received-widget-recent']),
      );
      final older = await twonlyDB.messagesDao.getMessagesBefore(
        'widgets',
        recent,
        beforeMessageId: 'sent-widget-recent',
      );
      expect(
        older.map((message) => message.messageId),
        isNot(contains('received-widget-expired')),
      );
      expect(
        (await (await twonlyDB.messagesDao.watchLastMessage(
          'widgets',
        )).first)!.messageId,
        'sent-widget-recent',
      );
      expect(
        (await twonlyDB.messagesDao.watchLatestMessagesByGroup().first)
            .single
            .openedAt,
        recent.copyWith(millisecond: 0, microsecond: 0),
      );

      await twonlyDB.messagesDao.purgeMessageTable();

      final remaining = await twonlyDB.select(twonlyDB.messages).get();
      expect(
        remaining.map((message) => message.messageId),
        unorderedEquals([
          'received-widget-expired',
          'sent-widget-recent',
          'received-widget-recent',
        ]),
      );
      final widgetImage = await twonlyDB.mediaFilesDao.getMediaFileById(
        'received-widget-expired',
      );
      expect(widgetImage!.downloadState, DownloadState.ready);
      expect(widgetImage.isWidgetMedia, isTrue);
    },
  );

  test('deleting a chat retains only one-time app state', () async {
    await twonlyDB.groupsDao.createNewGroup(
      GroupsCompanion.insert(groupId: 'chat', groupName: 'Trip'),
    );
    for (final statement in [
      "INSERT INTO messages(message_id, group_id, type) VALUES ('text', 'chat', 'text')",
      "INSERT INTO messages(message_id, group_id, type) VALUES ('expenses-card', 'chat', 'webxdcApp')",
      "INSERT INTO messages(message_id, group_id, type) VALUES ('game-card', 'chat', 'webxdcApp')",
      "INSERT INTO webxdc_apps(app_id, version, name, bundle_sha256, bundle_bytes, cached_at, one_time) VALUES ('expenses', 1, 'Expenses', 'expense-hash', 1, 0, 1)",
      "INSERT INTO webxdc_apps(app_id, version, name, bundle_sha256, bundle_bytes, cached_at, one_time) VALUES ('game', 1, 'Game', 'game-hash', 1, 0, 0)",
      "INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token, created_at, last_update_at) VALUES ('expenses-card', 'chat', 'expenses', 1, 'expenses-origin', 0, 0)",
      "INSERT INTO webxdc_instances(instance_id, group_id, app_id, version, origin_token, created_at, last_update_at) VALUES ('game-card', 'chat', 'game', 1, 'game-origin', 0, 0)",
      "INSERT INTO webxdc_updates(instance_id, serial, message_id, payload, received_at) VALUES ('expenses-card', 1, 'expense-update', '{}', 0)",
    ]) {
      await twonlyDB.customStatement(statement);
    }

    await twonlyDB.messagesDao.deleteMessagesByGroupId('chat');

    final messages = await twonlyDB.select(twonlyDB.messages).get();
    expect(messages.map((message) => message.messageId), ['expenses-card']);
    final instances = await twonlyDB.select(twonlyDB.webxdcInstances).get();
    expect(instances.map((instance) => instance.instanceId), ['expenses-card']);
    final updates = await twonlyDB.select(twonlyDB.webxdcUpdates).get();
    expect(updates, hasLength(1));
    expect((await twonlyDB.groupsDao.getGroup('chat'))?.deletedContent, isTrue);
  });
}
