import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/services/notifications/fcm.background.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

import '../../../firebase_options.dart';

// see more here: https://firebase.google.com/docs/cloud-messaging/flutter/receive?hl=de

class FcmNotificationService {
  static Future<void> initStartup() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(handleRemoteMessage);
  }

  static Future<void> initAfterUserLoaded() async {
    unawaited(_checkForTokenUpdates());
    unawaited(_checkFcmHealthAndResetIfNeeded());
  }

  static Future<void> initFCMAfterAuthenticated({bool force = false}) async {
    final fcmToken = userService.currentUser.fcmToken;
    if (userService.currentUser.updateFCMToken || force) {
      if (fcmToken == null) {
        Log.error('FCM token could not be updated as it is empty');
        await _checkForTokenUpdates();
        return;
      }
      final res = await apiService.updateFCMToken(
        fcmToken,
      );
      if (res.isSuccess) {
        Log.info('Uploaded new FCM token!');
        await UserService.update((u) {
          u.updateFCMToken = false;
        });
      } else {
        Log.error('Could not update FCM token!');
      }
    }
  }

  static Future<void> resetFCMTokens() async {
    await FirebaseInstallations.instance.delete();
    Log.info('Firebase Installation successfully deleted.');
    await FirebaseMessaging.instance.deleteToken();
    Log.info('Old FCM deleted.');
    await UserService.update((u) => u.fcmToken = null);
    await _checkForTokenUpdates();
    await initFCMAfterAuthenticated(force: true);
  }

  static Future<void> _checkForTokenUpdates() async {
    try {
      if (!userService.isUserCreated) {
        Log.info(
          'Checking for FCM token updates skipped: user is not yet created.',
        );
        return;
      }
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

      Log.info('Loaded FCM token.');

      if (userService.currentUser.fcmToken == null ||
          fcmToken != userService.currentUser.fcmToken) {
        Log.info('Got new FCM token.');
        await UserService.update((u) {
          u
            ..updateFCMToken = true
            ..fcmToken = fcmToken;
        });
        if (apiService.isAuthenticated) {
          final res = await apiService.updateFCMToken(fcmToken);
          if (res.isSuccess) {
            Log.info('Uploaded new FCM token!');
            await UserService.update((u) {
              u.updateFCMToken = false;
            });
          } else {
            Log.error('Could not update FCM token!');
          }
        }
      }

      FirebaseMessaging.instance.onTokenRefresh
          // ignore: avoid_types_on_closure_parameters
          .listen((String fcmToken) async {
            await UserService.update((u) {
              u
                ..updateFCMToken = true
                ..fcmToken = fcmToken;
            });
            if (apiService.isAuthenticated) {
              final res = await apiService.updateFCMToken(fcmToken);
              if (res.isSuccess) {
                Log.info('Uploaded new FCM token!');
                await UserService.update((u) {
                  u.updateFCMToken = false;
                });
              } else {
                Log.error('Could not update FCM token!');
              }
            }
          })
          .onError((err) {
            Log.error('could not listen on token refresh');
          });
    } catch (e) {
      Log.error('could not load fcm token: $e');
    }
  }

  static Future<void> handleRemoteMessage(RemoteMessage message) async {
    await _updateLastFcmMessageTimestamp();
    if (!Platform.isAndroid) {
      Log.error('Got message in Dart while on iOS');
    }
    if (message.notification != null && AppState.isAppInBackground) {
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
    }
  }

  static Future<void> _updateLastFcmMessageTimestamp() async {
    const storage = FlutterSecureStorage();
    final nowMs = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await storage.write(
        key: SecureStorageKeys.lastFcmMessageTimestamp,
        value: nowMs,
        iOptions: const IOSOptions(
          groupId: 'CN332ZUGRP.eu.twonly.shared',
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      Log.info('Updated last FCM message timestamp to $nowMs');
    } catch (e) {
      Log.error('Could not write last FCM message timestamp: $e');
    }
  }

  static Future<void> updateLastServerMessageTimestamp() async {
    const storage = FlutterSecureStorage();
    final nowMs = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      await storage.write(
        key: SecureStorageKeys.lastServerMessageTimestamp,
        value: nowMs,
        iOptions: const IOSOptions(
          groupId: 'CN332ZUGRP.eu.twonly.shared',
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      Log.info('Updated last server message timestamp to $nowMs');
    } catch (e) {
      Log.error('Could not write last server message timestamp: $e');
    }
  }

  static Future<void> _checkFcmHealthAndResetIfNeeded() async {
    if (!userService.isUserCreated) {
      Log.info('FCM health check skipped: user is not yet created.');
      return;
    }
    const storage = FlutterSecureStorage();
    try {
      final lastFcmStr = await storage.read(
        key: SecureStorageKeys.lastFcmMessageTimestamp,
        iOptions: const IOSOptions(
          groupId: 'CN332ZUGRP.eu.twonly.shared',
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );
      final lastServerStr = await storage.read(
        key: SecureStorageKeys.lastServerMessageTimestamp,
        iOptions: const IOSOptions(
          groupId: 'CN332ZUGRP.eu.twonly.shared',
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      DateTime? lastFcmTime;
      if (lastFcmStr != null) {
        final ms = int.tryParse(lastFcmStr);
        if (ms != null) {
          lastFcmTime = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }

      if (lastFcmTime != null) {
        Log.info(
          'Last message received via FCM messaging system: $lastFcmTime',
        );
      } else {
        Log.info('No record of a message received via FCM messaging system.');
      }

      DateTime? lastServerTime;
      if (lastServerStr != null) {
        final ms = int.tryParse(lastServerStr);
        if (ms != null) {
          lastServerTime = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }

      final fcmInactive =
          lastFcmTime == null || lastFcmTime.isBefore(threeDaysAgo);
      final serverActive =
          lastServerTime != null && lastServerTime.isAfter(threeDaysAgo);

      if (fcmInactive && serverActive) {
        Log.warn(
          'FCM has been inactive for >3 days, but server messages have been active. Resetting FCM tokens...',
        );
        await resetFCMTokens();
      } else {
        Log.info('FCM check passed. No reset needed.');
      }
    } catch (e) {
      Log.error('Error during FCM health check: $e');
    }
  }
}
