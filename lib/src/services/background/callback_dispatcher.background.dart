import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api.service.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:workmanager/workmanager.dart';

// ignore: unreachable_from_main
Future<void> initializeBackgroundTaskManager() async {
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    'fetch_data_from_server',
    'eu.twonly.periodic_task',
    frequency: const Duration(minutes: 20),
    initialDelay: const Duration(minutes: 5),
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

Future<bool> initBackgroundExecution() async {
  SentryWidgetsFlutterBinding.ensureInitialized();
  initLogger();

  final user = await getUser();
  if (user == null) return false;
  gUser = user;

  globalApplicationCacheDirectory = (await getApplicationCacheDirectory()).path;
  globalApplicationSupportDirectory =
      (await getApplicationSupportDirectory()).path;

  twonlyDB = TwonlyDB();
  apiService = ApiService();
  globalIsInBackgroundTask = true;

  return true;
}

Future<bool> handlePeriodicTask() async {
  final lastExecution =
      await KeyValueStore.get(KeyValueKeys.lastPeriodicTaskExecution);
  if (lastExecution == null || !lastExecution.containsKey('timestamp')) {
    final lastExecutionTime = lastExecution?['timestamp'] as int?;
    if (lastExecutionTime != null) {
      final lastExecution =
          DateTime.fromMillisecondsSinceEpoch(lastExecutionTime);
      if (DateTime.now().difference(lastExecution).inMinutes < 2) {
        Log.info(
          'eu.twonly.periodic_task not executed as last execution was within the last two minutes.',
        );
        return true;
      }
    }
  }

  await KeyValueStore.put(KeyValueKeys.lastPeriodicTaskExecution, {
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  });

  Log.info('eu.twonly.periodic_task was called.');

  final stopwatch = Stopwatch()..start();

  if (!await apiService.connect()) {
    Log.info('Could not connect to the api. Returning early.');
    return false;
  }

  if (!apiService.isAuthenticated) {
    Log.info('Api is not authenticated. Returning early.');
    return false;
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
  return true;
}

Future<void> handleProcessingTask() async {
  Log.info('eu.twonly.processing_task was called.');
  final stopwatch = Stopwatch()..start();
  await finishStartedPreprocessing();
  Log.info('eu.twonly.processing_task finished after ${stopwatch.elapsed}.');
}
