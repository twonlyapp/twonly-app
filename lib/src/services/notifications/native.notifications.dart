import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:twonly/src/utils/log.dart';

/// Taps on notifications rendered natively (Android `MessagingStyle`) arrive
/// through a platform channel instead of the Firebase Messaging plugin, which
/// no longer owns background delivery.
///
/// Only the opaque conversation identifier crosses the channel; the Flutter
/// route is built here so the native layer stays free of routing knowledge.
class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel(
    'eu.twonly/notificationTap',
  );

  static const String _conversationIdKey = 'conversation_id';
  static const String _notificationIdsKey = 'notification_ids';

  static final StreamController<String?> _taps =
      StreamController<String?>.broadcast();

  /// Emits the conversation id of every notification tapped while the app is
  /// running. A `null` value means the notification had no specific
  /// conversation and should only open the chats tab.
  static Stream<String?> get taps => _taps.stream;

  static void init() {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onNotificationTapped') return;
      _taps.add(_conversationIdOf(call.arguments));
    });
  }

  /// Returns the tap that launched the app, or `null` when the app was not
  /// started from a native notification. The result is consumed once.
  static Future<({String? conversationId})?> consumeInitialTap() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'consumeInitialNotification',
      );
      if (result == null) return null;
      return (conversationId: _conversationIdOf(result));
    } catch (e) {
      Log.error('Could not read the initial native notification: $e');
      return null;
    }
  }

  /// Withdraws notifications for messages that have just been opened. Native
  /// notification identifiers are strings on iOS and stable hashes on Android,
  /// so the conversion stays in the platform implementation.
  static Future<void> cancelNotifications(
    Iterable<String> notificationIds,
  ) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final ids = notificationIds.where((id) => id.isNotEmpty).toSet().toList();
    if (ids.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('cancelNotifications', {
        _notificationIdsKey: ids,
      });
    } catch (e) {
      Log.error('Could not withdraw opened-message notifications: $e');
    }
  }

  static String? _conversationIdOf(Object? arguments) {
    if (arguments is! Map) return null;
    final conversationId = arguments[_conversationIdKey];
    if (conversationId is! String || conversationId.isEmpty) return null;
    return conversationId;
  }
}
