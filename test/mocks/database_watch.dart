import 'package:twonly/core/bridge/database.dart';

/// Cancellation handle for tests whose mocked API returns ordinary Dart streams.
class TestDatabaseWatch implements DatabaseWatch {
  @override
  void cancel() {}

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
