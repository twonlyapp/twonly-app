import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';

void initLogger() {
  // Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) async {
    await _writeLogToFile(record);
    if (kDebugMode) {
      print(
          '${record.level.name} [twonly] ${record.loggerName} > ${record.message}');
    }
  });
}

class Log {
  static void error(Object? message, [Object? error, StackTrace? stackTrace]) {
    Logger(_getCallerSourceCodeFilename()).shout(message, error, stackTrace);
  }

  static void warn(Object? message, [Object? error, StackTrace? stackTrace]) {
    Logger(_getCallerSourceCodeFilename()).warning(message, error, stackTrace);
  }

  static void info(Object? message, [Object? error, StackTrace? stackTrace]) {
    Logger(_getCallerSourceCodeFilename()).fine(message, error, stackTrace);
  }
}

Mutex writeToLogGuard = Mutex();

Future<void> _writeLogToFile(LogRecord record) async {
  final directory = await getApplicationSupportDirectory();
  final logFile = File('${directory.path}/app.log');

  // Prepare the log message
  final logMessage =
      '${DateTime.now().toString().split(".")[0]} ${record.level.name} [twonly] ${record.loggerName} > ${record.message}\n';

  writeToLogGuard.protect(() async {
    // Append the log message to the file
    await logFile.writeAsString(logMessage, mode: FileMode.append);
  });
}

String _getCallerSourceCodeFilename() {
  StackTrace stackTrace = StackTrace.current;
  String stackTraceString = stackTrace.toString();
  String fileName = "";
  String lineNumber = "";
  List<String> stackLines = stackTraceString.split('\n');
  if (stackLines.length > 2) {
    String callerInfo = stackLines[2];
    List<String> parts = callerInfo.split('/');
    fileName = parts.last.split(':').first; // Extract the file name
    lineNumber = parts.last.split(':')[1]; // Extract the line number
  } else {
    String firstLine = stackTraceString.split('\n')[0];
    fileName =
        firstLine.split('/').last.split(':').first; // Extract the file name
    lineNumber = firstLine.split(':')[1]; // Extract the line number
  }
  return '$fileName:$lineNumber';
}
