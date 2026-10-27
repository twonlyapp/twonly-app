import 'dart:async';

import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/bridge/wrapper/app_database.dart';
import 'package:twonly/src/services/performance_tracking.service.dart';
import 'package:twonly/src/utils/log.dart';

Stream<List<String>> watchRustDatabaseChanges() =>
    watchRustDatabase((control) => RustAppDatabase.changes(control: control));

Stream<T> watchRustDatabase<T>(Stream<T> Function(DatabaseWatch) create) {
  DatabaseWatch? control;
  StreamSubscription<T>? subscription;
  late final StreamController<T> controller;
  controller = StreamController<T>(
    onListen: () {
      try {
        control = DatabaseWatch();
        PerformanceTracking.attachToWatch(control!);
        subscription = create(control!).listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      } catch (error, stackTrace) {
        controller.addError(error, stackTrace);
        unawaited(controller.close());
      }
    },
    onPause: () => subscription?.pause(),
    onResume: () => subscription?.resume(),
    onCancel: () async {
      control?.cancel();
      try {
        await subscription?.cancel();
      } finally {
        control?.dispose();
      }
    },
  );
  return controller.stream;
}

Stream<T> restartDatabaseWatch<T>(
  Stream<T> Function() create,
  Stream<void> invalidations,
) {
  StreamSubscription<T>? active;
  StreamSubscription<void>? triggers;
  var stopped = false;
  var pending = Future<void>.value();
  late final StreamController<T> controller;
  void restart() {
    pending = pending
        .then((_) async {
          await active?.cancel();
          if (stopped) return;
          active = create().listen(
            controller.add,
            onError: controller.addError,
          );
          if (controller.isPaused) active!.pause();
        })
        .catchError((Object error, StackTrace stack) {
          if (!stopped) controller.addError(error, stack);
        });
  }

  controller = StreamController<T>(
    onListen: () {
      triggers = invalidations.listen(
        (_) => restart(),
        onError: controller.addError,
      );
      restart();
    },
    onPause: () => active?.pause(),
    onResume: () => active?.resume(),
    onCancel: () async {
      stopped = true;
      await triggers?.cancel();
      await pending;
      await active?.cancel();
    },
  );
  return controller.stream;
}

void refreshDatabaseSubscriptions() =>
    unawaited(_refreshDatabaseSubscriptions());
Future<void> _refreshDatabaseSubscriptions() async {
  try {
    await refreshDatabaseWatches();
  } catch (error) {
    Log.warn('Could not refresh database watches: $error');
  }
}
