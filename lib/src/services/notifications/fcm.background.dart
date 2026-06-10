import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/background/callback_dispatcher.background.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/notifications/setup.notifications.dart';
import 'package:twonly/src/utils/log.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  SentryWidgetsFlutterBinding.ensureInitialized();
  await AppEnvironment.init();
  final isInitialized = await initBackgroundExecution();
  await setupPushNotification();
  Log.info('Handling a background message: ${message.messageId}');
  await FcmNotificationService.handleRemoteMessage(message);

  if (Platform.isAndroid) {
    if (isInitialized) {
      await handlePeriodicTask(lastExecutionInSecondsLimit: 10);
    }
  } else {
    // make sure every thing run...
    await Future.delayed(const Duration(milliseconds: 2000));
  }
}
