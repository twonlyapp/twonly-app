import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/backup.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

class _MemoriesApi extends NativeTestApi {
  ApiConnectionState connectionState = ApiConnectionState.authenticated;
  int? originalDate;
  Object? error;
  late StackTrace stackTrace;
  int requests = 0;
  int confirmations = 0;
  int thumbnailRefreshes = 0;
  Future<void> Function(String mediaId)? refreshThumbnail;
  Uint8List? mediaKey;
  Completer<FrbMemoriesUploadUrls>? pendingRequest;
  Completer<void>? requestStarted;

  @override
  Future<ApiConnectionState> crateBridgeApiRustApiConnectionState() async =>
      connectionState;

  @override
  Future<FrbMemoriesUploadUrls> crateBridgeApiRustApiRequestMemoriesUpload({
    required PlatformInt64 size,
    required PlatformInt64 originalDate,
    required String mediaId,
  }) {
    this.originalDate = originalDate;
    requests++;
    if (requestStarted != null && !requestStarted!.isCompleted) {
      requestStarted!.complete();
    }
    if (error != null) return Future.error(error!, stackTrace);
    if (pendingRequest != null) return pendingRequest!.future;
    return Future.value(
      FrbMemoriesUploadUrls(
        mediaId: mediaId,
        thumbnailUpload: const FrbPresignedPost(
          url: 'https://upload.example/thumbnail',
          fields: [('key', 'thumbnail')],
        ),
        fullUpload: const FrbPresignedPost(
          url: 'https://upload.example/full',
          fields: [('key', 'full')],
        ),
      ),
    );
  }

  @override
  Future<Uint8List>
  crateBridgeWrapperKeyManagerRustKeyManagerEncryptCloudMediaKey({
    required List<int> mediaKey,
    required String addition,
  }) async {
    this.mediaKey = Uint8List.fromList(mediaKey);
    return Uint8List.fromList([8, 9, 10]);
  }

  @override
  Future<void> crateBridgeApiRustApiConfirmMemoriesUpload({
    required String mediaId,
  }) async {
    confirmations++;
  }

  @override
  Future<void> crateBridgeApiRustApiStoreMedia({
    required String mediaId,
  }) async {}

  @override
  Future<void> crateBridgeApiRustApiMediaStepFinished({
    required String mediaId,
    required String kind,
  }) async {
    expect(kind, 'thumbnail');
    thumbnailRefreshes++;
    await refreshThumbnail?.call(mediaId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _MemoriesApi();
  late Directory support;
  late MemoriesCloudService service;
  late StreamSubscription<LogRecord> subscription;
  late Level? previousLogLevel;
  final records = <LogRecord>[];
  const mediaId = 'd98369cc-0902-436a-a785-85507d1f39d2';

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await TestDatabase.create();
    locator.registerSingleton<UserService>(UserService());
    userService.currentUser = testUserConfig(
      userId: 1,
      username: 'me',
      displayName: 'Me',
      subscriptionPlan: 'Free',
      currentSetupPage: null,
      appVersion: 100,
    )..isCloudBackupEnabled = true;
    support = Directory.systemTemp.createTempSync('memories-upload-test-');
    AppEnvironment.initTesting(customSupportDir: support.path);
    service = MemoriesCloudService();
    api
      ..connectionState = ApiConnectionState.authenticated
      ..originalDate = null
      ..requests = 0
      ..confirmations = 0
      ..thumbnailRefreshes = 0
      ..refreshThumbnail = null
      ..mediaKey = null
      ..error = null
      ..pendingRequest = null
      ..requestStarted = null
      ..stackTrace = StackTrace.fromString(
        '#0      requestUpload (package:twonly/upload.dart:42:7)',
      );
    previousLogLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    records.clear();
    subscription = Logger.root.onRecord.listen(records.add);

    final media = await rust_mediafiles.upsertMediaFile(
      patch: MediaFilePatch(
        mediaId: mediaId,
        type: MediaType.image.name,
        stored: true,
        hasThumbnail: true,
      ),
      transaction: currentDatabaseSession(),
    );
    final mediaService = MediaFileService(media);
    mediaService.storedPath.writeAsBytesSync([1, 2, 3]);
    mediaService.thumbnailPath.writeAsBytesSync([4, 5, 6]);
  });

