import 'dart:async';

import 'package:mutex/mutex.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/utils/exclusive_access.utils.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/startup_guard.dart';
import 'package:workmanager/workmanager.dart';

// ignore: unreachable_from_main
Future<void> initializeBackgroundTaskManager() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().cancelByUniqueName('fetch_data_from_server');

  // await Workmanager().registerPeriodicTask(
  //   'fetch_data_from_server',
  //   'eu.twonly.periodic_task',
  //   frequency: const Duration(minutes: 20),
  //   initialDelay: const Duration(minutes: 5),
  //   existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  //   constraints: Constraints(
  //     networkType: NetworkType.connected,
  //   ),
  // );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    SentryWidgetsFlutterBinding.ensureInitialized();
    await AppEnvironment.init();
    switch (task) {
      case 'eu.twonly.periodic_task':
        // if (await initBackgroundExecution()) {
        //   await handlePeriodicTask();
        // }
        break;
      case 'eu.twonly.processing_task':
      case _ when task.startsWith('progressing_finish_uploads_'):
        if (await initBackgroundExecution()) {
          await handleProcessingTask();
        }
      default:
        Log.error('Unknown task was executed: $task');
    }
    return Future.value(true);
  });
}

bool _isInitialized = false;

Future<bool> initBackgroundExecution() async {
  // 1. Check startup guard IMMEDIATELY before doing ANYTHING else.
  if (await StartupGuard.isAppStarting()) {
    return false;
  }

  AppState.isInBackgroundTask = true;

  if (await StartupGuard.isAppStarting()) {
    Log.error('App is starting. Returning early.');
    return false;
  }
  if (_isInitialized) {
    // Reload the users, as on Android the background isolate can
    // stay alive for multiple hours between task executions
    return userService.tryInit();
  }

  await twonlyMinimumInitialization();

  if (!await userService.tryInit()) {
    Log.info('Early return as user is not registered yet.');
    return false;
  }

  Log.info('Background task is initialized');

  _isInitialized = true;
  return true;
}

final Mutex _keyValueMutex = Mutex();

// ignore: unreachable_from_main
Future<bool> backgroundFetch({
  int? lastExecutionInSecondsLimit = 120,
}) async {
  if (lastExecutionInSecondsLimit != null) {
    final shouldBeExecuted = await exclusiveAccess(
      lockName: 'periodic_task',
      mutex: _keyValueMutex,
      action: () async {
        final lastExecution = await KeyValueStore.get(
          KeyValueKeys.lastPeriodicTaskExecution,
        );
        if (lastExecution != null && lastExecution.containsKey('timestamp')) {
          final lastExecutionTime = lastExecution['timestamp'] as int?;
          if (lastExecutionTime != null) {
            final lastExecutionDate = DateTime.fromMillisecondsSinceEpoch(
              lastExecutionTime,
            );
            if (DateTime.now().difference(lastExecutionDate).inSeconds <
                lastExecutionInSecondsLimit) {
              return false;
            }
          }
        }
        await KeyValueStore.put(KeyValueKeys.lastPeriodicTaskExecution, {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        return true;
      },
    );

    if (!shouldBeExecuted) return false;
  }

  Log.info('Periodic task was called.');
  AppState.gotMessageFromServer = false;

  final stopwatch = Stopwatch()..start();

  var authenticated = false;
  for (var attempt = 0; attempt < 100; attempt++) {
    final state = await RustApi.connectionState();
    if (state == ApiConnectionState.authenticated) {
      authenticated = true;
      break;
    }
    if (state == ApiConnectionState.permanentlyRejected ||
        state == ApiConnectionState.suspended) {
      break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  if (!authenticated) {
    Log.info('Api is not authenticated. Returning early.');
    return false;
  }

  var receiveMessage = false;

  try {
    while (!AppState.gotMessageFromServer) {
      if (stopwatch.elapsed.inSeconds >= 15) {
        Log.info('No new message from the server after 15 seconds.');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (AppState.gotMessageFromServer) {
      receiveMessage = true;
      Log.info('Received a server message from the server.');
    }

    await finishStartedPreprocessing();

    if (lastExecutionInSecondsLimit != null) {
      await Future.delayed(const Duration(milliseconds: 2000));
    }
  } finally {
    await RustApi.close();
    stopwatch.stop();
  }

  Log.info('Periodic task finished after ${stopwatch.elapsed}.');
  return receiveMessage;
}

Future<void> handleProcessingTask() async {
  Log.info('eu.twonly.processing_task was called.');
  final stopwatch = Stopwatch()..start();
  await finishStartedPreprocessing();
  Log.info('eu.twonly.processing_task finished after ${stopwatch.elapsed}.');
}
