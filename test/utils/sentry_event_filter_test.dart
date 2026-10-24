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

  test('normalizes identifier variants found in GlitchTip issue messages', () {
    const firstId = '11111111-2222-4333-8444-555555555555';
    const secondId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
    final firstToken = 'a' * 64;
    final secondToken = 'b' * 64;
    final variants = [
      (
        'AnyhowException(error sending request for url '
            '(https://api.twonly.eu/api/download/$firstToken))',
        'AnyhowException(error sending request for url '
            '(https://api.twonly.eu/api/download/$secondToken))',
      ),
      (
        'Could not decrypt message (V2) from 123456789: '
            'AnyhowException(Signal protocol error: message with old counter 7 / 5)',
        'Could not decrypt message (V2) from 987654321: '
            'AnyhowException(Signal protocol error: message with old counter 22 / 21)',
      ),
      (
        'Could not encrypt message (V2) for target 123456789: '
            'session with 123456789.1 not found: message_encrypt',
        'Could not encrypt message (V2) for target 987654321: '
            'session with 987654321.2 not found: message_encrypt',
      ),
      (
        '[$firstId] Could not encrypt the message (V2) for user 123456789.',
        '[$secondId] Could not encrypt the message (V2) for user 987654321.',
      ),
      (
        'untrusted identity for address 123456789.1',
        'untrusted identity for address 987654321.2',
      ),
      (
        'Could not generate ciphertext message for 123456789',
        'Could not generate ciphertext message for 987654321',
      ),
      (
        'Could not get upload URLs for memory $firstId',
        'Could not get upload URLs for memory $secondId',
      ),
      (
        'Error backing up memory $firstId: PathNotFoundException: '
            "Cannot open file, path = '/cache/thumb_$firstId.encrypted'",
        'Error backing up memory $secondId: PathNotFoundException: '
            "Cannot open file, path = '/cache/thumb_$secondId.encrypted'",
      ),
      (
        'Media file not found for $firstId => $secondId',
        'Media file not found for $secondId => $firstId',
      ),
      (
        'S3 upload failed: 400 (1000 encrypted bytes) - <Error> '
            '<Code>EntityTooLarge</Code><RequestId>request-a</RequestId>'
            '<HostId>host-a</HostId></Error>',
        'S3 upload failed: 400 (2000 encrypted bytes) - <Error> '
            '<Code>EntityTooLarge</Code><RequestId>request-b</RequestId>'
            '<HostId>host-b</HostId></Error>',
      ),
      (
        'Connection reset by peer, errno = 104, port = 49142',
        'Connection reset by peer, errno = 104, port = 45090',
      ),
    ];
    for (final (first, second) in variants) {
      final normalized = normalizeReportedError(first);
      expect(normalized, isNot(first));
      expect(normalized, normalizeReportedError(second));
      expect(normalizeReportedError(normalized), normalized);
    }
  });

  test('preserves failure reasons, HTTP status codes and OS error codes', () {
    for (final message in [
      'S3 upload failed: 400 (EntityTooLarge)',
      'S3 upload failed: 403 (AccessDenied)',
      'Connection reset by peer, errno = 104',
      'Signal protocol error: invalid prekey identifier',
      'Signal protocol error: invalid Whisper message: decryption failed',
    ]) {
      expect(normalizeReportedError(message), message);
    }
  });

  test(
    'normalizes every exception and log message without losing metadata',
    () {
      const raw = 'Could not decrypt message (V2) from 123456789';
      final frame = SentryStackFrame(
        function: 'decrypt',
        fileName: 'signal.dart',
      );
      final mechanism = Mechanism(type: 'generic', handled: false);
      final original = SentryEvent(
        level: SentryLevel.fatal,
        exceptions: [
          SentryException(type: '_Exception', value: raw),
          SentryException(
            type: 'AnyhowException',
            value: 'untrusted identity for address 123456789.1',
            mechanism: mechanism,
            stackTrace: SentryStackTrace(frames: [frame]),
          ),
        ],
        message: SentryMessage(raw, template: raw, params: [raw, 42]),
      );
      final logContext = {'message': raw, 'other': 'retained'};
      original.contexts['log'] = logContext;

      final filtered = filterSentryEvent(original, Hint())!;
      expect(filtered.level, SentryLevel.fatal);
      expect(filtered.exceptions!.first.type, '_Exception');
      expect(filtered.exceptions!.last.type, 'AnyhowException');
      expect(filtered.exceptions!.last.mechanism, same(mechanism));
      expect(filtered.exceptions!.last.stackTrace!.frames.single, same(frame));
      final json = filtered.toJson().toString();
      expect(json, isNot(contains('123456789')));
      expect(json, contains('untrusted identity'));
      expect(filtered.message!.params!.last, 42);
    expect((filtered.contexts['log'] as Map)['other'], 'retained');
      // The scope's original context must remain untouched.
      expect(logContext['message'], raw);
    },
  );
}
