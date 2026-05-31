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

  /// Reads the raw bytes from a content URI using the Android ContentResolver.
  static Future<Uint8List?> getUriBytes(String uri) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('getUriBytes', {'uri': uri});
      return bytes;
    } catch (e) {
      return null;
    }
  }
}
