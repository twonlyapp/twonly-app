import 'dart:async';
import 'package:drift/drift.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/log.dart';

class DriftLoggingInterceptor extends QueryInterceptor {
  bool get _isEnabled {
    try {
      if (!userService.isUserCreated) return false;
      return userService.currentUser.enableDatabaseLogging;
    } catch (_) {
      return false;
    }
  }

  List<String> _findUuids(dynamic value) {
    if (value == null) return const [];
    final uuids = <String>[];
    final uuidRegex = RegExp(
      '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
    );
    if (value is String) {
      for (final match in uuidRegex.allMatches(value)) {
        uuids.add(match.group(0)!);
      }
    } else if (value is Iterable) {
      for (final element in value) {
        uuids.addAll(_findUuids(element));
      }
    } else if (value is Map) {
      for (final element in value.values) {
        uuids.addAll(_findUuids(element));
      }
    } else {
      final str = value.toString();
      for (final match in uuidRegex.allMatches(str)) {
        uuids.add(match.group(0)!);
      }
    }
    return uuids.toSet().toList();
  }

  Future<T> _run<T>(
    String operation,
    String statement,
    List<Object?> args,
    Future<T> Function() query,
  ) async {
    if (!_isEnabled) {
      return query();
    }
    final stopwatch = Stopwatch()..start();
    try {
      final result = await query();
      final elapsed = stopwatch.elapsedMilliseconds;
      final uuids = _findUuids(args);
      if (uuids.isNotEmpty) {
        Log.info(
          '[DriftDB] $operation succeeded in ${elapsed}ms: "$statement" | UUIDs: $uuids',
        );
      } else {
        Log.info(
          '[DriftDB] $operation succeeded in ${elapsed}ms: "$statement"',
        );
      }
      return result;
    } catch (e) {
      final elapsed = stopwatch.elapsedMilliseconds;
      final uuids = _findUuids(args);
      if (uuids.isNotEmpty) {
        Log.info(
          '[DriftDB] $operation failed after ${elapsed}ms ($e): "$statement" | UUIDs: $uuids',
        );
      } else {
        Log.info(
          '[DriftDB] $operation failed after ${elapsed}ms ($e): "$statement"',
        );
      }
      rethrow;
    }
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run('INSERT', statement, args, () => executor.runInsert(statement, args));
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run('UPDATE', statement, args, () => executor.runUpdate(statement, args));
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run('DELETE', statement, args, () => executor.runDelete(statement, args));
  }

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    return _run('CUSTOM', statement, args, () => executor.runCustom(statement, args));
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) async {
    if (!_isEnabled) {
      return executor.runBatched(statements);
    }
    final stopwatch = Stopwatch()..start();
    try {
      await executor.runBatched(statements);
      final elapsed = stopwatch.elapsedMilliseconds;
      final uuids = <String>[];
      for (final batchArg in statements.arguments) {
        uuids.addAll(_findUuids(batchArg.arguments));
      }
      final statementsStr = statements.statements.join('; ');
      if (uuids.isNotEmpty) {
        Log.info(
          '[DriftDB] BATCH succeeded in ${elapsed}ms: "$statementsStr" | UUIDs: $uuids',
        );
      } else {
        Log.info(
          '[DriftDB] BATCH succeeded in ${elapsed}ms: "$statementsStr"',
        );
      }
    } catch (e) {
      final elapsed = stopwatch.elapsedMilliseconds;
      final uuids = <String>[];
      for (final batchArg in statements.arguments) {
        uuids.addAll(_findUuids(batchArg.arguments));
      }
      final statementsStr = statements.statements.join('; ');
      if (uuids.isNotEmpty) {
        Log.info(
          '[DriftDB] BATCH failed after ${elapsed}ms ($e): "$statementsStr" | UUIDs: $uuids',
        );
      } else {
        Log.info(
          '[DriftDB] BATCH failed after ${elapsed}ms ($e): "$statementsStr"',
        );
      }
      rethrow;
    }
  }
}
