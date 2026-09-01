import 'dart:async';
import 'dart:io';
import 'package:mutex/mutex.dart';
import 'package:twonly/globals.dart';

/// A lock file whose timestamp has not moved for this long is assumed to belong
/// to a process that is gone. The holder refreshes it while it works, so this
/// only ever breaks an abandoned lock — never a slow one.
const _staleAfter = Duration(seconds: 3);

/// How often the holder proves it is still alive.
const _heartbeat = Duration(seconds: 1);

Future<T> exclusiveAccess<T>({
  required String lockName,
  required Future<T> Function() action,
  required Mutex mutex,
}) async {
  final lockFile = File('${AppEnvironment.cacheDir}/$lockName.lock');
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
            // A process killed mid-initialization leaves its lock behind. The
            // holder keeps the timestamp fresh, so a stale one means nobody is
            // working on it any more. Everything the lock guards is idempotent
            // by itself, so breaking an abandoned lock is safe.
            if (DateTime.now().difference(stat.modified) > _staleAfter) {
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

    // Keep the lock visibly alive for as long as the work takes. Without this,
    // an initialization slower than `_staleAfter` — the legacy database import,
    // for one — would have its lock broken by the next waiter.
    Timer? keepAlive;
    if (lockAcquired) {
      keepAlive = Timer.periodic(_heartbeat, (_) {
        try {
          lockFile.setLastModifiedSync(DateTime.now());
        } catch (_) {}
      });
    }

    try {
      return await action();
    } finally {
      keepAlive?.cancel();
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
