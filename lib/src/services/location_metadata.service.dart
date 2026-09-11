import 'package:flutter/services.dart';

class LocationMetadataService {
  static const _channel = MethodChannel('eu.twonly/location_metadata');

  /// Opens the native permission sheet only after the user enables the switch.
  /// Approximate/reduced access is rejected because this feature promises a
  /// precise capture location.
  static Future<bool> requestPrecisePermission() async {
    return await _channel.invokeMethod<bool>('requestPrecisePermission') ??
        false;
  }
}
