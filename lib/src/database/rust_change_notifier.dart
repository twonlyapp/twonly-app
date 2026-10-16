import 'dart:async';

import 'package:drift/drift.dart';
import 'package:twonly/core/bridge/wrapper/app_database.dart';
import 'package:twonly/src/utils/log.dart';

/// Bridges Rust-side commits into Drift's stream query invalidation.
///
/// Rust owns the SQLite connection. Statements Drift issues go through
/// `openRustAppDatabase` and invalidate its query streams as usual, but every
/// write Rust performs on its own bypasses that executor entirely — Drift never
/// learns about it, so `watch()` keeps serving stale rows and the UI does not
/// update until something else happens to touch the same table.
///
/// SQLite's own commit hook broadcasts the tables each committed transaction
/// touched; this forwards those batches into [GeneratedDatabase.notifyUpdates].
StreamSubscription<List<String>> listenToRustDatabaseChanges(
  GeneratedDatabase db,
) {
  return RustAppDatabase.changes().listen(
    (tables) {
      // An empty batch means Rust could not tell us precisely what changed
      // (fresh subscription, or dropped notifications). Invalidate everything
      // rather than leaving the UI stale.
      final updates = tables.isEmpty
          ? db.allTables.map(TableUpdate.onTable).toSet()
          : tables.map(TableUpdate.new).toSet();
      db.notifyUpdates(updates);
    },
    onError: (Object error, StackTrace stackTrace) {
      Log.error(
        'Rust database change stream failed',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}
