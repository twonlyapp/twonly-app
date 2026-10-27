import 'dart:async';
import 'dart:io' show Platform;

import 'package:clock/clock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/services/notifications/fcm_health_policy.dart';
import 'package:twonly/src/services/notifications/fcm_token_registration.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';

import '../../../firebase_options.dart';

class FcmNotificationService {
  // The native receivers own message delivery. This single registration owner
  // keeps startup, authentication, refresh events and recovery from racing.
  static final _registration = FcmTokenRegistration(
    readToken: _readToken,
    deleteToken: () => FirebaseMessaging.instance.deleteToken(),
    tokenRefreshes: () => FirebaseMessaging.instance.onTokenRefresh,
    saveToken: (token) => UserService.update((user) {
      user
        ..fcmToken = token
        ..updateFcmToken = true;
    }),
    isAuthenticated: () async =>
        await RustApi.connectionState() == ApiConnectionState.authenticated,
    uploadToken: (token) async {
      await RustApi.updateFcmToken(token: token);
      Log.info('FCM registration confirmed by server.');
    },
    onError: _registrationError,
  );

  static Future<void> initStartup() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static Future<void> initAfterUserLoaded() async {
    await _refreshRegistration();
    await _checkFcmHealthAndResetIfNeeded();
  }

  static Future<void> initFCMAfterAuthenticated() => _refreshRegistration();

  static Future<void> _refreshRegistration() async {
    if (!userService.isUserCreated) return;
    try {
      await _registration.refresh();
    } catch (error, stackTrace) {
      _registrationError(error, stackTrace);
    }
  }

  static void _registrationError(Object error, StackTrace stackTrace) {
    Log.warn('FCM registration will be retried.', error, stackTrace);
  }

  static Future<String?> _readToken() async {
    if (Platform.isIOS) {
      for (var attempt = 0; attempt < 20; attempt++) {
        if (await FirebaseMessaging.instance.getAPNSToken() != null) break;
        if (attempt == 19) throw StateError('APNs token is not available yet');
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> resetFCMTokens() async {
    if (!userService.isUserCreated) return;
    final now = clock.now();
    final monitoring = await _monitoring(now);
    await KeyValueStore.putAtomically(KeyValueKeys.fcmRecoveryMonitoring, {
      ...monitoring,
      'lastAttemptAt': now.toIso8601String(),
    });
    Log.info('Rotating FCM registration.');
    await _registration.reset();
    Log.info('FCM registration rotation finished.');
  }

  static Future<Map<String, dynamic>> _monitoring(DateTime now) async {
    final stored = await KeyValueStore.get(KeyValueKeys.fcmRecoveryMonitoring);
    if (DateTime.tryParse(stored?['since'] as String? ?? '') != null) {
      return stored!;
    }
    final monitoring = {'since': now.toIso8601String()};
    await KeyValueStore.putAtomically(
      KeyValueKeys.fcmRecoveryMonitoring,
      monitoring,
    );
    return monitoring;
  }

  static Future<void> _checkFcmHealthAndResetIfNeeded() async {
    if (!userService.isUserCreated) return;
    try {
      final config = await UserConfigApi.load();
      if (config == null) return;
      final now = clock.now();
      final monitoring = await _monitoring(now);
      DateTime? timestamp(int? seconds) => seconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      final lastWakeup = timestamp(config.lastFcmWakeupAt);
      Log.info('Last native FCM wake-up: $lastWakeup');
      if (FcmHealthPolicy.shouldReset(
        now: now,
        lastWakeup: lastWakeup,
        lastServerMessage: timestamp(config.lastServerMessageAt),
        monitoringSince: DateTime.parse(monitoring['since'] as String),
        lastRecoveryAttempt: DateTime.tryParse(
          monitoring['lastAttemptAt'] as String? ?? '',
        ),
      )) {
        Log.warn(
          'FCM wake-ups are stale; recovering the messaging registration.',
        );
        await resetFCMTokens();
      }
    } catch (error, stackTrace) {
      _registrationError(error, stackTrace);
    }
  }
}
