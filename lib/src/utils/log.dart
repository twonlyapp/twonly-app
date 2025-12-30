import 'dart:io';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/globals.dart';

void initLogger() {
  // Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) async {
    await _writeLogToFile(record);
    if (!kReleaseMode) {
      // ignore: avoid_print
      print(
        '${record.level.name} [twonly] ${record.loggerName} > ${record.message}',
      );
    }
  });
  cleanLogFile();
}

class Log {
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
    if (globalAllowErrorTrackingViaSentry) {
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

Mutex writeToLogGuard = Mutex();

Future<String> loadLogFile() async {
  final directory = await getApplicationSupportDirectory();
  final logFile = File('${directory.path}/app.log');

  if (logFile.existsSync()) {
    return logFile.readAsString();
  } else {
    return 'Log file does not exist.';
  }
}

Future<String> readLast1000Lines() async {
  final dir = await getApplicationSupportDirectory();
  final file = File('${dir.path}/app.log');
  if (!file.existsSync()) return '';
  final all = await file.readAsLines();
  final start = all.length > 1000 ? all.length - 1000 : 0;
  return all.sublist(start).join('\n');
}

Future<void> _writeLogToFile(LogRecord record) async {
  final directory = await getApplicationSupportDirectory();
  final logFile = File('${directory.path}/app.log');
  if (!logFile.existsSync()) {
    logFile.createSync(recursive: true);
  }

  // Prepare the log message
  final logMessage =
      '${clock.now().toString().split(".")[0]} ${record.level.name} [twonly] ${record.loggerName} > ${record.message}\n';

  await writeToLogGuard.protect(() async {
    // Append the log message to the file
    await logFile.writeAsString(logMessage, mode: FileMode.append);
  });
}

Future<void> cleanLogFile() async {
  final directory = await getApplicationSupportDirectory();
  final logFile = File('${directory.path}/app.log');

  if (logFile.existsSync()) {
    final lines = await logFile.readAsLines();

    if (lines.length <= 5000) return;

    final removeCount = lines.length - 5000;
    final remaining = lines.sublist(removeCount);

    final sink = logFile.openWrite()..writeAll(remaining, '\n');
    await sink.close();
  }
}

Future<bool> deleteLogFile() async {
  final directory = await getApplicationSupportDirectory();
  final logFile = File('${directory.path}/app.log');

  if (logFile.existsSync()) {
    await logFile.delete();
    return true;
  }
  return false;
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
    fileName =
        firstLine.split('/').last.split(':').first; // Extract the file name
    lineNumber = firstLine.split(':')[1]; // Extract the line number
  }
  lineNumber = lineNumber.replaceAll(')', '');
  return '$fileName:$lineNumber';
}
