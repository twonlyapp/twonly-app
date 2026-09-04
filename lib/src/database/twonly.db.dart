import 'dart:async';

import 'package:drift/drift.dart';
import 'package:twonly/src/database/daos/contact_groups.dao.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/groups.dao.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/daos/mediafiles.dao.dart';
import 'package:twonly/src/database/daos/messages.dao.dart';
import 'package:twonly/src/database/daos/reactions.dao.dart';
import 'package:twonly/src/database/daos/receipts.dao.dart';
import 'package:twonly/src/database/daos/user_discovery.dao.dart';
import 'package:twonly/src/database/rust_change_notifier.dart';
import 'package:twonly/src/database/rust_query_executor.dart';
import 'package:twonly/src/database/tables/contact_groups.table.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/tables/reactions.table.dart';
import 'package:twonly/src/database/tables/receipts.table.dart';
import 'package:twonly/src/database/tables/user_discovery.table.dart';
import 'package:twonly/src/database/tables/webxdc.table.dart';
import 'package:twonly/src/database/twonly.db.steps.dart';
import 'package:twonly/src/utils/log.dart';

part 'twonly.db.g.dart';

// You can then create a database class that includes this table
@DriftDatabase(
  tables: [
    Contacts,
    Messages,
    MessageHistories,
    MediaFiles,
    Reactions,
    Groups,
    GroupMembers,
    Receipts,
    ReceivedReceipts,
    MessageActions,
    GroupHistories,
    KeyVerifications,
    VerificationTokens,
    UserDiscoveryAnnouncedUsers,
    UserDiscoveryUserRelations,
    UserDiscoveryOtherPromotions,
    UserDiscoveryOwnPromotions,
    UserDiscoveryShares,
    ContactGroups,
    ContactGroupMembers,
    WebxdcApps,
    WebxdcInstances,
    WebxdcUpdates,
  ],
  daos: [
    MessagesDao,
    ContactsDao,
    ReceiptsDao,
    GroupsDao,
    ReactionsDao,
    MediaFilesDao,
    UserDiscoveryDao,
    KeyVerificationDao,
    ContactGroupsDao,
  ],
)
class TwonlyDB extends _$TwonlyDB {
  TwonlyDB([QueryExecutor? e]) : super(e ?? openRustAppDatabase()) {
    // Only the Rust-backed connection needs external change notifications.
    // An explicit executor is a plain Drift-owned database (tests, and the
    // legacy import in main.dart), where Drift already sees every write.
    if (e == null) {
      _rustChanges = listenToRustDatabaseChanges(this);
    }
  }

  // ignore: matching_super_parameters
  TwonlyDB.forTesting(DatabaseConnection super.connection);

  StreamSubscription<List<String>>? _rustChanges;

  @override
  Future<void> close() async {
    await _rustChanges?.cancel();
    _rustChanges = null;
    return super.close();
  }

  @override
  int get schemaVersion => 25;

