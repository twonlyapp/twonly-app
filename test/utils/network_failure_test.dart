import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/src/utils/network_failure.dart';

void main() {
  test('recognizes retryable connection failures', () {
    for (final error in [
      const SocketException('Network is unreachable'),
      TimeoutException('Request timed out'),
      http.ClientException('Connection reset by peer'),
      const HandshakeException('Connection terminated during handshake'),
    ]) {
      expect(isTransientNetworkFailure(error), isTrue);
    }
  });

  test('certificate failures and programming errors remain errors', () {
    for (final error in [
      const HandshakeException('CERTIFICATE_VERIFY_FAILED: Hostname mismatch'),
      http.ClientException('CERTIFICATE_VERIFY_FAILED'),
      StateError('Invalid response'),
      const FormatException('Invalid JSON'),
    ]) {
      expect(isTransientNetworkFailure(error), isFalse);
    }
  });
}
