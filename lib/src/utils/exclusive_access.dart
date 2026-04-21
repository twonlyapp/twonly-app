import 'dart:async';
import 'dart:io';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';

Future<T> exclusiveAccess<T>({
  required String lockName,
  required Future<T> Function() action,
  required Mutex mutex,
}) async {
  final lockFile = File('${AppEnvironment.supportDir}/$lockName.lock');
  return mutex.protect(() async {
    var lockAcquired = false;

    while (!lockAcquired) {
      try {
        lockFile.createSync(exclusive: true);
        lockAcquired = true;
      } on FileSystemException catch (e) {
        final isExists = e is PathExistsException || e.osError?.errorCode == 17;
        if (!isExists) {
          break;
        }
        try {
          final stat = lockFile.statSync();
          if (stat.type != FileSystemEntityType.notFound) {
            final age = DateTime.now().difference(stat.modified).inMilliseconds;
            if (age > 1000) {
              lockFile.deleteSync();
              continue;
            }
          }
        } catch (_) {}
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (_) {
        break;
      }
    }
    try {
      return await action();
    } finally {
      if (lockAcquired) {
        try {
          if (lockFile.existsSync()) {
            lockFile.deleteSync();
          }
        } catch (_) {}
      }
    }
  });
}
