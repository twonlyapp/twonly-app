import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/services/api/rust_api_result.dart';

void main() {
  test(
    'only known database lifecycle messages are background cancellation',
    () {
      for (final message in [
        'Database operation cancelled; retry when active',
        'Native database admission cancelled',
        'Database operation deferred until foreground',
        'attempted to acquire a connection on a closed pool',
      ]) {
        expect(isBackgroundCancellation(Exception(message)), isTrue);
      }
      for (final message in [
        'response channel closed',
        'database is corrupt',
        'send error: NotConnected (timeout)',
      ]) {
        expect(isBackgroundCancellation(Exception(message)), isFalse);
      }
    },
  );

  test(
    'unawaited transport failures retain a warning and their original stack',
    () async {
      final previous = Logger.root.level;
      Logger.root.level = Level.ALL;
      final records = <LogRecord>[];
      final subscription = Logger.root.onRecord.listen(records.add);
      final error = Exception('response channel closed');
      final stack = StackTrace.fromString('transport.dart:7');
      try {
        unawaitedRustCall(Future<void>.error(error, stack), 'Reopen update');
        await Future<void>.delayed(Duration.zero);
        expect(records.single.level, Level.WARNING);
        expect(records.single.error, same(error));
        expect(records.single.stackTrace, same(stack));
      } finally {
        await subscription.cancel();
        Logger.root.level = previous;
      }
    },
  );
}
