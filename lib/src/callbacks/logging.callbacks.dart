import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/utils/log.dart';

/// Matches ANSI escape sequences (CSI sequences, caret notation like ^[[3m or \^[[3m).
final _ansiRegex = RegExp(r'(?:\x1B|\\?\^\[)\[[0-?]*[ -/]*[@-~]');

/// Matches the plain `ShortEventFormatter` output from `rust/src/log.rs`:
/// `HH:MM:SS LEVEL dir/file.rs:12 <fields> <message>`.
final _rustLogLine = RegExp(
  r'^\d{2}:\d{2}:\d{2} (TRACE|DEBUG|INFO|WARN|ERROR) +(\S+:\d+) ?(.*)$',
  dotAll: true,
);

/// Rust levels mapped onto the `logging` levels the Dart side already prints.
/// `SHOUT` is what [Log.error] uses, so a Rust `ERROR` reads the same as a Dart
/// one.
const Map<String, Level> _levels = {
  'TRACE': Level.FINEST,
  'DEBUG': Level.FINE,
  'INFO': Level.INFO,
  'WARN': Level.WARNING,
  'ERROR': Level.SHOUT,
};

class LoggingCallbacks {
  static Future<RustStreamSink<String>> getStreamSink() async {
    final dartLogSink = RustStreamSink<String>();

    // `stream` throws until flutter_rust_bridge has serialized the sink for
    // Rust, which only happens once this function has returned. Poll for it
    // instead of racing; buffered events are replayed on the first listen.
    var attempts = 0;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      attempts++;
      try {
        dartLogSink.stream.listen(_handleRustLog);
        timer.cancel();
      } catch (_) {
        // Stream not yet initialized.
        if (attempts >= 100) {
          timer.cancel();
          Log.warn('Rust log sink never became available.');
        }
      }
    });

    return dartLogSink;
  }

  @visibleForTesting
  static void handleRustLog(String log) => _handleRustLog(log);

  static void _handleRustLog(String log) {
    final sanitizedLog = log.replaceAll(_ansiRegex, '');
    final match = _rustLogLine.firstMatch(sanitizedLog);
    if (match == null) {
      // Not a formatted event (panic output, a continuation line, ...).
      Log.warn(sanitizedLog);
      return;
    }

    // The level and the `file.rs:line` origin belong in the record itself, not
    // repeated inside the message: the Dart call site here says nothing useful.
    Log.forward(
      level: _levels[match.group(1)] ?? Level.INFO,
      source: match.group(2)!,
      messageInput: match.group(3),
    );
  }
}
