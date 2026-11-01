import 'dart:convert';
import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:twonly/src/services/feedback.service.dart';

void main() {
  const baseUrl = 'https://api.example.test/api/';
  final token = 'a' * 64;

  test('uploads compressed encrypted logs without authentication', () async {
    late List<int> uploaded;
    final service = FeedbackService(
      apiBaseUrl: () => baseUrl,
      client: MockClient((request) async {
        expect(request.url.toString(), '${baseUrl}feedback/logs');
        expect(request.method, 'POST');
        expect(request.headers['authorization'], isNull);
        expect(request.headers['content-type'], 'application/octet-stream');
        uploaded = request.bodyBytes;
        expect(
          utf8.decode(uploaded, allowMalformed: true),
          isNot(contains('private log')),
        );
        return http.Response(jsonEncode({'token': token}), 201);
      }),
    );
    addTearDown(service.close);
    final attachment = await service.uploadDebugLog('private log 👋');
    expect(attachment.downloadToken, token);
    final key = List<int>.generate(
      32,
      (i) => int.parse(
        attachment.encryptionKey.substring(i * 2, i * 2 + 2),
        radix: 16,
      ),
    );
    final box = SecretBox.fromConcatenation(
      uploaded,
      nonceLength: 12,
      macLength: 16,
    );
    final compressed = await AesGcm.with256bits().decrypt(
      box,
      secretKey: SecretKey(key),
    );
    expect(utf8.decode(gzip.decode(compressed)), 'private log 👋');
  });

  test(
    'submits JSON feedback with its attachment without authentication',
    () async {
      final attachment = (downloadToken: token, encryptionKey: 'b' * 64);
      final service = FeedbackService(
        apiBaseUrl: () => baseUrl,
        client: MockClient((request) async {
          expect(request.url.toString(), '${baseUrl}feedback');
          expect(request.headers['authorization'], isNull);
          expect(request.headers['content-type'], 'application/json');
          expect(jsonDecode(request.body), {
            'feedback': 'A report 👋',
            'debug_log_token': token,
            'debug_log_key': attachment.encryptionKey,
          });
          return http.Response('{"id": 1}', 201);
        }),
      );
      addTearDown(service.close);
      await service.submit('A report 👋', debugLog: attachment);
    },
  );

  test('submits feedback without a debug log', () async {
    final service = FeedbackService(
      apiBaseUrl: () => baseUrl,
      client: MockClient((request) async {
        expect(jsonDecode(request.body), {'feedback': 'A suggestion'});
        return http.Response('{"id": 2}', 201);
      }),
    );
    addTearDown(service.close);
    await service.submit('A suggestion');
  });

  test('does not report success on upload or feedback failures', () async {
    final service = FeedbackService(
      apiBaseUrl: () => baseUrl,
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );
    addTearDown(service.close);
    await expectLater(
      service.uploadDebugLog('A log'),
      throwsA(isA<http.ClientException>()),
    );
    await expectLater(
      service.submit('A message'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('rejects malformed log tokens', () async {
    final service = FeedbackService(
      apiBaseUrl: () => baseUrl,
      client: MockClient(
        (_) async => http.Response('{"token":"invalid"}', 201),
      ),
    );
    addTearDown(service.close);
    await expectLater(service.uploadDebugLog('A log'), throwsFormatException);
  });
}
