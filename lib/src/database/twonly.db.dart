import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show DriftNativeOptions, driftDatabase;
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/groups.dao.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/daos/mediafiles.dao.dart';
import 'package:twonly/src/database/daos/messages.dao.dart';
import 'package:twonly/src/database/daos/reactions.dao.dart';
import 'package:twonly/src/database/daos/receipts.dao.dart';
import 'package:twonly/src/database/daos/user_discovery.dao.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/tables/reactions.table.dart';
import 'package:twonly/src/database/tables/receipts.table.dart';
import 'package:twonly/src/database/tables/signal_identity_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_pre_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_sender_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_session_store.table.dart';
import 'package:twonly/src/database/tables/user_discovery.table.dart';
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
    SignalIdentityKeyStores,
    SignalPreKeyStores,
    SignalSenderKeyStores,
    SignalSessionStores,
    MessageActions,
    GroupHistories,
    KeyVerifications,
    VerificationTokens,
    UserDiscoveryAnnouncedUsers,
    UserDiscoveryUserRelations,
    UserDiscoveryOtherPromotions,
    UserDiscoveryOwnPromotions,
    UserDiscoveryShares,
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
  ],
)
class TwonlyDB extends _$TwonlyDB {
  TwonlyDB([QueryExecutor? e])
    : super(
        e ?? _openConnection(),
      );

  // ignore: matching_super_parameters
  TwonlyDB.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 12;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'twonly',
      native: DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
        shareAcrossIsolates: true,
        setup: (rawDb) {
          rawDb
            ..execute('PRAGMA journal_mode=WAL;')
            ..execute('PRAGMA busy_timeout=5000;');
        },
      ),
    );
  }

  @override
  MigrationStrategy get migration {
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
        )(m, from, to);
      },
    );
  }

  void markUpdated() {
    notifyUpdates({TableUpdate.onTable(messages, kind: UpdateKind.update)});
    notifyUpdates({TableUpdate.onTable(contacts, kind: UpdateKind.update)});
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

  Future<void> deleteDataForTwonlySafe() async {
    await (delete(messages)..where(
          (t) =>
              (t.mediaStored.equals(false) &
              t.isDeletedFromSender.equals(false)),
        ))
        .go();
    await update(messages).write(
      const MessagesCompanion(
        downloadToken: Value(null),
      ),
    );
    await (delete(mediaFiles)..where(
          (t) => (t.stored.equals(false)),
        ))
        .go();
    await delete(receipts).go();
    await delete(receivedReceipts).go();
    await update(contacts).write(
      const ContactsCompanion(
        avatarSvgCompressed: Value(null),
        senderProfileCounter: Value(0),
      ),
    );
    await (delete(signalPreKeyStores)..where(
          (t) => (t.createdAt.isSmallerThanValue(
            clock.now().subtract(
              const Duration(days: 25),
            ),
          )),
        ))
        .go();
  }
}
