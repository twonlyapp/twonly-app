import 'package:sentry_flutter/sentry_flutter.dart';

final _uuid = RegExp(
  '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
  caseSensitive: false,
);
final _downloadToken = RegExp(r'(/api/download/)[^\s)\]"\x27?]+');
final _userId = RegExp(r'\b(from|user|peer|target) -?\d+\b');
final _ciphertextRecipient = RegExp(r'(ciphertext message for )-?\d+\b');
final _signalAddress = RegExp(
  r'(session with |identity for address )-?\d+\.\d+',
);
final _signalCounter = RegExp(r'old counter \d+ / \d+');
final _s3RequestId = RegExp(r'<(RequestId|HostId)>[^<]*</\1>');
final _uploadSize = RegExp(r'\(\d+ encrypted bytes\)');
final _socketPort = RegExp(r'\bport = \d+\b');

/// Keep failure reasons stable across users, messages, files and requests.
/// Apply at beforeSend so uncaught bridge errors are covered too, while local
/// warning logs can retain the details needed to investigate a failed retry.
String normalizeReportedError(String message) => message
    .replaceAll(_uuid, '<id>')
    .replaceAllMapped(_downloadToken, (match) => '${match[1]}<token>')
    .replaceAllMapped(_userId, (match) => '${match[1]} <user>')
    .replaceAllMapped(_ciphertextRecipient, (match) => '${match[1]}<user>')
    .replaceAllMapped(_signalAddress, (match) => '${match[1]}<address>')
    .replaceAll(_signalCounter, 'old counter <counter> / <counter>')
    .replaceAllMapped(
      _s3RequestId,
      (match) => '<${match[1]}><id></${match[1]}>',
    )
    .replaceAll(_uploadSize, '(<size> encrypted bytes)')
    .replaceAll(_socketPort, 'port = <port>');

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

  // Change only the text: preserve exception types, mechanisms and stacks so
  // different failures remain distinguishable and actionable in GlitchTip.
  for (final exception in event.exceptions ?? <SentryException>[]) {
    final value = exception.value;
    if (value != null) exception.value = normalizeReportedError(value);
  }
  final message = event.message;
  if (message != null) {
    message.formatted = normalizeReportedError(message.formatted);
    final template = message.template;
    if (template != null) message.template = normalizeReportedError(template);
    message.params = message.params
        ?.map(
          (param) => param is String ? normalizeReportedError(param) : param,
        )
        .toList();
  }
  final log = event.contexts['log'];
  if (log is Map && log['message'] is String) {
    event.contexts['log'] = {
      ...log,
      'message': normalizeReportedError(log['message'] as String),
    };
  }
  return event;
}
