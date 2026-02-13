// ignore_for_file: unreachable_from_main

import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

import '../../firebase_options.dart';

// see more here: https://firebase.google.com/docs/cloud-messaging/flutter/receive?hl=de

Future<void> checkForTokenUpdates() async {
  const storage = FlutterSecureStorage();

  final storedToken = await storage.read(key: SecureStorageKeys.googleFcm);

  try {
    if (Platform.isIOS) {
      var apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      for (var i = 0; i < 20; i++) {
        if (apnsToken != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      }
      if (apnsToken == null) {
        Log.error('Could not get APNS token even after 20s...');
        return;
      }
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      Log.error('Could not get fcm token');
      return;
    }
    Log.info('Loaded fcm token');
    if (storedToken == null || fcmToken != storedToken) {
      await updateUserdata((u) {
        u.updateFCMToken = true;
        return u;
      });
      await storage.write(key: SecureStorageKeys.googleFcm, value: fcmToken);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await updateUserdata((u) {
        u.updateFCMToken = true;
        return u;
      });
      await storage.write(key: SecureStorageKeys.googleFcm, value: fcmToken);
    }).onError((err) {
      Log.error('could not listen on token refresh');
    });
  } catch (e) {
    Log.error('could not load fcm token: $e');
  }
}

Future<void> initFCMAfterAuthenticated() async {
  if (gUser.updateFCMToken) {
    const storage = FlutterSecureStorage();
    final storedToken = await storage.read(key: SecureStorageKeys.googleFcm);
    if (storedToken != null) {
      final res = await apiService.updateFCMToken(storedToken);
      if (res.isSuccess) {
        Log.info('Uploaded new fmt token!');
        await updateUserdata((u) {
          u.updateFCMToken = false;
          return u;
        });
      }
    }
  }
}

Future<void> initFCMService() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  unawaited(checkForTokenUpdates());

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // You may set the permission requests to "provisional" which allows the user to choose what type
  // of notifications they would like to receive once the user receives a notification.
  // final notificationSettings =
  // await FirebaseMessaging.instance.requestPermission(provisional: true);
  await FirebaseMessaging.instance.requestPermission();

  // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
  // if (Platform.isIOS) {
  //   final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  //   if (apnsToken == null) {
  //     return;
  //   }
  // }

  FirebaseMessaging.onMessage.listen(handleRemoteMessage);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  initLogger();
  // Log.info('Handling a background message: ${message.messageId}');
  await handleRemoteMessage(message);
  // make sure every thing run...
  await Future.delayed(const Duration(milliseconds: 2000));
}

Future<void> handleRemoteMessage(RemoteMessage message) async {
  if (!Platform.isAndroid) {
    Log.error('Got message in Dart while on iOS');
  }
  if (message.notification != null && globalIsAppInBackground) {
    Log.error(
      'Got notification but app is in background, so the SDK already have shown the message.',
    );
    return;
  }

  if (message.notification != null || message.data['title'] != null) {
    final title =
        message.notification?.title ?? message.data['title'] as String? ?? '';
    final body =
        message.notification?.body ?? message.data['body'] as String? ?? '';
    await customLocalPushNotification(title, body);
  } else if (message.data['push_data'] != null) {
    await handlePushData(message.data['push_data'] as String);
  }
}
