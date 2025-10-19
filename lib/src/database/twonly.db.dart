import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show DriftNativeOptions, driftDatabase;
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/groups.dao.dart';
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
    SignalIdentityKeyStores,
    SignalPreKeyStores,
    SignalSenderKeyStores,
    SignalSessionStores,
    SignalContactPreKeys,
    SignalContactSignedPreKeys,
  ],
  daos: [
    MessagesDao,
    ContactsDao,
    SignalDao,
    ReceiptsDao,
    GroupsDao,
    ReactionsDao
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
  int get schemaVersion => 1;

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
      // onUpgrade: stepByStep(),
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
    // await delete(messages).go();
    // await delete(messageRetransmissions).go();
    // await delete(mediaUploads).go();
    // await update(contacts).write(
    //   const ContactsCompanion(
    //     avatarSvg: Value(null),
    //     myAvatarCounter: Value(0),
    //   ),
    // );
    // await delete(signalContactPreKeys).go();
    // await delete(signalContactSignedPreKeys).go();
    // await (delete(signalPreKeyStores)
    //       ..where(
    //         (t) => (t.createdAt.isSmallerThanValue(
    //           DateTime.now().subtract(
    //             const Duration(days: 25),
    //           ),
    //         )),
    //       ))
    //     .go();
  }
}
