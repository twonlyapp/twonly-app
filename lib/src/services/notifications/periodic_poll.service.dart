import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PeriodicPollStatus {
  const PeriodicPollStatus({
    required this.hasPlayServices,
    required this.enabled,
    required this.intervalMinutes,
    required this.ignoringBatteryOptimizations,
    required this.backgroundRestricted,
  });

  factory PeriodicPollStatus.fromMap(Map<String, dynamic> value) =>
      PeriodicPollStatus(
        hasPlayServices: value['hasPlayServices'] as bool,
        enabled: value['enabled'] as bool,
        intervalMinutes: value['intervalMinutes'] as int,
        ignoringBatteryOptimizations:
            value['ignoringBatteryOptimizations'] as bool,
        backgroundRestricted: value['backgroundRestricted'] as bool,
      );

  final bool hasPlayServices;
  final bool enabled;
  final int intervalMinutes;
  final bool ignoringBatteryOptimizations;
  final bool backgroundRestricted;

  // Keep the off switch accessible if Google services are installed later.
  bool get showSettings => !hasPlayServices || enabled;
}

class PeriodicPollService {
  static const _channel = MethodChannel('eu.twonly/periodic_poll');
  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<PeriodicPollStatus?> getStatus() async {
    if (!_supported) return null;
    final value = await _channel.invokeMapMethod<String, dynamic>('getStatus');
    return value == null ? null : PeriodicPollStatus.fromMap(value);
  }

  static Future<PeriodicPollStatus?> setEnabled(bool enabled) async {
    if (!_supported) return null;
    final value = await _channel.invokeMapMethod<String, dynamic>(
      'setEnabled',
      enabled,
    );
    return value == null ? null : PeriodicPollStatus.fromMap(value);
  }

  static Future<void> openBatterySettings() async {
    if (_supported) await _channel.invokeMethod<void>('openBatterySettings');
  }
}
