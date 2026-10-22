import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/wrapper/app_database.dart';
import 'package:twonly/core/database/app.dart' as raw;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/utils/database/session.dart';

import 'native_api.dart';

export 'native_api.dart';

const testDatabase = TestDatabase._();

/// Native replies need the real event loop; widget animation time is virtual.
Future<T> runNative<T>(WidgetTester tester, Future<T> Function() action) async {
  late T result;
  await tester.runAsync(() async {
    result = await action();
  });
  return result;
}

Future<void> pumpNative(WidgetTester tester, {bool Function()? until}) async {
  final elapsed = Stopwatch()..start();
  do {
    await tester.pump(const Duration(milliseconds: 16));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 16));
    if (until?.call() ?? !tester.binding.hasScheduledFrame) return;
  } while (elapsed.elapsed < const Duration(seconds: 5));
  throw TestFailure('Native widget work did not reach the expected state');
}

/// Fixture seeding only: this owns no connection and implements no application queries.
class TestDatabase {
  const TestDatabase._();
  static Future<TestDatabase> create() async {
    await initializeNativeDatabase();
    final tables = await testDatabase
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' AND name NOT IN ('_sqlx_migrations', 'app_metadata')",
        )
        .get();
    await withDatabaseTransaction(() async {
      await testDatabase.customStatement('PRAGMA defer_foreign_keys = ON');
      for (final table in tables) {
        final name = table.read<String>('name').replaceAll('"', '""');
        await testDatabase.customStatement('DELETE FROM "$name"');
      }
      // Deletes can queue native file cleanup through triggers.
      await testDatabase.customStatement(
        'DELETE FROM pending_media_file_removals',
      );
    });
    return testDatabase;
  }

  Future<int> insert(Object value) async {
    final (table, fields) = _fixture(value);
    final columns = fields.keys.map((key) => '"$key"').join(', ');
    final placeholders = List.filled(fields.length, '?').join(', ');
    final result = await RustAppDatabase.executeInSession(
      statement: 'INSERT INTO "$table" ($columns) VALUES ($placeholders)',
      arguments: fields.values.map(_encode).toList(),
      session: currentDatabaseSession(),
    );
    return result.lastInsertRowId;
  }

  Future<void> customStatement(
    String sql, [
    List<Object?> args = const [],
  ]) async {
    await RustAppDatabase.executeInSession(
      statement: sql,
      arguments: args.map(_encode).toList(),
      session: currentDatabaseSession(),
    );
  }

  Future<int> customUpdate(String sql) async =>
      (await RustAppDatabase.executeInSession(
        statement: sql,
        arguments: const [],
        session: currentDatabaseSession(),
      )).affectedRows;
  TestQuery customSelect(String sql, [List<Object?> args = const []]) =>
      TestQuery(sql, args);
}

class TestQuery {
  const TestQuery(this.sql, this.arguments);
  final String sql;
  final List<Object?> arguments;
  Future<List<TestRow>> get() async {
    final result = await RustAppDatabase.selectInSession(
      statement: sql,
      arguments: arguments.map(_encode).toList(),
      session: currentDatabaseSession(),
    );
    return [
      for (final row in result.rows)
        TestRow(Map.fromIterables(result.columns, row.values.map(_decode))),
    ];
  }

  Future<TestRow> getSingle() async => (await get()).single;
}

class TestRow {
  const TestRow(this.values);
  final Map<String, Object?> values;
  T read<T>(String name) => values[name] as T;
}

raw.SqlValue _encode(Object? value) => switch (value) {
  null => const raw.SqlValue(kind: 0),
  bool() => raw.SqlValue(kind: 1, integerValue: value ? 1 : 0),
  int() => raw.SqlValue(kind: 1, integerValue: value),
  double() => raw.SqlValue(kind: 2, realValue: value),
  String() => raw.SqlValue(kind: 3, textValue: value),
  Uint8List() => raw.SqlValue(kind: 4, blobValue: value),
  DateTime() => raw.SqlValue(
    kind: 1,
    integerValue: value.millisecondsSinceEpoch ~/ 1000,
  ),
  Enum() => raw.SqlValue(kind: 3, textValue: value.name),
  _ => throw ArgumentError.value(value),
};
Object? _decode(raw.SqlValue value) => switch (value.kind) {
  0 => null,
  1 => value.integerValue,
  2 => value.realValue,
  3 => value.textValue,
  4 => value.blobValue,
  _ => throw StateError('Unknown SQLite value'),
};

