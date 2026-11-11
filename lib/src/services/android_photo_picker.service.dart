import 'package:flutter/services.dart';

class AndroidPhotoPickerService {
  static const MethodChannel _channel = MethodChannel('eu.twonly/photo_picker');

  /// Launches the native Android Photo Picker and returns a list of URIs.
  static Future<List<String>> pickImages() async {
    try {
      final result = await _channel.invokeListMethod<String>('pickImages');
      return result ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Copies the content behind [uri] to [path] on a native background thread,
  /// so several picks can be copied at once without blocking the UI.
  static Future<bool> copyUriToFile(String uri, String path) async {
    try {
      final copied = await _channel.invokeMethod<bool>('copyUriToFile', {
        'uri': uri,
        'path': path,
      });
      return copied ?? false;
    } catch (e) {
      return false;
    }
  }
}
