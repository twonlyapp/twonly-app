import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/utils/log.dart';

class KeyValueStore {
  static Future<File> _getFilePath(String key) async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}/keyvalue/$key.json');
  }

  static Future<void> delete(String key) async {
    try {
      final file = await _getFilePath(key);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      Log.error('Error deleting file: $e');
    }
  }

  static Future<Map<String, dynamic>?> get(String key) async {
    try {
      final file = await _getFilePath(key);
      if (file.existsSync()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      Log.warn('Error reading file: $e');
      return null;
    }
  }

  static Future<void> put(String key, Map<String, dynamic> value) async {
    try {
      final file = await _getFilePath(key);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(value));
    } catch (e) {
      Log.error('Error writing file: $e');
    }
  }
}
