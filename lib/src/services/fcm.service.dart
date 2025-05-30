import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/app.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/notification.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'dart:io' show Platform;
import '../../firebase_options.dart';

// see more here: https://firebase.google.com/docs/cloud-messaging/flutter/receive?hl=de

Future initFCMAfterAuthenticated() async {
  if (globalIsAppInBackground) return;

  final storage = FlutterSecureStorage();

  String? storedToken = await storage.read(key: "google_fcm");

  try {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) {
      Logger("init_fcm_service").shout("Error getting fcmToken");
      return;
    }

    if (storedToken == null || fcmToken != storedToken) {
      await apiService.updateFCMToken(fcmToken);
      await storage.write(key: "google_fcm", value: fcmToken);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
      await apiService.updateFCMToken(fcmToken);
      await storage.write(key: "google_fcm", value: fcmToken);
    }).onError((err) {
      // Logger("init_fcm_service").shout("Error getting fcmToken");
    });
  } catch (e) {
    Logger("fcm_service").shout("Error loading fcmToken: $e");
  }
}

Future initFCMService() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // You may set the permission requests to "provisional" which allows the user to choose what type
  // of notifications they would like to receive once the user receives a notification.
  // final notificationSettings =
  // await FirebaseMessaging.instance.requestPermission(provisional: true);
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
  if (Platform.isIOS) {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken == null) {
      return;
    }
  }

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    handleRemoteMessage(message);
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  initLogger();
  Logger("firebase-background")
      .info('Handling a background message: ${message.messageId}');
  twonlyDB = TwonlyDatabase();
  await handleRemoteMessage(message);

  // make sure every thing run...
  await Future.delayed(Duration(milliseconds: 2000));
}

Future handleRemoteMessage(RemoteMessage message) async {
  if (!Platform.isAndroid) {
    Logger("firebase-notification").shout("Got message in Dart while on iOS");
  }

  if (message.notification != null) {
    String title = message.notification!.title ?? "";
    String body = message.notification!.body ?? "";
    await customLocalPushNotification(title, body);
  } else if (message.data["push_data"] != null) {
    await handlePushData(message.data["push_data"]);
  }
}
