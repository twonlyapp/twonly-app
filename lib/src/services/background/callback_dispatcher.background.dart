import 'dart:async';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/utils/exclusive_access.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:workmanager/workmanager.dart';

// ignore: unreachable_from_main
Future<void> initializeBackgroundTaskManager() async {
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().cancelByUniqueName('fetch_data_from_server');

  await Workmanager().registerPeriodicTask(
    'fetch_data_from_server',
    'eu.twonly.periodic_task',
    frequency: const Duration(minutes: 20),
    initialDelay: const Duration(minutes: 5),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'eu.twonly.periodic_task':
        if (await initBackgroundExecution()) {
          await handlePeriodicTask();
        }
      case 'eu.twonly.processing_task':
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
  if (_isInitialized) {
    // Reload the users, as on Android the background isolate can
    // stay alive for multiple hours between task executions
    final user = await getUser();
    if (user == null) return false;
    gUser = user;
    return true;
  }

  SentryWidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.cacheDir = (await getApplicationCacheDirectory()).path;
  AppEnvironment.supportDir = (await getApplicationSupportDirectory()).path;

  initLogger();

  final user = await getUser();
  if (user == null) return false;
  gUser = user;

  twonlyDB = TwonlyDB();
  apiService = ApiService();
  globalIsInBackgroundTask = true;

  _isInitialized = true;
  return true;
}

final Mutex _keyValueMutex = Mutex();

Future<void> handlePeriodicTask({int lastExecutionInSecondsLimit = 120}) async {
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

  if (!shouldBeExecuted) return;

  Log.info('eu.twonly.periodic_task was called.');

  final stopwatch = Stopwatch()..start();

  if (!await apiService.connect()) {
    Log.info('Could not connect to the api. Returning early.');
    return;
  }

  if (!apiService.isAuthenticated) {
    Log.info('Api is not authenticated. Returning early.');
    return;
  }

  while (!globalGotMessageFromServer) {
    if (stopwatch.elapsed.inSeconds >= 15) {
      Log.info('No new message from the server after 15 seconds.');
      break;
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  if (globalGotMessageFromServer) {
    Log.info('Received a server message from the server.');
  }

  await finishStartedPreprocessing();

  await Future.delayed(const Duration(milliseconds: 2000));

  await apiService.close(() {});
  stopwatch.stop();

  Log.info('eu.twonly.periodic_task finished after ${stopwatch.elapsed}.');
  return;
}

Future<void> handleProcessingTask() async {
  Log.info('eu.twonly.processing_task was called.');
  final stopwatch = Stopwatch()..start();
  await finishStartedPreprocessing();
  Log.info('eu.twonly.processing_task finished after ${stopwatch.elapsed}.');
}