  test('uploads encrypted thumbnail and media without cache files', () async {
    final uploads = <String>[];
    final progress = <MemoriesBackupProgress?>[];
    final progressSubscription = service.progressStream.listen(progress.add);
    addTearDown(progressSubscription.cancel);
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      uploads.add(request.url.path);
      expect(api.confirmations, 0);

      // Decode the file part of the actual multipart body sent to S3.
      final body = latin1.decode(request.bodyBytes);
      final fileHeader = body.indexOf('filename="file"');
      expect(fileHeader, greaterThanOrEqualTo(0));
      final start = body.indexOf('\r\n\r\n', fileHeader) + 4;
      final end = body.lastIndexOf('\r\n--');
      final payload = CloudMediaBackupEncrypted.fromBuffer(
        request.bodyBytes.sublist(start, end),
      );
      expect(payload.addition, 'app');
      expect(payload.encryptedMediaKey, [8, 9, 10]);
      final ciphertext = payload.mediaCiphertext;
      final bytes = await Chacha20.poly1305Aead().decrypt(
        SecretBox(
          ciphertext.sublist(0, ciphertext.length - 16),
          nonce: payload.mediaNonce,
          mac: Mac(ciphertext.sublist(ciphertext.length - 16)),
        ),
        secretKey: SecretKey(api.mediaKey!),
      );
      expect(bytes, request.url.path == '/thumbnail' ? [4, 5, 6] : [1, 2, 3]);
      return http.Response('', 204);
    });
    addTearDown(client.close);

    // No path_provider mock is installed: backup must not need cache files.
    await http.runWithClient(service.checkUploads, () => client);

