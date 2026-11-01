import 'dart:convert';
import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/core/bridge/api.dart';

typedef FeedbackDebugLog = ({String downloadToken, String encryptionKey});

/// Feedback must also work when the user cannot authenticate.
class FeedbackService {
  FeedbackService({http.Client? client, String Function()? apiBaseUrl})
    : _client = client ?? http.Client(),
      _apiBaseUrl = apiBaseUrl ?? (() => RustApi.apiBaseUrl(protocol: 'https'));

  final http.Client _client;
  final String Function() _apiBaseUrl;

  Future<FeedbackDebugLog> uploadDebugLog(String log) async {
    final algorithm = AesGcm.with256bits();
    final key = await algorithm.newSecretKey();
    final box = await algorithm.encrypt(
      gzip.encode(utf8.encode(log)),
      secretKey: key,
    );
    final response = await _client
        .post(
          Uri.parse('${_apiBaseUrl()}feedback/logs'),
          headers: {'Content-Type': 'application/octet-stream'},
          body: box.concatenation(),
        )
        .timeout(const Duration(minutes: 2));
    if (response.statusCode != 201) {
      throw http.ClientException(
        'Could not upload debug log (${response.statusCode}).',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final token = body['token'];
    if (token is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(token)) {
      throw const FormatException('Invalid debug log token.');
    }
    return (
      downloadToken: token,
      encryptionKey: (await key.extractBytes())
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join(),
    );
  }

  Future<void> submit(String message, {FeedbackDebugLog? debugLog}) async {
    final response = await _client
        .post(
          Uri.parse('${_apiBaseUrl()}feedback'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'feedback': message,
            if (debugLog != null) ...{
              'debug_log_token': debugLog.downloadToken,
              'debug_log_key': debugLog.encryptionKey,
            },
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 201) {
      throw http.ClientException(
        'Could not submit feedback (${response.statusCode}).',
      );
    }
  }

  void close() => _client.close();
}
