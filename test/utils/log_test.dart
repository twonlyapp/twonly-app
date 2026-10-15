import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/log.dart';

void main() {
  late Completer<SentryEvent> captured;
  late bool previousErrorTracking;

  setUp(() async {
    previousErrorTracking = AppState.allowErrorTrackingViaSentry;
    AppState.allowErrorTrackingViaSentry = true;
    captured = Completer<SentryEvent>();
    await Sentry.init((options) {
      options
        ..dsn = 'https://public@example.com/1'
        ..debug = false
        ..beforeSend = (event, hint) {
          captured.complete(event);
          // Inspect the real Sentry event without sending it over the network.
          return null;
        };
    });
  });

  tearDown(() async {
    AppState.allowErrorTrackingViaSentry = previousErrorTracking;
    await Sentry.close();
  });

  test('reports the upload cause and its original stack trace', () async {
    final error = TimeoutException('Upload timed out');
    final stackTrace = StackTrace.fromString(
      '#0      uploadArchive (package:twonly/upload.dart:42:7)',
    );

    Log.error(
      'Archive backup upload failed.',
      error: error,
      stackTrace: stackTrace,
    );

    final event = await captured.future;
    expect(event.throwable, same(error));
    final exception = event.exceptions!.single;
    expect(exception.type, 'TimeoutException');
    expect(exception.value, contains('Upload timed out'));
    expect(exception.stackTrace!.frames.single.function, 'uploadArchive');
    expect(event.contexts['log'], {'message': 'Archive backup upload failed.'});
  });

  test('preserves exceptions passed as the log message', () async {
    final error = StateError('Backup unavailable');
    Log.error(error);

    final event = await captured.future;
    expect(event.throwable, same(error));
    expect(event.exceptions!.single.type, 'StateError');
  });

  test('message-only errors retain their message and caller stack', () async {
    Log.error('Archive backup upload failed with status 500.');

    final event = await captured.future;
    expect(
      event.exceptions!.single.value,
      'Exception: Archive backup upload failed with status 500.',
    );
    expect(event.exceptions!.single.stackTrace!.frames, isNotEmpty);
  });

  test('redacts SQLite parameters from the cause and log context', () async {
    final error = Exception(
      'SqliteException: write failed, parameters: [private message]',
    );
    Log.error('$error', error: error);

    final event = await captured.future;
    expect(event.exceptions!.single.value, isNot(contains('private message')));
    expect('${event.contexts['log']}', isNot(contains('private message')));
    expect(event.exceptions!.single.value, contains('write failed'));
  });

  test('does not report errors when tracking is disabled', () async {
    AppState.allowErrorTrackingViaSentry = false;
    Log.error(
      'Archive backup upload failed.',
      error: TimeoutException('Upload timed out'),
    );
    Log.error('Sentry only', onlyIfSentryEnabled: true);
    await Sentry.close();

    expect(captured.isCompleted, isFalse);
  });
}
