import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

import '../../../firebase_options.dart';

// see more here: https://firebase.google.com/docs/cloud-messaging/flutter/receive?hl=de

class FcmNotificationService {
  /// FCM is only an opaque wake-up transport now. Delivery is owned natively by
  /// the iOS Notification Service Extension and by
  /// `TwonlyFirebaseMessagingService` on Android, both of which call Rust
  /// directly, so no Dart isolate or message listener is registered here.
  static Future<void> initStartup() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> initAfterUserLoaded() async {
    unawaited(_checkForTokenUpdates());
    unawaited(_checkFcmHealthAndResetIfNeeded());
  }

  static Future<void> initFCMAfterAuthenticated({bool force = false}) async {
    final fcmToken = userService.currentUser.fcmToken;
    if (userService.currentUser.updateFcmToken || force) {
      if (fcmToken == null) {
        Log.error('FCM token could not be updated as it is empty');
        await _checkForTokenUpdates();
        return;
      }
      if (await _uploadFcmToken(fcmToken)) {
        await UserService.update((u) {
          u.updateFcmToken = false;
        });
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
            ..updateFcmToken = true
            ..fcmToken = fcmToken;
        });
        if (await RustApi.connectionState() ==
            ApiConnectionState.authenticated) {
          if (await _uploadFcmToken(fcmToken)) {
            await UserService.update((u) {
              u.updateFcmToken = false;
            });
          }
        }
      }

      FirebaseMessaging.instance.onTokenRefresh
          // ignore: avoid_types_on_closure_parameters
          .listen((String fcmToken) async {
            await UserService.update((u) {
              u
                ..updateFcmToken = true
                ..fcmToken = fcmToken;
            });
            if (await RustApi.connectionState() ==
                ApiConnectionState.authenticated) {
              if (await _uploadFcmToken(fcmToken)) {
                await UserService.update((u) {
                  u.updateFcmToken = false;
                });
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

  static Future<bool> _uploadFcmToken(String token) async {
    try {
      await RustApi.updateFcmToken(token: token);
      Log.info('Uploaded new FCM token!');
      return true;
    } catch (error) {
      Log.error('Could not update FCM token!', error: error);
      return false;
    }
  }

  static Future<void> _checkFcmHealthAndResetIfNeeded() async {
    if (!userService.isUserCreated) {
      Log.info('FCM health check skipped: user is not yet created.');
      return;
    }
    try {
      final config = await UserConfigApi.load();
      if (config == null) {
        Log.warn('FCM health check skipped: user configuration is missing.');
        return;
      }

      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      // Recorded by the Rust notification worker, because neither platform
      // starts Flutter for a background wake-up any more.
      final lastFcmWakeup = config.lastFcmWakeupAt;
      final lastFcmTime = lastFcmWakeup == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastFcmWakeup * 1000);

      if (lastFcmTime != null) {
        Log.info(
          'Last message received via FCM messaging system: $lastFcmTime',
        );
      } else {
        Log.info('No record of a message received via FCM messaging system.');
      }

      final lastServerMessage = config.lastServerMessageAt;
      final lastServerTime = lastServerMessage == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastServerMessage * 1000);

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
