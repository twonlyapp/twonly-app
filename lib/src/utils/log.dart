import 'dart:async';
import 'dart:io';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/exclusive_access.utils.dart';

class Log {
  static bool _isInitialized = false;

  static void init() {
    if (_isInitialized) return;
    _isInitialized = true;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) async {
      unawaited(_writeLogToFile(record));
      if (!kReleaseMode) {
        // ignore: avoid_print
        print(
          '${record.level.name} [${AppState.isInBackgroundTask ? 'b' : 'f'}] [twonly] ${record.loggerName} > ${record.message}',
        );
      }
    });
    cleanLogFile();
  }

  static String filterLogMessage(String msg) {
    if (msg.contains('SqliteException')) {
      // Do not log data which would be inserted into the DB.
      return msg.substring(0, msg.indexOf('parameters: '));
    }
    return msg;
  }

  static void error(
    Object? messageInput, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
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
  return _protectFileAccess(() async {
    final logFile = File('${AppEnvironment.supportDir}/app.log');

    if (logFile.existsSync()) {
      return logFile.readAsString();
    } else {
      return 'Log file does not exist.';
    }
  });
}

Future<String> readLast1000Lines() async {
  return _protectFileAccess(() async {
    final file = File('${AppEnvironment.supportDir}/app.log');
    if (!file.existsSync()) return '';
    final all = await file.readAsLines();
    final start = all.length > 1000 ? all.length - 1000 : 0;
    return all.sublist(start).join('\n');
  });
}

final Mutex _logMutex = Mutex();

Future<T> _protectFileAccess<T>(Future<T> Function() action) async {
  return exclusiveAccess(
    lockName: 'app.log',
    action: action,
    mutex: _logMutex,
  );
}

Future<void> _writeLogToFile(LogRecord record) async {
  final logFile = File('${AppEnvironment.supportDir}/app.log');

  final logMessage =
      '${clock.now().toString().split(".")[0]} ${record.level.name} [${AppState.isInBackgroundTask ? 'b' : 'f'}] [twonly] ${record.loggerName} > ${record.message}\n';

  return _protectFileAccess(() async {
    if (!logFile.existsSync()) {
      logFile.createSync(recursive: true);
    }
    final raf = await logFile.open(mode: FileMode.writeOnlyAppend);
    try {
      await raf.writeString(logMessage);
      await raf.flush();
    } catch (e) {
      // ignore: avoid_print
      print('Error during file access: $e');
    } finally {
      await raf.close();
    }
  });
}

Future<void> cleanLogFile() async {
  return _protectFileAccess(() async {
    final logFile = File('${AppEnvironment.supportDir}/app.log');

    if (!logFile.existsSync()) {
      return;
    }
    final lines = await logFile.readAsLines();

    final twoWeekAgo = clock.now().subtract(const Duration(days: 14));
    var keepStartIndex = -1;

    for (var i = 0; i < lines.length; i += 100) {
      if (lines[i].length >= 19) {
        final date = DateTime.tryParse(lines[i].substring(0, 19));
        if (date != null && date.isAfter(twoWeekAgo)) {
          keepStartIndex = i;
          break;
        }
      }
    }

    if (keepStartIndex == 0) return;

    if (keepStartIndex == -1) {
      await logFile.writeAsString('');
      return;
    }

    final remaining = lines.sublist(keepStartIndex);
    final sink = logFile.openWrite()..writeAll(remaining, '\n');
    await sink.close();
  });
}

Future<bool> deleteLogFile() async {
  return _protectFileAccess(() async {
    final logFile = File('${AppEnvironment.supportDir}/app.log');

    if (logFile.existsSync()) {
      await logFile.delete();
      return true;
    }
    return false;
  });
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
