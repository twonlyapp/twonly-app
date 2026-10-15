import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/src/utils/sentry_event_filter.dart';

void main() {
  SentryEvent event({
    String type = 'LateError',
    String field = '_channel@1661297868',
    String function = 'MapLibreMethodChannel.dispose',
    String fileName = 'method_channel_maplibre_gl.dart',
  }) => SentryEvent(
    exceptions: [
      SentryException(
        type: type,
        value:
            "LateInitializationError: Field '$field' has not been initialized.",
        stackTrace: SentryStackTrace(
          frames: [SentryStackFrame(function: function, fileName: fileName)],
        ),
      ),
    ],
  );

  for (final type in ['LateError', 'LateInitializationError']) {
    test('ignores $type from MapLibre channel disposal', () {
      expect(filterSentryEvent(event(type: type), Hint()), isNull);
    });
  }

  test('ignores channel disposal without a private-field suffix', () {
    expect(filterSentryEvent(event(field: '_channel'), Hint()), isNull);
  });

  test('preserves unrelated initialization errors', () {
    final unrelated = [
      event(field: '_controller'),
      event(function: 'AnotherMethodChannel.dispose'),
      event(fileName: 'another_method_channel.dart'),
      event(type: 'StateError'),
      SentryEvent(),
    ];
    for (final original in unrelated) {
      expect(filterSentryEvent(original, Hint()), same(original));
    }
  });
}
