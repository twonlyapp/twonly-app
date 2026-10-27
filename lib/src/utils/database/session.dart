import 'dart:async';

import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/bridge/database/transactions.dart';
import 'package:twonly/src/utils/log.dart';

final _transactionScopeKey = Object();
DatabaseSession? _defaultSession;

class _RustTransactionScope {
  _RustTransactionScope(this.transaction) : session = transaction.session();

  final DatabaseTransaction transaction;
  final DatabaseSession session;
  bool active = true;

  void checkActive() {
    if (!active) throw StateError('Rust transaction scope is closed');
  }
}

_RustTransactionScope? _scopeFor() {
  final scope = Zone.current[_transactionScopeKey] as _RustTransactionScope?;
  return scope;
}

/// Commands join only the transaction belonging to this caller and database.
/// An escaped callback fails once its scope closes instead of writing later.
DatabaseSession currentDatabaseSession() {
  final scope = _scopeFor();
  if (scope != null) {
    scope.checkActive();
    return scope.session;
  }
  return _defaultSession ??= DatabaseSession();
}

/// Rust owns the connection, savepoints, commit and rollback. Nested callbacks
/// always get their own savepoint, including when their errors are caught.
Future<T> withDatabaseTransaction<T>(
  Future<T> Function() action,
) async {
  final parent = _scopeFor();
  parent?.checkActive();
  final transaction = parent == null
      ? await DatabaseTransaction.begin()
      : await parent.transaction.beginNested();
  final scope = _RustTransactionScope(transaction);
  try {
    return await runZoned(() async {
      try {
        final result = await action();
        scope.active = false;
        await transaction.commit();
        return result;
      } catch (error, stackTrace) {
        scope.active = false;
        try {
          await transaction.rollback();
        } catch (rollbackError) {
          Log.warn(
            'Rolling back a native database transaction failed: $rollbackError',
          );
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
    }, zoneValues: {_transactionScopeKey: scope});
  } finally {
    scope.active = false;
    scope.session.dispose();
    transaction.dispose();
  }
}
