import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show DriftNativeOptions, driftDatabase;
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/daos/media_uploads_dao.dart';
import 'package:twonly/src/database/daos/message_retransmissions.dao.dart';
import 'package:twonly/src/database/daos/messages_dao.dart';
import 'package:twonly/src/database/daos/signal_dao.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/tables/media_uploads_table.dart';
import 'package:twonly/src/database/tables/message_retransmissions.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/tables/signal_contact_prekey_table.dart';
import 'package:twonly/src/database/tables/signal_contact_signed_prekey_table.dart';
import 'package:twonly/src/database/tables/signal_identity_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_pre_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_sender_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_session_store_table.dart';
import 'package:twonly/src/database/twonly_database.steps.dart';
import 'package:twonly/src/utils/log.dart';

part 'twonly_database.g.dart';

// You can then create a database class that includes this table
@DriftDatabase(
  tables: [
    Contacts,
    Messages,
    MediaUploads,
    SignalIdentityKeyStores,
    SignalPreKeyStores,
    SignalSenderKeyStores,
    SignalSessionStores,
    SignalContactPreKeys,
    SignalContactSignedPreKeys,
    MessageRetransmissions,
  ],
  daos: [
    MessagesDao,
    ContactsDao,
    MediaUploadsDao,
    SignalDao,
    MessageRetransmissionDao,
  ],
)
class TwonlyDatabase extends _$TwonlyDatabase {
  TwonlyDatabase([QueryExecutor? e])
      : super(
          e ?? _openConnection(),
        );

  // ignore: matching_super_parameters
  TwonlyDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 17;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'twonly_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: stepByStep(
        from1To2: (m, schema) async {
          await m.addColumn(schema.messages, schema.messages.errorWhileSending);
        },
        from2To3: (m, schema) async {
          await m.addColumn(schema.contacts, schema.contacts.archived);
          await m.addColumn(
            schema.contacts,
            schema.contacts.deleteMessagesAfterXMinutes,
          );
        },
        from3To4: (m, schema) async {
          await m.createTable(schema.mediaUploads);
          await m.alterTable(
            TableMigration(
              schema.mediaUploads,
              columnTransformer: {
                schema.mediaUploads.metadata:
                    schema.mediaUploads.metadata.cast<String>(),
              },
            ),
          );
        },
        from4To5: (m, schema) async {
          await m.createTable(schema.mediaDownloads);
          await m.addColumn(schema.messages, schema.messages.mediaDownloadId);
          await m.addColumn(schema.messages, schema.messages.mediaUploadId);
        },
        from5To6: (m, schema) async {
          await m.addColumn(schema.messages, schema.messages.mediaStored);
        },
        from6To7: (m, schema) async {
          await m.addColumn(schema.contacts, schema.contacts.pinned);
        },
        from7To8: (m, schema) async {
          await m.addColumn(schema.contacts, schema.contacts.alsoBestFriend);
          await m.addColumn(schema.contacts, schema.contacts.lastFlameSync);
        },
        from8To9: (m, schema) async {
          await m.alterTable(
            TableMigration(
              schema.mediaUploads,
              columnTransformer: {
                schema.mediaUploads.metadata:
                    schema.mediaUploads.metadata.cast<String>(),
              },
            ),
          );
        },
        from9To10: (m, schema) async {
          await m.createTable(schema.signalContactPreKeys);
          await m.createTable(schema.signalContactSignedPreKeys);
          await m.addColumn(schema.contacts, schema.contacts.deleted);
        },
        from10To11: (m, schema) async {
          await m.createTable(schema.messageRetransmissions);
        },
        from11To12: (m, schema) async {
          await m.addColumn(
            schema.messageRetransmissions,
            schema.messageRetransmissions.willNotGetACKByUser,
          );
        },
        from12To13: (m, schema) async {
          await m.dropColumn(
            schema.messageRetransmissions,
            'will_not_get_a_c_k_by_user',
          );
        },
        from13To14: (m, schema) async {
          await m.addColumn(
            schema.messageRetransmissions,
            schema.messageRetransmissions.encryptedHash,
          );
        },
        from14To15: (m, schema) async {
          await m.dropColumn(schema.mediaUploads, 'upload_tokens');
          await m.dropColumn(schema.mediaUploads, 'already_notified');
          await m.addColumn(
            schema.messages,
            schema.messages.mediaRetransmissionState,
          );
        },
        from15To16: (m, schema) async {
          await m.deleteTable('media_downloads');
        },
        from16To17: (m, schema) async {
          await m.addColumn(
            schema.messageRetransmissions,
            schema.messageRetransmissions.lastRetry,
          );
          await m.addColumn(
            schema.messageRetransmissions,
            schema.messageRetransmissions.retryCount,
          );
        },
      ),
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
    await delete(messages).go();
    await delete(messageRetransmissions).go();
    await delete(mediaUploads).go();
    await update(contacts).write(
      const ContactsCompanion(
        avatarSvg: Value(null),
        myAvatarCounter: Value(0),
      ),
    );
    await delete(signalContactPreKeys).go();
    await delete(signalContactSignedPreKeys).go();
    await (delete(signalPreKeyStores)
          ..where(
            (t) => (t.createdAt.isSmallerThanValue(
              DateTime.now().subtract(
                const Duration(days: 25),
              ),
            )),
          ))
        .go();
  }
}