(String, Map<String, Object?>) _fixture(Object value) => switch (value) {
  ContactPatch() => (
    'contacts',
    {
      if (value.userId != null) 'user_id': value.userId,
      if (value.username != null) 'username': value.username,
      if (value.displayName != null) 'display_name': value.displayName!.value,
      if (value.nickName != null) 'nick_name': value.nickName!.value,
      if (value.avatarSvgCompressed != null)
        'avatar_svg_compressed': value.avatarSvgCompressed!.value,
      if (value.preferPhotoAvatar != null)
        'prefer_photo_avatar': value.preferPhotoAvatar!.value,
      if (value.senderProfileCounter != null)
        'sender_profile_counter': value.senderProfileCounter,
      if (value.accepted != null) 'accepted': value.accepted,
      if (value.deletedByUser != null) 'deleted_by_user': value.deletedByUser,
      if (value.requested != null) 'requested': value.requested,
      if (value.blocked != null) 'blocked': value.blocked,
      if (value.verified != null) 'verified': value.verified,
      if (value.accountDeleted != null) 'account_deleted': value.accountDeleted,
      if (value.createdAt != null) 'created_at': value.createdAt,
      if (value.signalVersion != null) 'signal_version': value.signalVersion,
      if (value.userDiscoveryVersion != null)
        'user_discovery_version': value.userDiscoveryVersion!.value,
      if (value.userDiscoveryExcluded != null)
        'user_discovery_excluded': value.userDiscoveryExcluded,
      if (value.userDiscoveryManualApproved != null)
        'user_discovery_manual_approved':
            value.userDiscoveryManualApproved!.value,
      if (value.recoveryIsTrustedFriend != null)
        'recovery_is_trusted_friend': value.recoveryIsTrustedFriend,
      if (value.recoveryLastHeartbeat != null)
        'recovery_last_heartbeat': value.recoveryLastHeartbeat!.value,
      if (value.recoverySecretShare != null)
        'recovery_secret_share': value.recoverySecretShare!.value,
      if (value.recoveryContactsSecretShare != null)
        'recovery_contacts_secret_share':
            value.recoveryContactsSecretShare!.value,
      if (value.recoveryContactsLastHeartbeat != null)
        'recovery_contacts_last_heartbeat':
            value.recoveryContactsLastHeartbeat!.value,
      if (value.recoveryContactsThreshold != null)
        'recovery_contacts_threshold': value.recoveryContactsThreshold!.value,
      if (value.askForFriendPromotions != null)
        'ask_for_friend_promotions': value.askForFriendPromotions!.value,
      if (value.widgetSharingAllowed != null)
        'widget_sharing_allowed': value.widgetSharingAllowed,
      if (value.widgetSharingGranted != null)
        'widget_sharing_granted': value.widgetSharingGranted,
      if (value.twonlyScore != null) 'twonly_score': value.twonlyScore!.value,
      if (value.joinedAt != null) 'joined_at': value.joinedAt!.value,
      if (value.mediaSendCounter != null)
        'media_send_counter': value.mediaSendCounter,
      if (value.mediaReceivedCounter != null)
        'media_received_counter': value.mediaReceivedCounter,
    },
  ),
  GroupPatch() => (
    'groups',
    {
      if (value.groupId != null) 'group_id': value.groupId,
      if (value.isGroupAdmin != null) 'is_group_admin': value.isGroupAdmin,
      if (value.isDirectChat != null) 'is_direct_chat': value.isDirectChat,
      if (value.pinned != null) 'pinned': value.pinned,
      if (value.archived != null) 'archived': value.archived,
      if (value.joinedGroup != null) 'joined_group': value.joinedGroup,
      if (value.leftGroup != null) 'left_group': value.leftGroup,
      if (value.deletedContent != null) 'deleted_content': value.deletedContent,
      if (value.stateVersionId != null)
        'state_version_id': value.stateVersionId,
      if (value.stateEncryptionKey != null)
        'state_encryption_key': value.stateEncryptionKey!.value,
      if (value.myGroupPrivateKey != null)
        'my_group_private_key': value.myGroupPrivateKey!.value,
      if (value.groupName != null) 'group_name': value.groupName,
      if (value.draftMessage != null)
        'draft_message': value.draftMessage!.value,
      if (value.totalMediaCounter != null)
        'total_media_counter': value.totalMediaCounter,
      if (value.alsoBestFriend != null)
        'also_best_friend': value.alsoBestFriend,
      if (value.deleteMessagesAfterMilliseconds != null)
        'delete_messages_after_milliseconds':
            value.deleteMessagesAfterMilliseconds,
      if (value.createdAt != null) 'created_at': value.createdAt,
      if (value.lastMessageSend != null)
        'last_message_send': value.lastMessageSend!.value,
      if (value.lastMessageReceived != null)
        'last_message_received': value.lastMessageReceived!.value,
      if (value.lastFlameCounterChange != null)
        'last_flame_counter_change': value.lastFlameCounterChange!.value,
      if (value.lastFlameSync != null)
        'last_flame_sync': value.lastFlameSync!.value,
      if (value.flameCounter != null) 'flame_counter': value.flameCounter,
      if (value.maxFlameCounter != null)
        'max_flame_counter': value.maxFlameCounter,
      if (value.maxFlameCounterFrom != null)
        'max_flame_counter_from': value.maxFlameCounterFrom!.value,
      if (value.lastMessageExchange != null)
        'last_message_exchange': value.lastMessageExchange,
    },
  ),
  GroupMemberPatch() => (
    'group_members',
    {
      if (value.groupId != null) 'group_id': value.groupId,
      if (value.contactId != null) 'contact_id': value.contactId,
      if (value.memberState != null) 'member_state': value.memberState!.value,
      if (value.groupPublicKey != null)
        'group_public_key': value.groupPublicKey!.value,
      if (value.lastChatOpened != null)
        'last_chat_opened': value.lastChatOpened!.value,
      if (value.lastTypeIndicator != null)
        'last_type_indicator': value.lastTypeIndicator!.value,
      if (value.lastMessage != null) 'last_message': value.lastMessage!.value,
      if (value.createdAt != null) 'created_at': value.createdAt,
    },
  ),
  MediaFilePatch() => (
    'media_files',
    {
      if (value.mediaId != null) 'media_id': value.mediaId,
      if (value.type != null) 'type': value.type,
      if (value.uploadState != null) 'upload_state': value.uploadState!.value,
      if (value.cloudState != null) 'cloud_state': value.cloudState,
      if (value.blurhash != null) 'blurhash': value.blurhash!.value,
      if (value.downloadState != null)
        'download_state': value.downloadState!.value,
      if (value.requiresAuthentication != null)
        'requires_authentication': value.requiresAuthentication,
      if (value.stored != null) 'stored': value.stored,
      if (value.isDraftMedia != null) 'is_draft_media': value.isDraftMedia,
      if (value.isWidgetMedia != null) 'is_widget_media': value.isWidgetMedia,
      if (value.isFavorite != null) 'is_favorite': value.isFavorite,
      if (value.hasCropAnalyzed != null)
        'has_crop_analyzed': value.hasCropAnalyzed,
      if (value.preProgressingProcess != null)
        'pre_progressing_process': value.preProgressingProcess!.value,
      if (value.reuploadRequestedBy != null)
        'reupload_requested_by': value.reuploadRequestedBy!.value,
      if (value.displayLimitInMilliseconds != null)
        'display_limit_in_milliseconds':
            value.displayLimitInMilliseconds!.value,
      if (value.removeAudio != null) 'remove_audio': value.removeAudio!.value,
      if (value.trimStartMs != null) 'trim_start_ms': value.trimStartMs!.value,
      if (value.trimEndMs != null) 'trim_end_ms': value.trimEndMs!.value,
      if (value.downloadToken != null)
        'download_token': value.downloadToken!.value,
      if (value.encryptionKey != null)
        'encryption_key': value.encryptionKey!.value,
      if (value.encryptionMac != null)
        'encryption_mac': value.encryptionMac!.value,
      if (value.encryptionNonce != null)
        'encryption_nonce': value.encryptionNonce!.value,
      if (value.storedFileHash != null)
        'stored_file_hash': value.storedFileHash!.value,
      if (value.hasThumbnail != null) 'has_thumbnail': value.hasThumbnail,
      if (value.sizeInBytes != null) 'size_in_bytes': value.sizeInBytes!.value,
      if (value.locationLatitude != null)
        'location_latitude': value.locationLatitude!.value,
      if (value.locationLongitude != null)
        'location_longitude': value.locationLongitude!.value,
      if (value.locationAccuracy != null)
        'location_accuracy': value.locationAccuracy!.value,
      if (value.locationStatus != null)
        'location_status': value.locationStatus!.value,
      if (value.locationDeadlineAt != null)
        'location_deadline_at': value.locationDeadlineAt!.value,
      if (value.galleryExportPending != null)
        'gallery_export_pending': value.galleryExportPending,
      if (value.createdAt != null) 'created_at': value.createdAt,
      if (value.createdAtMonth != null)
        'created_at_month': value.createdAtMonth!.value,
    },
  ),
  MessagePatch() => (
    'messages',
    {
      if (value.groupId != null) 'group_id': value.groupId,
      if (value.messageId != null) 'message_id': value.messageId,
      if (value.senderId != null) 'sender_id': value.senderId!.value,
      if (value.type != null) 'type': value.type,
      if (value.content != null) 'content': value.content!.value,
      if (value.mediaId != null) 'media_id': value.mediaId!.value,
      if (value.additionalMessageData != null)
        'additional_message_data': value.additionalMessageData!.value,
      if (value.mediaStored != null) 'media_stored': value.mediaStored,
      if (value.mediaReopened != null) 'media_reopened': value.mediaReopened,
      if (value.downloadToken != null)
        'download_token': value.downloadToken!.value,
      if (value.quotesMessageId != null)
        'quotes_message_id': value.quotesMessageId!.value,
      if (value.isDeletedFromSender != null)
        'is_deleted_from_sender': value.isDeletedFromSender,
      if (value.isWidgetMedia != null) 'is_widget_media': value.isWidgetMedia,
      if (value.isStory != null) 'is_story': value.isStory,
      if (value.openedAt != null) 'opened_at': value.openedAt!.value,
      if (value.openedByAll != null) 'opened_by_all': value.openedByAll!.value,
      if (value.createdAt != null) 'created_at': value.createdAt,
      if (value.modifiedAt != null) 'modified_at': value.modifiedAt!.value,
      if (value.ackByUser != null) 'ack_by_user': value.ackByUser!.value,
      if (value.ackByServer != null) 'ack_by_server': value.ackByServer!.value,
    },
  ),
  StoredMessage() => (
    'messages',
    {
      'group_id': value.groupId,
      'message_id': value.messageId,
      'sender_id': value.senderId,
      'type': value.type,
      'content': value.content,
      'media_id': value.mediaId,
      'additional_message_data': value.additionalMessageData,
      'media_stored': value.mediaStored,
      'media_reopened': value.mediaReopened,
      'download_token': value.downloadToken,
      'quotes_message_id': value.quotesMessageId,
      'is_deleted_from_sender': value.isDeletedFromSender,
      'is_widget_media': value.isWidgetMedia,
      'is_story': value.isStory,
      'opened_at': value.openedAtSeconds,
      'opened_by_all': value.openedByAllSeconds,
      'created_at': value.createdAtSeconds,
      'modified_at': value.modifiedAtSeconds,
      'ack_by_user': value.ackByUserSeconds,
      'ack_by_server': value.ackByServerSeconds,
    },
  ),
  _ => throw ArgumentError.value(value, 'value', 'Unsupported native fixture'),
};
