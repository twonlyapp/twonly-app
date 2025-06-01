import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show driftDatabase, DriftNativeOptions;
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/daos/media_downloads_dao.dart';
import 'package:twonly/src/database/daos/media_uploads_dao.dart';
import 'package:twonly/src/database/daos/messages_dao.dart';
import 'package:twonly/src/database/daos/signal_dao.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/tables/media_download_table.dart';
import 'package:twonly/src/database/tables/media_uploads_table.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/tables/signal_contact_prekey_table.dart';
import 'package:twonly/src/database/tables/signal_contact_signed_prekey_table.dart';
import 'package:twonly/src/database/tables/signal_identity_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_pre_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_sender_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_session_store_table.dart';
import 'package:twonly/src/database/twonly_database.steps.dart';

part 'twonly_database.g.dart';

// You can then create a database class that includes this table
@DriftDatabase(tables: [
  Contacts,
  Messages,
  MediaUploads,
  MediaDownloads,
  SignalIdentityKeyStores,
  SignalPreKeyStores,
  SignalSenderKeyStores,
  SignalSessionStores,
  SignalContactPreKeys,
  SignalContactSignedPreKeys
], daos: [
  MessagesDao,
  ContactsDao,
  MediaUploadsDao,
  MediaDownloadsDao,
  SignalDao
])
class TwonlyDatabase extends _$TwonlyDatabase {
  TwonlyDatabase([QueryExecutor? e])
      : super(
          e ?? _openConnection(),
        );

  TwonlyDatabase.forTesting(DatabaseConnection super.connection);

  @override
  int get schemaVersion => 10;

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
          m.addColumn(schema.messages, schema.messages.errorWhileSending);
        },
        from2To3: (m, schema) async {
          m.addColumn(schema.contacts, schema.contacts.archived);
          m.addColumn(
              schema.contacts, schema.contacts.deleteMessagesAfterXMinutes);
        },
        from3To4: (m, schema) async {
          m.createTable(mediaUploads);
          await m.alterTable(TableMigration(
            schema.mediaUploads,
            columnTransformer: {
              schema.mediaUploads.metadata:
                  schema.mediaUploads.metadata.cast<String>(),
            },
          ));
        },
        from4To5: (m, schema) async {
          m.createTable(mediaDownloads);
          m.addColumn(schema.messages, schema.messages.mediaDownloadId);
          m.addColumn(schema.messages, schema.messages.mediaUploadId);
        },
        from5To6: (m, schema) async {
          m.addColumn(schema.messages, schema.messages.mediaStored);
        },
        from6To7: (m, schema) async {
          m.addColumn(schema.contacts, schema.contacts.pinned);
        },
        from7To8: (m, schema) async {
          m.addColumn(schema.contacts, schema.contacts.alsoBestFriend);
          m.addColumn(schema.contacts, schema.contacts.lastFlameSync);
        },
        from8To9: (m, schema) async {
          await m.alterTable(TableMigration(
            schema.mediaUploads,
            columnTransformer: {
              schema.mediaUploads.metadata:
                  schema.mediaUploads.metadata.cast<String>(),
            },
          ));
        },
        from9To10: (m, schema) async {
          m.createTable(signalContactPreKeys);
          m.createTable(signalContactSignedPreKeys);
          m.addColumn(schema.contacts, schema.contacts.deleted);
        },
      ),
    );
  }

  void markUpdated() {
    notifyUpdates({TableUpdate.onTable(messages, kind: UpdateKind.update)});
    notifyUpdates({TableUpdate.onTable(contacts, kind: UpdateKind.update)});
  }
}
