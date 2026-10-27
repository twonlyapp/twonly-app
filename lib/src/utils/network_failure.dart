import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Connectivity failures leave cached content usable and can be retried.
/// A failed certificate check needs investigation and must remain an error.
bool isTransientNetworkFailure(Object error) {
  if (error is HandshakeException) {
    return error.message.contains('Connection terminated during handshake');
  }
  if (error is http.ClientException &&
      error.message.contains('CERTIFICATE_VERIFY_FAILED')) {
    return false;
  }
  return error is SocketException ||
      error is TimeoutException ||
      error is http.ClientException;
}
