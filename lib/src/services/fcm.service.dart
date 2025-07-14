import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/utils/log.dart';

import '../../firebase_options.dart';

// see more here: https://firebase.google.com/docs/cloud-messaging/flutter/receive?hl=de

Future<void> initFCMAfterAuthenticated() async {
  if (globalIsAppInBackground) return;

  const storage = FlutterSecureStorage();

  final storedToken = await storage.read(key: SecureStorageKeys.googleFcm);

  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      Log.error('Error getting fcmToken');
      return;
    }

    if (storedToken == null || fcmToken != storedToken) {
      await apiService.updateFCMToken(fcmToken);
      await storage.write(key: SecureStorageKeys.googleFcm, value: fcmToken);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await apiService.updateFCMToken(fcmToken);
      await storage.write(key: SecureStorageKeys.googleFcm, value: fcmToken);
    }).onError((err) {
      Log.error('could not listen on token refresh');
    });
  } catch (e) {
    Log.error('could not load fcm token: $e');
  }
}

Future<void> initFCMService() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // You may set the permission requests to "provisional" which allows the user to choose what type
  // of notifications they would like to receive once the user receives a notification.
  // final notificationSettings =
  // await FirebaseMessaging.instance.requestPermission(provisional: true);
  await FirebaseMessaging.instance.requestPermission();

  // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
  if (Platform.isIOS) {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken == null) {
      return;
    }
  }

  FirebaseMessaging.onMessage.listen(handleRemoteMessage);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  initLogger();
  Log.info('Handling a background message: ${message.messageId}');
  await handleRemoteMessage(message);
  // make sure every thing run...
  await Future.delayed(const Duration(milliseconds: 2000));
}

Future<void> handleRemoteMessage(RemoteMessage message) async {
  if (!Platform.isAndroid) {
    Log.error('Got message in Dart while on iOS');
  }

  if (message.notification != null) {
    final title = message.notification!.title ?? '';
    final body = message.notification!.body ?? '';
    await customLocalPushNotification(title, body);
  } else if (message.data['push_data'] != null) {
    await handlePushData(message.data['push_data'] as String);
  }
}
