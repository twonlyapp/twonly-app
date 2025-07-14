import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/utils/log.dart';

class KeyValueStore {
  static Future<String> _getFilePath(String key) async {
    final directory = await getApplicationSupportDirectory();
    return '${directory.path}/keyvalue/$key.json';
  }

  static Future<Map<String, dynamic>?> get(String key) async {
    try {
      final filePath = await _getFilePath(key);
      final file = File(filePath);

      // Check if the file exists
      if (file.existsSync()) {
        final contents = await file.readAsString();
        return jsonDecode(contents) as Map<String, dynamic>;
      } else {
        return null; // File does not exist
      }
    } catch (e) {
      Log.error('Error reading file: $e');
      return null;
    }
  }

  static Future<void> put(String key, Map<String, dynamic> value) async {
    try {
      final filePath = await _getFilePath(key);
      final file = File(filePath);

      // Create the directory if it doesn't exist
      await file.parent.create(recursive: true);

      // Write the JSON data to the file
      await file.writeAsString(jsonEncode(value));
    } catch (e) {
      Log.error('Error writing file: $e');
    }
  }
}
