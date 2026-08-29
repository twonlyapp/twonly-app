import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/callbacks/logging.callbacks.dart';

void main() {
  group('LoggingCallbacks ANSI stripping', () {
    test('removes raw ANSI color escape sequences', () {
      LogRecord? captured;
      final sub = Logger.root.onRecord.listen((record) {
        captured = record;
      });

      const rawAnsiLog =
          '12:34:56 INFO dir/test.rs:42 \x1b[3mreceipt_id\x1b[0m\x1b[2m=\x1b[0m"d9891084-0f7c-4f30-958d-d8619df5a91c" Handling incoming message: FlameSync';

      LoggingCallbacks.handleRustLog(rawAnsiLog);

      expect(captured, isNotNull);
      expect(captured!.loggerName, 'dir/test.rs:42');
      expect(
        captured!.message,
        'receipt_id="d9891084-0f7c-4f30-958d-d8619df5a91c" Handling incoming message: FlameSync',
      );

      sub.cancel();
    });

    test('removes escaped caret ANSI notation', () {
      LogRecord? captured;
      final sub = Logger.root.onRecord.listen((record) {
        captured = record;
      });

      const caretLog =
          r'12:34:56 INFO dir/test.rs:42 \^[[3mreceipt_id\^[[0m\^[[2m=\^[[0m"d9891084" \^[[3mkind\^[[0m\^[[2m=\^[[0m"FlameSync" Handling incoming message';

      LoggingCallbacks.handleRustLog(caretLog);

      expect(captured, isNotNull);
      expect(
        captured!.message,
        'receipt_id="d9891084" kind="FlameSync" Handling incoming message',
      );

      sub.cancel();
    });
  });
}
