import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart'
    show DriftNativeOptions, driftDatabase;
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/database/tables/signal_identity_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_pre_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_sender_key_store.table.dart';
import 'package:twonly/src/database/tables/signal_session_store.table.dart';
import 'package:twonly/src/database/tables/signal_signed_pre_key_store.table.dart';

part 'signal.db.g.dart';

@DriftDatabase(
  tables: [
    SignalIdentityKeyStores,
    SignalPreKeyStores,
    SignalSenderKeyStores,
    SignalSessionStores,
    SignalSignedPreKeyStores,
  ],
)
class SignalDB extends _$SignalDB {
  SignalDB([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  // This database shares the legacy twonly.sqlite file, whose user_version is
  // already 25. Keeping that version avoids a false downgrade while only the
  // Signal tables remain owned by Drift.
  int get schemaVersion => 25;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'twonly',
      native: DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
        shareAcrossIsolates: true,
        setup: (database) {
          database
            ..execute('PRAGMA journal_mode=DELETE;')
            ..execute('PRAGMA synchronous=FULL;')
            ..execute('PRAGMA busy_timeout=5000;')
            ..execute('PRAGMA foreign_keys=ON;');
        },
      ),
    );
  }
}
