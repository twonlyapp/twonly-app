import 'dart:convert';
import 'dart:io';

import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/exclusive_access.utils.dart';
import 'package:twonly/src/utils/log.dart';

class KeyValueStore {
  static final Mutex _mutex = Mutex();

  static Future<File> _getFilePath(String key) async {
    return File('${AppEnvironment.supportDir}/keyvalue/$key.json');
  }

  static Future<T> _exclusive<T>(String key, Future<T> Function() action) {
    return exclusiveAccess(
      lockName: 'keyvalue-$key',
      mutex: _mutex,
      action: action,
    );
  }

  static Future<void> delete(String key) => _exclusive(key, () async {
    try {
      final file = await _getFilePath(key);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      Log.error('Error deleting file: $e');
    }
  });

  static Future<Map<String, dynamic>?> get(String key) =>
      _exclusive(key, () async {
        final file = await _getFilePath(key);
        try {
          if (file.existsSync()) {
            final contents = await file.readAsString();
            return jsonDecode(contents) as Map<String, dynamic>;
          } else {
            return null;
          }
        } catch (e) {
          Log.warn('Error reading file. Deleting it.: $e');
          file.deleteSync();
          return null;
        }
      });

  static Future<void> put(String key, Map<String, dynamic> value) =>
      _exclusive(key, () async {
        try {
          final file = await _getFilePath(key);
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(value));
        } catch (e) {
          Log.error('Error writing file: $e');
        }
      });
}