    expect(uploads, ['/thumbnail', '/full']);
    expect(api.confirmations, 1);
    expect(
      api.originalDate,
      (await rust_mediafiles.getMediaFile(
            id: mediaId,
            transaction: currentDatabaseSession(),
          ))!.createdAt.millisecondsSinceEpoch ~/
          1000,
    );
    expect(
      (await rust_mediafiles.getMediaFile(
        id: mediaId,
        transaction: currentDatabaseSession(),
      ))!.cloudState,
      CloudState.uploaded,
    );
    expect(progress.any((p) => p?.currentUploadProgress == 1), isTrue);
    expect(service.isProcessing, isFalse);
    expect(service.currentProgress, isNull);
  });

  test('repairs an existing oversized thumbnail before uploading', () async {
    final media = MediaFileService(
      (await rust_mediafiles.getMediaFile(
        id: mediaId,
        transaction: currentDatabaseSession(),
      ))!,
    );
    media.thumbnailPath.writeAsBytesSync(Uint8List(400001));
    api.refreshThumbnail = (_) async {
      expect(api.requests, 0);
      await media.thumbnailPath.writeAsBytes([4, 5, 6]);
    };
    final uploads = <String>[];
    final client = MockClient((request) async {
      expect(api.thumbnailRefreshes, 1);
      expect(request.bodyBytes.length, lessThan(400000));
      uploads.add(request.url.path);
      return http.Response('', 204);
    });
    addTearDown(client.close);

    await http.runWithClient(service.checkUploads, () => client);

    expect(uploads, ['/thumbnail', '/full']);
    expect(api.confirmations, 1);
    expect(
      await rust_mediafiles.listMediaFiles(
        input: const db_mediafiles.MediaQuery(
          filter: db_mediafiles.MediaFilter.memoriesToBackup,
        ),
        transaction: currentDatabaseSession(),
      ),
      isEmpty,
    );
    expect(media.storedPath.readAsBytesSync(), [1, 2, 3]);
  });

  test(
    'failed thumbnail repair leaves backup queued without an S3 request',
    () async {
      final media = MediaFileService(
        (await rust_mediafiles.getMediaFile(
          id: mediaId,
          transaction: currentDatabaseSession(),
        ))!,
      );
      media.thumbnailPath.writeAsBytesSync(Uint8List(400001));
      final client = MockClient((_) async {
        fail('An oversized thumbnail must not be sent to S3');
      });
      addTearDown(client.close);

      await http.runWithClient(service.checkUploads, () => client);

      expect(api.thumbnailRefreshes, 1);
      expect(api.requests, 0);
      expect(api.confirmations, 0);
      expect(
        await rust_mediafiles.listMediaFiles(
          input: const db_mediafiles.MediaQuery(
            filter: db_mediafiles.MediaFilter.memoriesToBackup,
          ),
          transaction: currentDatabaseSession(),
        ),
        hasLength(1),
      );
      expect(
        records.singleWhere((r) => r.error is StateError).error.toString(),
        contains('400001 bytes'),
      );
    },
  );

  test('concurrent saves use the shared backup worker', () async {
    final pending = Completer<FrbMemoriesUploadUrls>();
    final started = Completer<void>();
    api
      ..pendingRequest = pending
      ..requestStarted = started;
    final idle = memoriesCloudService.progressStream.firstWhere(
      (progress) => progress == null,
    );
    final media = MediaFileService(
      (await rust_mediafiles.getMediaFile(
        id: mediaId,
        transaction: currentDatabaseSession(),
      ))!,
    );
    try {
      await media.storeMediaFile();
      await started.future;
      expect(memoriesCloudService.isProcessing, isTrue);

      await media.storeMediaFile();
      await memoriesCloudService.checkUploads();

      expect(api.requests, 1);
      expect(pending.isCompleted, isFalse);
    } finally {
      // Release the worker without a network request, then wait for cleanup.
      pending.completeError(AnyhowException('Not connected'));
      if (memoriesCloudService.isProcessing) await idle;
    }
    expect(memoriesCloudService.isProcessing, isFalse);
  });

  test(
    'failed S3 upload preserves cause and permits a successful retry',
    () async {
      final client = MockClient((_) async => http.Response('', 500));
      addTearDown(client.close);
      await http.runWithClient(service.checkUploads, () => client);

      expect(api.confirmations, 0);
      expect(
        await rust_mediafiles.listMediaFiles(
          input: const db_mediafiles.MediaQuery(
            filter: db_mediafiles.MediaFilter.memoriesToBackup,
          ),
          transaction: currentDatabaseSession(),
        ),
        hasLength(1),
      );
      final record = records.singleWhere(
        (record) => record.message == 'Error backing up memory $mediaId',
      );
      expect(record.level, Level.SHOUT);
      expect(record.error.toString(), contains('S3 upload failed: 500'));
      expect(record.stackTrace, isNotNull);
      expect(service.isProcessing, isFalse);

      final retryClient = MockClient((_) async => http.Response('', 204));
      addTearDown(retryClient.close);
      await http.runWithClient(service.checkUploads, () => retryClient);

      expect(api.confirmations, 1);
      expect(
        await rust_mediafiles.listMediaFiles(
          input: const db_mediafiles.MediaQuery(
            filter: db_mediafiles.MediaFilter.memoriesToBackup,
          ),
          transaction: currentDatabaseSession(),
        ),
        isEmpty,
      );
    },
  );

  for (final uploadPath in ['/thumbnail', '/full']) {
    for (final error in [
      const SocketException('Failed host lookup: fsn1.your-objectstorage.com'),
      const SocketException(
        'Software caused connection abort',
        osError: OSError('Software caused connection abort', 103),
        port: 45090,
      ),
      http.ClientException(
        'SocketException: Software caused connection abort '
        '(OS Error: Software caused connection abort, errno = 103), '
        'address = fsn1.your-objectstorage.com, port = 45090',
        Uri.parse('https://fsn1.your-objectstorage.com/twonly'),
      ),
      http.ClientException(
        'Software caused connection abort',
        Uri.parse('https://fsn1.your-objectstorage.com/twonly'),
      ),
      http.ClientException(
        'SocketException: Failed host lookup: fsn1.your-objectstorage.com',
        Uri.parse('https://fsn1.your-objectstorage.com/twonly'),
      ),
      TimeoutException('Upload timed out'),
    ]) {
      test('$uploadPath $error warns and permits a successful retry', () async {
        final stackTrace = StackTrace.fromString(
          '#0      uploadToS3 (package:twonly/upload.dart:42:7)',
        );
        final client = MockClient((request) async {
          if (request.url.path == uploadPath) {
            Error.throwWithStackTrace(error, stackTrace);
          }
          return http.Response('', 204);
        });
        addTearDown(client.close);

        await http.runWithClient(service.checkUploads, () => client);

        final record = records.singleWhere(
          (record) => record.message == 'Error backing up memory $mediaId',
        );
        expect(record.level, Level.WARNING);
        expect(record.error, same(error));
        expect(record.stackTrace.toString(), contains(stackTrace.toString()));
        expect(records.where((r) => r.level >= Level.SEVERE), isEmpty);
        expect(api.confirmations, 0);
        expect(
          (await rust_mediafiles.getMediaFile(
            id: mediaId,
            transaction: currentDatabaseSession(),
          ))!.cloudState,
          CloudState.none,
        );
        expect(
          await rust_mediafiles.listMediaFiles(
            input: const db_mediafiles.MediaQuery(
              filter: db_mediafiles.MediaFilter.memoriesToBackup,
            ),
            transaction: currentDatabaseSession(),
          ),
          hasLength(1),
        );
        expect(service.isProcessing, isFalse);
        expect(service.currentProgress, isNull);

        final retryClient = MockClient((_) async => http.Response('', 204));
        addTearDown(retryClient.close);
        await http.runWithClient(service.checkUploads, () => retryClient);

        expect(api.confirmations, 1);
        expect(
          await rust_mediafiles.listMediaFiles(
            input: const db_mediafiles.MediaQuery(
              filter: db_mediafiles.MediaFilter.memoriesToBackup,
            ),
            transaction: currentDatabaseSession(),
          ),
          isEmpty,
        );
      });
    }
  }

  tearDown(() async {
    service.dispose();
    await subscription.cancel();
    Logger.root.level = previousLogLevel;
    await locator.unregister<UserService>();

    support.deleteSync(recursive: true);
  });

  test('offline worker leaves memory queued until authentication', () async {
    api.connectionState = ApiConnectionState.reconnecting;

    await service.checkUploads();

    expect(api.requests, 0);
    expect(service.isProcessing, isFalse);
    expect(
      await rust_mediafiles.listMediaFiles(
        input: const db_mediafiles.MediaQuery(
          filter: db_mediafiles.MediaFilter.memoriesToBackup,
        ),
        transaction: currentDatabaseSession(),
      ),
      hasLength(1),
    );

    api.connectionState = ApiConnectionState.authenticated;
    final client = MockClient((_) async => http.Response('', 204));
    addTearDown(client.close);
    await http.runWithClient(service.checkUploads, () => client);

    expect(api.confirmations, 1);
    expect(
      await rust_mediafiles.listMediaFiles(
        input: const db_mediafiles.MediaQuery(
          filter: db_mediafiles.MediaFilter.memoriesToBackup,
        ),
        transaction: currentDatabaseSession(),
      ),
      isEmpty,
    );
  });

  test('pending upload from an interrupted run is retried', () async {
    await rust_mediafiles.updateMediaFiles(
      id: mediaId,
      patch: MediaFilePatch(cloudState: CloudState.pending.name),
      transaction: currentDatabaseSession(),
    );
    final client = MockClient((_) async => http.Response('', 204));
    addTearDown(client.close);

    await http.runWithClient(service.checkUploads, () => client);

    expect(api.requests, 1);
    expect(api.confirmations, 1);
    expect(
      await rust_mediafiles.listMediaFiles(
        input: const db_mediafiles.MediaQuery(
          filter: db_mediafiles.MediaFilter.memoriesToBackup,
        ),
        transaction: currentDatabaseSession(),
      ),
      isEmpty,
    );
  });

  for (final message in [
    'Not connected',
    'API request timed out',
    'response channel closed',
    'send error: ChannelClosed',
    'API error code 1022',
    'API error code 1023',
    'API error code 1009',
    'API error code 429',
    'API error code 500',
    'invalid API response',
  ]) {
    test(
      '$message retains cause and stack and leaves memory retryable',
      () async {
        api.error = AnyhowException(message);

        await service.checkUploads();

        final record = records.singleWhere(
          (record) =>
              record.message == 'Could not get upload URLs for memory $mediaId',
        );
        expect(record.error, same(api.error));
        expect(record.stackTrace, same(api.stackTrace));
        expect(
          record.level,
          ['API error code 500', 'invalid API response'].contains(message)
              ? Level.SHOUT
              : Level.WARNING,
        );
        expect(service.isProcessing, isFalse);
        expect(service.currentProgress, isNull);
        expect(
          (await rust_mediafiles.getMediaFile(
            id: mediaId,
            transaction: currentDatabaseSession(),
          ))!.cloudState,
          CloudState.none,
        );
        expect(
          await rust_mediafiles.listMediaFiles(
            input: const db_mediafiles.MediaQuery(
              filter: db_mediafiles.MediaFilter.memoriesToBackup,
            ),
            transaction: currentDatabaseSession(),
          ),
          hasLength(1),
        );

        await service.checkUploads();

        expect(api.requests, 2);
        expect(service.isProcessing, isFalse);
      },
    );
  }
}
