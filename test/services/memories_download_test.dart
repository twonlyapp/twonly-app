import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:twonly/core/database/app/mediafiles/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/client/generated/backup.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';

class _DownloadApi implements RustLibApi {
  int decryptions = 0;
  final key = Uint8List(32);

  @override
  Future<String> crateBridgeApiRustApiGetMemoriesUrl({
    required String mediaId,
    required bool thumbnail,
  }) async => 'https://download.example/media';

  @override
  Future<Uint8List>
  crateBridgeWrapperKeyManagerRustKeyManagerDecryptCloudMediaKey({
    required List<int> encryptedMediaKey,
    required String addition,
  }) async {
    decryptions++;
    return key;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DownloadClient extends http.BaseClient {
  _DownloadClient(this.response);

  final http.StreamedResponse response;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return response;
  }

  @override
  void close() => closed = true;
}

void main() {
  final api = _DownloadApi();
  late Directory directory;
  late MediaFileService media;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() {
    api.decryptions = 0;
    directory = Directory.systemTemp.createTempSync('memories-download-test-');
    AppEnvironment.initTesting(customSupportDir: directory.path);
    media = MediaFileService(
      const MediaFile(
        mediaId: 'imported-memory',
        typeName: 'image',
        cloudStateName: 'uploaded',
        requiresAuthentication: false,
        stored: false,
        isDraftMedia: false,
        isWidgetMedia: false,
        isFavorite: false,
        hasCropAnalyzed: false,
        hasThumbnail: true,
        galleryExportPending: false,
        createdAtSeconds: 1,
      ),
    );
  });

  tearDown(() => directory.delete(recursive: true));

  Future<bool> download(_DownloadClient client, {bool thumbnail = false}) =>
      http
          .runWithClient(
            () => MemoriesCloudService.downloadFromCloud(
              media,
              isThumbnail: thumbnail,
            ),
            () => client,
          )
          .timeout(const Duration(seconds: 5));

  Future<Uint8List> encrypt(Uint8List plain) async {
    final cipher = Chacha20.poly1305Aead();
    final nonce = cipher.newNonce();
    final box = await cipher.encrypt(
      plain,
      secretKey: SecretKey(api.key),
      nonce: nonce,
    );
    return (CloudMediaBackupEncrypted()
          ..addition = 'import_test'
          ..encryptedMediaKey = [1, 2, 3]
          ..mediaNonce = nonce
          ..mediaCiphertext = [...box.cipherText, ...box.mac.bytes])
        .writeToBuffer();
  }

  for (final thumbnail in [false, true]) {
    final label = thumbnail ? 'thumbnail' : 'full media';
    final limit = thumbnail ? 400000 : 100100000;

    test('$label decrypts an accepted streamed payload', () async {
      final plain = Uint8List.fromList([4, 5, 6]);
      final payload = await encrypt(plain);
      final client = _DownloadClient(
        http.StreamedResponse(
          Stream.fromIterable([payload.sublist(0, 10), payload.sublist(10)]),
          200,
        ),
      );
      expect(await download(client, thumbnail: thumbnail), isTrue);
      final file = thumbnail ? media.thumbnailPath : media.storedPath;
      expect(await file.readAsBytes(), plain);
      expect(api.decryptions, 1);
      expect(client.closed, isTrue);
    });

    test('$label rejects an oversized Content-Length before reading', () async {
      var listened = false;
      final body = StreamController<List<int>>(
        onListen: () => listened = true,
      );
      final client = _DownloadClient(
        http.StreamedResponse(body.stream, 200, contentLength: limit + 1),
      );
      expect(await download(client, thumbnail: thumbnail), isFalse);
      expect(listened, isFalse);
      expect(client.closed, isTrue);
      expect(api.decryptions, 0);
      expect(media.storedPath.existsSync(), isFalse);
      expect(media.thumbnailPath.existsSync(), isFalse);
      unawaited(body.close());
    });

    for (final declaredLength in [null, 1]) {
      test('$label limits actual bytes with length $declaredLength', () async {
        var cancelled = false;
        // Reuse chunks so the test need not allocate a full-media sized body.
        // Leave the stream open to require rejection before EOF.
        final chunk = Uint8List(100000);
        final body = StreamController<List<int>>(
          onCancel: () => cancelled = true,
        );
        for (var bytes = 0; bytes <= limit; bytes += chunk.length) {
          body.add(chunk);
        }
        final client = _DownloadClient(
          http.StreamedResponse(
            body.stream,
            200,
            contentLength: declaredLength,
          ),
        );
        expect(await download(client, thumbnail: thumbnail), isFalse);
        expect(cancelled, isTrue);
        expect(client.closed, isTrue);
        expect(api.decryptions, 0);
        expect(media.storedPath.existsSync(), isFalse);
        expect(media.thumbnailPath.existsSync(), isFalse);
        await body.close();
      });
    }
  }

  test('a failed download releases its slot and allows a retry', () async {
    final failed = _DownloadClient(
      http.StreamedResponse(Stream.error(const SocketException('reset')), 200),
    );
    expect(await download(failed), isFalse);
    expect(failed.closed, isTrue);
    expect(media.storedPath.existsSync(), isFalse);

    final payload = await encrypt(Uint8List.fromList([7, 8, 9]));
    final retry = _DownloadClient(
      http.StreamedResponse(Stream.value(payload), 200),
    );
    expect(await download(retry), isTrue);
    expect(retry.closed, isTrue);
  });

  test('HTTP errors are rejected without reading the response body', () async {
    final body = StreamController<List<int>>();
    final client = _DownloadClient(http.StreamedResponse(body.stream, 503));
    expect(await download(client), isFalse);
    expect(client.closed, isTrue);
    expect(api.decryptions, 0);
    unawaited(body.close());
  });
}
