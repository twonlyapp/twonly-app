import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/daos/messages_dao.dart';
import 'package:twonly/src/database/tables/contacts_table.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/tables/signal_identity_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_pre_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_sender_key_store_table.dart';
import 'package:twonly/src/database/tables/signal_session_store_table.dart';
import 'package:twonly/src/json_models/message.dart';

part 'twonly_database.g.dart';

// You can then create a database class that includes this table
@DriftDatabase(tables: [
  Contacts,
  Messages,
  SignalIdentityKeyStores,
  SignalPreKeyStores,
  SignalSenderKeyStores,
  SignalSessionStores
], daos: [
  MessagesDao,
  ContactsDao
])
class TwonlyDatabase extends _$TwonlyDatabase {
  TwonlyDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'twonly_database',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  void markUpdated() {
    notifyUpdates({TableUpdate.onTable(messages, kind: UpdateKind.update)});
    notifyUpdates({TableUpdate.onTable(contacts, kind: UpdateKind.update)});
  }
}
