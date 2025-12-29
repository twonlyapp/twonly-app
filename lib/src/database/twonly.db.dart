import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show DriftNativeOptions, driftDatabase;
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/groups.dao.dart';
import 'package:twonly/src/database/daos/mediafiles.dao.dart';
import 'package:twonly/src/database/daos/messages.dao.dart';
import 'package:twonly/src/database/daos/reactions.dao.dart';
import 'package:twonly/src/database/daos/receipts.dao.dart';
import 'package:twonly/src/database/daos/signal.dao.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/tables/groups.table.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/tables/reactions.table.dart';
import 'package:twonly/src/database/tables/receipts.table.dart';
import 'package:twonly/src/database/tables/signal_contact_prekey.table.dart';
import 'package:twonly/src/database/tables/signal_contact_signed_prekey.table.dart';
import 'package:twonly/src/database/tables/signal_identity_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_pre_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_sender_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_session_store.table.dart';
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
    SignalContactPreKeys,
    SignalContactSignedPreKeys,
    MessageActions,
    GroupHistories,
  ],
  daos: [
    MessagesDao,
    ContactsDao,
    SignalDao,
    ReceiptsDao,
    GroupsDao,
    ReactionsDao,
    MediaFilesDao,
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
  int get schemaVersion => 5;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'twonly',
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
    await (delete(messages)
          ..where(
            (t) => (t.mediaStored.equals(false) &
                t.isDeletedFromSender.equals(false)),
          ))
        .go();
    await update(messages).write(
      const MessagesCompanion(
        downloadToken: Value(null),
      ),
    );
    await (delete(mediaFiles)
          ..where(
            (t) => (t.stored.equals(false)),
          ))
        .go();
    await delete(receipts).go();
    await update(contacts).write(
      const ContactsCompanion(
        avatarSvgCompressed: Value(null),
        senderProfileCounter: Value(0),
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
