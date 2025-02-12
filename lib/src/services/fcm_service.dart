import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:twonly/src/providers/db_provider.dart';
import 'package:twonly/src/utils/misc.dart';

import '../../firebase_options.dart';

// see more here: https://firebase.google.com/docs/cloud-messaging/flutter/receive?hl=de

Future initFCMAfterAuthenticated() async {
  if (globalIsAppInBackground) return;

  final storage = getSecureStorage();

  String? storedToken = await storage.read(key: "google_fcm");

  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken == null) {
    Logger("init_fcm_service").shout("Error getting fcmToken");
    return;
  }

  if (storedToken == null || fcmToken != storedToken) {
    await apiProvider.updateFCMToken(fcmToken);
    await storage.write(key: "google_fcm", value: fcmToken);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
    await apiProvider.updateFCMToken(fcmToken);
    await storage.write(key: "google_fcm", value: fcmToken);
  }).onError((err) {
    // Logger("init_fcm_service").shout("Error getting fcmToken");
  });
}

Future initFCMService() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // You may set the permission requests to "provisional" which allows the user to choose what type
  // of notifications they would like to receive once the user receives a notification.
  // final notificationSettings =
  await FirebaseMessaging.instance.requestPermission(provisional: true);

  // For apple platforms, ensure the APNS token is available before making any FCM plugin API calls
  // final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
  // if (apnsToken != null) {
  // APNS token is available, make FCM plugin API requests...
  // }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.

  // Wenn Tasks länger als 30 Sekunden ausgeführt werden, wird der Prozess möglicherweise automatisch vom Gerät beendet.
  // -> offer backend via http?

  print("Handling a background message: ${message.messageId}");

  bool gotMessage = false;

  globalCallBackOnMessageChange = (a, b) async {
    gotMessage = true;
    print("Got message can exit");
  };

  dbProvider = DbProvider();
  await dbProvider.ready;
  apiProvider = ApiProvider();
  await apiProvider.connect();

  final stopwatch = Stopwatch()..start();
  while (!gotMessage) {
    if (stopwatch.elapsed >= Duration(seconds: 20)) {
      Logger("firebase-background").shout('Timeout reached. Exiting the loop.');
      break; // Exit the loop if the timeout is reached.
    }
    await Future.delayed(Duration(milliseconds: 10));
  }
  await apiProvider.close(() {});
}
