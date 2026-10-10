import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:twonly/core/bridge/live_location.dart' as live;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/location_metadata.service.dart';
import 'package:twonly/src/utils/log.dart';

class LiveLocationService {
  static const _channel = MethodChannel('eu.twonly/location_metadata');
  static const durations = [600, 1200, 3600, 7200, 28800];

  static LiveLocationData? decode(List<int>? bytes) {
    if (bytes == null) return null;
    try {
      final data = AdditionalMessageData.fromBuffer(bytes);
      if (data.type != AdditionalMessageData_Type.LIVE_LOCATION ||
          !data.hasLiveLocation()) {
        return null;
      }
      final location = data.liveLocation;
      if (location.sessionId.isEmpty ||
          location.messageId.isEmpty ||
          location.expiresAtMs <= 0) {
        return null;
      }
      if (location.hasLatitude() != location.hasLongitude()) return null;
      if (location.hasLatitude() &&
          (!location.latitude.isFinite ||
              !location.longitude.isFinite ||
              location.latitude < -90 ||
              location.latitude > 90 ||
              location.longitude < -180 ||
              location.longitude > 180)) {
        return null;
      }
      return location;
    } on Object {
      return null;
    }
  }

  static Future<live.LiveLocationSession?> state() => live.liveLocationState();

  static Future<void> start({
    required String groupId,
    required int durationSeconds,
    required String title,
    required String body,
    required String stopLabel,
  }) async {
    if (!await LocationMetadataService.requestPrecisePermission() ||
        !await Permission.notification.request().isGranted) {
      throw PlatformException(code: 'permission_denied');
    }
    final session = await live.startLiveLocation(
      groupIds: [groupId],
      durationSeconds: durationSeconds,
      text: title,
    );
    try {
      await _startNative(session, title, body, stopLabel);
    } on Object {
      await live.stopLiveLocationInChat(
        sessionId: session.sessionId,
        groupId: groupId,
      );
      rethrow;
    }
  }

  static Future<void> _startNative(
    live.LiveLocationSession session,
    String title,
    String body,
    String stopLabel,
  ) async {
    final started = await _channel.invokeMethod<bool>('startLiveLocation', {
      'session_id': session.sessionId,
      'expires_at_ms': session.expiresAtMs,
      'directory': AppEnvironment.supportDir,
      'title': title,
      'body': body,
      'stop': stopLabel,
    });
    if (started != true) {
      throw PlatformException(code: 'location_service_failed');
    }
  }

  static Future<void> stop(String sessionId) async {
    // Persist the stop before releasing the OS worker. A late tick cannot
    // reopen a share after its session has been removed.
    await live.stopLiveLocation(sessionId: sessionId);
    await _channel.invokeMethod<bool>('stopLiveLocation', {
      'session_id': sessionId,
    });
  }

  static Future<void> stopInChat(String sessionId, String groupId) async {
    await live.stopLiveLocationInChat(sessionId: sessionId, groupId: groupId);
    final session = await state();
    if (session == null) {
      await _channel.invokeMethod<bool>('stopLiveLocation', {
        'session_id': sessionId,
      });
    } else {
      final lang = _localizations();
      await _startNative(
        session,
        lang.liveLocationTitle,
        lang.liveLocationNotificationBody,
        lang.liveLocationStop,
      );
    }
  }

  static AppLocalizations _localizations() {
    final locale = userService.currentUser.language == null
        ? basicLocaleListResolution(
            WidgetsBinding.instance.platformDispatcher.locales,
            AppLocalizations.supportedLocales,
          )
        : Locale(userService.currentUser.language!);
    return lookupAppLocalizations(locale);
  }

  static Future<void> restore() async {
    try {
      final lang = _localizations();
      final session = await state();
      if (session != null) {
        try {
          await _startNative(
            session,
            lang.liveLocationTitle,
            lang.liveLocationNotificationBody,
            lang.liveLocationStop,
          );
        } on Object {
          await live.stopLiveLocation(sessionId: session.sessionId);
          rethrow;
        }
      }
    } on Object catch (error) {
      Log.warn('Could not restore live location: $error');
    }
  }
}
