import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/core/bridge/logging.dart' as rust_logging;
import 'package:twonly/globals.dart';

class Log {
  static bool _isInitialized = false;
  static bool _rustSinkReady = false;
  static const int _maxBufferedRecords = 1000;
  static final List<LogRecord> _bufferedRecords = [];

  static void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      if (_rustSinkReady) {
        if (!_writeLogToRust(record)) {
          _rustSinkReady = false;
          _buffer(record);
        }
      } else {
        _buffer(record);
      }
      if (!kReleaseMode) {
        if (!Platform.environment.containsKey('FLUTTER_TEST') ||
            record.level >= Level.WARNING) {
          // ignore: avoid_print
          print(
            '${record.level.name} [${AppState.isInBackgroundTask ? 'b' : 'f'}] [twonly] ${record.loggerName} > ${record.message}',
          );
        }
      }
    });
  }

  /// Enables the Rust-owned app.log and flushes records emitted before Rust
  /// initialization completed.
  static void enableRustSink() {
    if (_rustSinkReady) return;
    _rustSinkReady = true;
    final pending = List<LogRecord>.of(_bufferedRecords);
    _bufferedRecords.clear();
    for (var i = 0; i < pending.length; i++) {
      if (_writeLogToRust(pending[i])) continue;
      _rustSinkReady = false;
      for (var j = i; j < pending.length; j++) {
        _buffer(pending[j]);
      }
      break;
    }
  }

  static void _buffer(LogRecord record) {
    if (_bufferedRecords.length == _maxBufferedRecords) {
      _bufferedRecords.removeAt(0);
    }
    _bufferedRecords.add(record);
  }

  static bool _writeLogToRust(LogRecord record) {
    try {
      rust_logging.writeLog(
        level: switch (record.level) {
          >= Level.SHOUT => rust_logging.LogLevel.shout,
          >= Level.WARNING => rust_logging.LogLevel.warning,
          >= Level.INFO => rust_logging.LogLevel.info,
          >= Level.FINE => rust_logging.LogLevel.fine,
          _ => rust_logging.LogLevel.finest,
        },
        source: record.loggerName,
        message: record.message,
        inBackground: AppState.isInBackgroundTask,
      );
      return true;
    } catch (error) {
      if (!kReleaseMode) {
        // ignore: avoid_print
        print('Could not forward log record to Rust: $error');
      }
      return false;
    }
  }

  static String filterLogMessage(String msg) {
    if (msg.contains('SqliteException')) {
      // Do not log data which would be inserted into the DB.
      final paramIndex = msg.indexOf('parameters: ');
      if (paramIndex != -1) {
        return msg.substring(0, paramIndex);
      }
    }
    return msg;
  }

  static void error(
    Object? messageInput, {
    Object? error,
    StackTrace? stackTrace,
    bool onlyIfSentryEnabled = false,
  }) {
    if (!AppState.allowErrorTrackingViaSentry && onlyIfSentryEnabled) {
      return;
    }
    final message = filterLogMessage('$messageInput');
    if (AppState.allowErrorTrackingViaSentry) {
      try {
        throw Exception(message);
      } catch (exception, stackTrace) {
        Sentry.captureException(exception, stackTrace: stackTrace);
      }
    }
    Logger(_getCallerSourceCodeFilename()).shout(message, error, stackTrace);
  }

  static void warn(
    Object? messageInput, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final message = filterLogMessage('$messageInput');
    Logger(_getCallerSourceCodeFilename()).warning(message, error, stackTrace);
  }

  static void info(
    Object? messageInput, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final message = filterLogMessage('$messageInput');
    Logger(_getCallerSourceCodeFilename()).fine(message, error, stackTrace);
  }
}

Future<String> loadLogFile() async {
  return rust_logging.loadLogFile();
}

Future<String> readLast1000Lines() async {
  return rust_logging.readLastLogLines(lineCount: 1000);
}

Future<void> cleanLogFile() async {
  return rust_logging.cleanLogFile();
}

Future<bool> deleteLogFile() async {
  return rust_logging.clearLogFile();
}

String _getCallerSourceCodeFilename() {
  final stackTrace = StackTrace.current;
  final stackTraceString = stackTrace.toString();
  var fileName = '';
  var lineNumber = '';
  final stackLines = stackTraceString.split('\n');
  if (stackLines.length > 2) {
    final callerInfo = stackLines[2];
    final parts = callerInfo.split('/');
    fileName = parts.last.split(':').first; // Extract the file name
    lineNumber = parts.last.split(':')[1]; // Extract the line number
  } else {
    final firstLine = stackTraceString.split('\n')[0];
    fileName = firstLine
        .split('/')
        .last
        .split(':')
        .first; // Extract the file name
    lineNumber = firstLine.split(':')[1]; // Extract the line number
  }
  lineNumber = lineNumber.replaceAll(')', '');
  return '$fileName:$lineNumber';
}
