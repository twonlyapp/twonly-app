import 'package:flutter/services.dart';

enum NativeBackupScheduleState { scheduled, running, notScheduled, unavailable }

class NativeBackupSchedule {
  const NativeBackupSchedule({
    required this.state,
    this.earliestStart,
    this.executionAllowed = true,
  });

  final NativeBackupScheduleState state;
  final DateTime? earliestStart;
  final bool executionAllowed;
}

class NativeBackupScheduler {
  static const _channel = MethodChannel('eu.twonly/backup_schedule');

  /// Query the OS reservation, rather than estimating from the last upload.
  static Future<NativeBackupSchedule> getSchedule() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getSchedule',
      );
      final state = switch (result?['state']) {
        'scheduled' => NativeBackupScheduleState.scheduled,
        'running' => NativeBackupScheduleState.running,
        'notScheduled' => NativeBackupScheduleState.notScheduled,
        _ => NativeBackupScheduleState.unavailable,
      };
      final millis = result?['earliestStartMillis'] as int?;
      return NativeBackupSchedule(
        state: state,
        executionAllowed: result?['executionAllowed'] as bool? ?? true,
        earliestStart: millis == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                millis,
                isUtc: true,
              ).toLocal(),
      );
    } on PlatformException catch (_) {
      return const NativeBackupSchedule(
        state: NativeBackupScheduleState.unavailable,
      );
    } on MissingPluginException catch (_) {
      return const NativeBackupSchedule(
        state: NativeBackupScheduleState.unavailable,
      );
    }
  }
}