  @override
  MigrationStrategy get migration {
    // Frozen legacy-Drift upgrade chain used only before Rust imports schema
    // v25. All current application schema migrations are owned by Rust.
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (m, from, to) async {
        // disable foreign_keys before migrations
        await customStatement('PRAGMA foreign_keys = OFF');
        return stepByStep(
          from1To2: (m, schema) async {
            await m.addColumn(schema.messages, schema.messages.mediaReopened);
            await m.dropColumn(schema.mediaFiles, 'reopen_by_contact');
          },
          from2To3: (m, schema) async {
            await m.addColumn(schema.groups, schema.groups.draftMessage);
          },
          from3To4: (m, schema) async {
            await m.alterTable(
              TableMigration(
                schema.groupHistories,
                columnTransformer: {
                  schema.groupHistories.affectedContactId:
                      schema.groupHistories.affectedContactId,
                },
              ),
            );
          },
          from4To5: (m, schema) async {
            await m.addColumn(schema.receipts, schema.receipts.markForRetry);
            await m.addColumn(
              schema.mediaFiles,
              schema.mediaFiles.storedFileHash,
            );
          },
          from5To6: (m, schema) async {
            await m.addColumn(
              schema.receipts,
              schema.receipts.markForRetryAfterAccepted,
            );
          },
          from6To7: (m, schema) async {
            await m.addColumn(
              schema.messages,
              schema.messages.additionalMessageData,
            );
          },
          from7To8: (m, schema) async {
            await m.deleteTable('signal_contact_pre_keys');
            await m.deleteTable('signal_contact_signed_pre_keys');
            // For message_actions
            await m.alterTable(TableMigration(schema.messageHistories));
            await m.alterTable(TableMigration(schema.messageActions));
          },
          from8To9: (m, schema) async {
            await m.addColumn(
              schema.mediaFiles,
              schema.mediaFiles.preProgressingProcess,
            );
          },
          from9To10: (m, schema) async {
            await m.addColumn(
              schema.receipts,
              schema.receipts.willBeRetriedByMediaUpload,
            );
          },
          from10To11: (m, schema) async {
            await m.addColumn(
              schema.groupMembers,
              schema.groupMembers.lastChatOpened,
            );
            await m.addColumn(
              schema.groupMembers,
              schema.groupMembers.lastTypeIndicator,
            );
          },
          from11To12: (m, schema) async {
            await m.createTable(schema.verificationTokens);
            await m.createTable(schema.keyVerifications);
            await m.createTable(schema.userDiscoveryAnnouncedUsers);
            await m.createTable(schema.userDiscoveryOwnPromotions);
            await m.createTable(schema.userDiscoveryOtherPromotions);
            await m.createTable(schema.userDiscoveryShares);
            await m.createTable(schema.userDiscoveryUserRelations);
            final columns = [
              schema.contacts.userDiscoveryVersion,
              schema.contacts.mediaReceivedCounter,
              schema.contacts.mediaSendCounter,
              schema.contacts.userDiscoveryExcluded,
              schema.contacts.userDiscoveryManualApproved,
            ];
            for (final column in columns) {
              await m.addColumn(schema.contacts, column);
            }
          },
          from12To13: (m, schema) async {
            await m.createTable(schema.shortcuts);
            await m.createTable(schema.shortcutMembers);
          },
          from13To14: (m, schema) async {
            await m.addColumn(
              schema.mediaFiles,
              schema.mediaFiles.createdAtMonth,
            );
            await m.addColumn(schema.mediaFiles, schema.mediaFiles.isFavorite);
            await m.addColumn(
              schema.mediaFiles,
              schema.mediaFiles.hasCropAnalyzed,
            );
          },
          from14To15: (m, schema) async {
            await m.createTable(schema.signalSignedPreKeyStores);
          },
          from15To16: (m, schema) async {
            await m.addColumn(
              schema.mediaFiles,
              schema.mediaFiles.hasThumbnail,
            );
            await m.addColumn(schema.mediaFiles, schema.mediaFiles.sizeInBytes);
          },
          from16To17: (m, schema) async {
            await m.addColumn(
              schema.userDiscoveryAnnouncedUsers,
              schema.userDiscoveryAnnouncedUsers.wasAskedFriends,
            );
          },
          from17To18: (m, schema) async {
            await m.addColumn(
              schema.contacts,
              schema.contacts.askForFriendPromotions,
            );
          },
          from18To19: (m, schema) async {
            await m.addColumn(
              schema.keyVerifications,
              schema.keyVerifications.verifiedBy,
            );
          },
          from19To20: (m, schema) async {
            await m.addColumn(
              schema.contacts,
              schema.contacts.recoveryIsTrustedFriend,
            );
            await m.addColumn(
              schema.contacts,
              schema.contacts.recoveryLastHeartbeat,
            );
            await m.addColumn(
              schema.contacts,
              schema.contacts.recoverySecretShare,
            );
          },
          from20To21: (m, schema) async {
            await m.addColumn(
              schema.contacts,
              schema.contacts.recoveryContactsSecretShare,
            );
            await m.addColumn(
              schema.contacts,
              schema.contacts.recoveryContactsLastHeartbeat,
            );
          },
          from21To22: (m, schema) async {
            await m.addColumn(
              schema.contacts,
              schema.contacts.recoveryContactsThreshold,
            );
          },
          from22To23: (m, schema) async {
            await m.addColumn(
              schema.mediaFiles,
              schema.mediaFiles.cloudState,
            );
            await m.addColumn(
              schema.mediaFiles,
              schema.mediaFiles.blurhash,
            );
          },
          from23To24: (m, schema) async {
            await m.createTable(schema.labels);
            await m.createTable(schema.contactLabels);
          },
          from24To25: (m, schema) async {
            await m.addColumn(schema.contacts, schema.contacts.signalVersion);
          },
        )(m, from, to);
      },
    );
  }

  void markUpdated() {
    notifyUpdates({
      TableUpdate.onTable(messages, kind: UpdateKind.update),
      TableUpdate.onTable(contacts, kind: UpdateKind.update),
      TableUpdate.onTable(groups, kind: UpdateKind.update),
    });
  }

  Future<void> printTableSizes() async {
    final result = await customSelect(
      'SELECT name, SUM(pgsize) as size FROM dbstat GROUP BY name',
    ).get();

    for (final row in result) {
      final tableName = row.read<String>('name');
      final tableSize = row.read<String>('size');
      Log.info('Table: $tableName, Size: $tableSize bytes');
    }
  }
}
