import 'package:sentry_flutter/sentry_flutter.dart';

SentryEvent? filterSentryEvent(SentryEvent event, Hint hint) {
  for (final exception in event.exceptions ?? <SentryException>[]) {
    if (exception.type != 'LateError' &&
        exception.type != 'LateInitializationError') {
      continue;
    }
    final channelNotInitialized = RegExp(
      r"Field '_channel(?:@\d+)?' has not been initialized",
    ).hasMatch(exception.value ?? '');
    final disposingMap =
        exception.stackTrace?.frames.any(
          (frame) =>
              frame.function == 'MapLibreMethodChannel.dispose' &&
              (frame.fileName ?? '').endsWith(
                'method_channel_maplibre_gl.dart',
              ),
        ) ??
        false;
    // MapLibre can dispose before its native channel exists. Ignore only this
    // known teardown error, keeping unrelated initialization failures visible.
    if (channelNotInitialized && disposingMap) return null;
  }
  return event;
}
