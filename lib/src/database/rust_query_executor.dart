import 'package:drift/backends.dart';
import 'package:drift/drift.dart';
import 'package:twonly/core/bridge/wrapper/app_database.dart';
import 'package:twonly/core/database/app.dart' as rust;

/// Drift compatibility executor backed by the Rust-owned SQLCipher database.
///
/// This keeps the existing generated models, DAO methods and query watches
/// while moving connection, encryption and storage ownership into Rust.
QueryExecutor openRustAppDatabase() => DelegatedDatabase(
  _RustDatabaseDelegate(),
  isSequential: true,
);

class _RustDatabaseDelegate extends DatabaseDelegate {
  @override
  Future<bool> get isOpen async => true;

  @override
  DbVersionDelegate get versionDelegate => const NoVersionDelegate();

  @override
  TransactionDelegate get transactionDelegate => const NoTransactionDelegate();

  @override
  Future<void> open(QueryExecutorUser db) async {}

  @override
  Future<void> close() async {
    // The Rust application context owns the database lifecycle.
  }

  @override
  Future<QueryResult> runSelect(String statement, List<Object?> args) async {
    final result = await RustAppDatabase.select(
      statement: statement,
      arguments: args.map(_encode).toList(growable: false),
    );
    return QueryResult(
      result.columns,
      result.rows
          .map((row) => row.values.map(_decode).toList(growable: false))
          .toList(growable: false),
    );
  }

  @override
  Future<int> runInsert(String statement, List<Object?> args) async {
    final result = await _execute(statement, args);
    return result.lastInsertRowId;
  }

  @override
  Future<int> runUpdate(String statement, List<Object?> args) async {
    final result = await _execute(statement, args);
    return result.affectedRows;
  }

  @override
  Future<void> runCustom(String statement, List<Object?> args) async {
    await _execute(statement, args);
  }

  Future<rust.SqlExecutionResult> _execute(
    String statement,
    List<Object?> args,
  ) {
    return RustAppDatabase.execute(
      statement: statement,
      arguments: args.map(_encode).toList(growable: false),
    );
  }
}

rust.SqlValue _encode(Object? value) {
  return switch (value) {
    null => const rust.SqlValue(kind: 0),
    final bool value => rust.SqlValue(kind: 1, integerValue: value ? 1 : 0),
    final int value => rust.SqlValue(kind: 1, integerValue: value),
    final double value => rust.SqlValue(kind: 2, realValue: value),
    final String value => rust.SqlValue(kind: 3, textValue: value),
    final Uint8List value => rust.SqlValue(kind: 4, blobValue: value),
    _ => throw ArgumentError.value(value, 'value', 'Unsupported SQLite value'),
  };
}

Object? _decode(rust.SqlValue value) {
  return switch (value.kind) {
    0 => null,
    1 => value.integerValue,
    2 => value.realValue,
    3 => value.textValue,
    4 => value.blobValue,
    _ => throw StateError('Unknown SQLite value kind ${value.kind}'),
  };
}
