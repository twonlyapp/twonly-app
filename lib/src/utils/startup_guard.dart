import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/utils/log.dart';

class StartupGuard {
  static Future<File> _getLockFile() async {
    final path = (await getApplicationCacheDirectory()).path;
    return File('$path/app_startup.lock');
  }

  static Future<void> markAppStartup() async {
    try {
      final file = await _getLockFile();
      await file.writeAsString(
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      Log.info('App is starting');
    } catch (e) {
      Log.error('Failed to mark app startup: $e');
    }
  }

  static Future<bool> isAppStarting() async {
    try {
      final file = await _getLockFile();
      if (!file.existsSync()) return false;

      final stat = file.statSync();
      final diff = DateTime.now().difference(stat.modified);

      final starting = diff.inSeconds < 30;
      if (starting) {
        Log.info(
          'Startup guard: App is currently starting (${diff.inSeconds}s ago).',
        );
      }
      return starting;
    } catch (e) {
      Log.error('Failed to check startup guard: $e');
      return false;
    }
  }
}
