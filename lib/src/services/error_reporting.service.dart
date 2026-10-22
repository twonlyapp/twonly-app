import 'dart:io';

import 'package:flutter/services.dart';
import 'package:mutex/mutex.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/sentry_event_filter.dart';

/// Native SDKs own crash handling, including processes started without Flutter.
/// Mirror consent before starting Dart so the native SDK is never initialized
/// a second time by sentry_flutter.
class ErrorReportingService {
  static const _channel = MethodChannel('eu.twonly/error_reporting');
  static final _mutex = Mutex();
  static bool? _enabled;

  static Future<void> setEnabled(bool enabled) => _mutex.protect(() async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    if (_enabled == enabled) return;
    AppState.allowErrorTrackingViaSentry = false;
    await _channel.invokeMethod<void>('setEnabled', enabled);
    if (enabled) {
      await SentryFlutter.init(
        (options) => options
          ..dsn =
              'https://6b24a012c85144c9b522440a1d17d01c@glitchtip.twonly.eu/4'
          ..autoInitializeNativeSdk = false
          ..tracesSampleRate = 0.1
          ..beforeSend = filterSentryEvent
          ..enableAutoSessionTracking = false,
      );
    } else {
      await Sentry.close();
    }
    _enabled = enabled;
    AppState.allowErrorTrackingViaSentry = enabled;
  });
}
