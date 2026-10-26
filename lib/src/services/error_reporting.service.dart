import 'dart:io';

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/services.dart';
import 'package:mutex/mutex.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/core/bridge/performance.dart' as rust_performance;
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/performance_tracking.service.dart';
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
    if (!enabled) {
      PerformanceTracking.setEnabled(false);
      AppState.allowErrorTrackingViaSentry = false;
      rust_performance.setEnabled(enabled: false);
    }
    if (_enabled == enabled) return;
    AppState.allowErrorTrackingViaSentry = false;
    await _channel.invokeMethod<void>('setEnabled', enabled);
    if (enabled) {
      await SentryFlutter.init(
        (options) => options
          ..dsn =
              'https://6b24a012c85144c9b522440a1d17d01c@glitchtip.twonly.eu/4'
          ..autoInitializeNativeSdk = false
          ..tracesSampleRate = kReleaseMode ? 0.01 : 1.0
          ..enableAutoPerformanceTracing = false
          ..beforeSendTransaction = PerformanceTracking.beforeSend
          ..sendDefaultPii = false
          ..beforeSend = filterSentryEvent
          ..enableAutoSessionTracking = false,
      );
    } else {
      await Sentry.close();
    }
    _enabled = enabled;
    AppState.allowErrorTrackingViaSentry = enabled;
    PerformanceTracking.setEnabled(enabled);
    rust_performance.setEnabled(enabled: enabled);
  });
}
