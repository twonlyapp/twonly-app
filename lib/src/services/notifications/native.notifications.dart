import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/core/bridge/wrapper/app_database.dart';
import 'package:twonly/src/utils/log.dart';

/// Taps on notifications rendered natively (Android `MessagingStyle`) arrive
/// through a platform channel instead of the Firebase Messaging plugin, which
/// no longer owns background delivery.
///
/// Only opaque notification metadata crosses the channel; Flutter owns the
/// routing decision.
class NativeNotificationService {
  static const MethodChannel _channel = MethodChannel(
    'eu.twonly/notificationTap',
  );

  static const String _conversationIdKey = 'conversation_id';
  static const String _notificationKindKey = 'notification_kind';
  static const String _notificationIdsKey = 'notification_ids';
  static const String _badgeCountKey = 'badge_count';

  /// The table Rust commits to whenever a notification event is recorded,
  /// delivered or cleared.
  static const String _outboxTable = 'notification_outbox';

  static final StreamController<NativeNotificationTap> _taps =
      StreamController<NativeNotificationTap>.broadcast();

  /// Lives for the whole process: the badge has to follow the outbox for as
  /// long as the app runs.
  // ignore: cancel_subscriptions
  static StreamSubscription<List<String>>? _outboxChanges;

  /// Emits metadata for every native notification tapped while the app runs.
  static Stream<NativeNotificationTap> get taps => _taps.stream;

  /// Text messages (including quoted replies) open their conversation. Media
  /// and every other notification kind stay on the chat overview.
  static bool opensConversation(String? kind) =>
      kind == 'text' || kind == 'response';

  static void init() {
    _startBadgeSync();
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onNotificationTapped') return;
      _taps.add(_tapOf(call.arguments));
    });
  }

  /// Keeps the iOS app icon badge in sync with the pending notification
  /// events. Only the notification service extension ever sets a badge on a
  /// delivered alert, so without this the number stays at whatever the last
  /// push reported even after every message has been read.
  static void _startBadgeSync() {
    if (!Platform.isIOS || _outboxChanges != null) return;
    try {
      _outboxChanges = RustAppDatabase.changes().listen(
        (tables) {
          // An empty batch means Rust could not say what changed, so the
          // outbox has to be assumed stale as well.
          if (tables.isNotEmpty && !tables.contains(_outboxTable)) return;
          unawaited(refreshBadgeCount());
        },
        onError: (Object error) {
          Log.error('Notification badge change stream failed: $error');
        },
      );
    } catch (e) {
      Log.error('Could not watch the notification outbox: $e');
      return;
    }
    unawaited(refreshBadgeCount());
  }

  /// Reads the pending event count from Rust and writes it to the app icon.
  static Future<void> refreshBadgeCount() async {
    if (!Platform.isIOS) return;
    try {
      final count = await RustApi.notificationBadgeCount();
      await _channel.invokeMethod<void>('setBadgeCount', {
        _badgeCountKey: count,
      });
    } catch (e) {
      Log.error('Could not update the app icon badge: $e');
    }
  }

  /// Acknowledges every pending notification of a conversation the user just
  /// opened and withdraws the alerts still on screen.
  static Future<void> clearConversation(String conversationId) async {
    if (conversationId.isEmpty) return;
    try {
      final notificationIds = await RustApi.clearConversationNotifications(
        conversationId: conversationId,
      );
      await cancelNotifications(notificationIds);
    } catch (e) {
      Log.error('Could not clear the notifications of a conversation: $e');
    }
  }

  /// Acknowledges the contact requests the user just looked at. They belong to
  /// no conversation, so this is the only moment they can be cleared.
  static Future<void> clearContactRequests() async {
    try {
      final notificationIds = await RustApi.clearContactRequestNotifications();
      await cancelNotifications(notificationIds);
    } catch (e) {
      Log.error('Could not clear the contact request notifications: $e');
    }
  }

  /// Returns the tap that launched the app, or `null` when the app was not
  /// started from a native notification. The result is consumed once.
  static Future<NativeNotificationTap?> consumeInitialTap() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'consumeInitialNotification',
      );
      if (result == null) return null;
      return _tapOf(result);
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

  static String? _notificationKindOf(Object? arguments) {
    if (arguments is! Map) return null;
    final notificationKind = arguments[_notificationKindKey];
    if (notificationKind is! String || notificationKind.isEmpty) return null;
    return notificationKind;
  }

  static NativeNotificationTap _tapOf(Object? arguments) => (
    conversationId: _conversationIdOf(arguments),
    kind: _notificationKindOf(arguments),
  );
}

typedef NativeNotificationTap = ({String? conversationId, String? kind});
