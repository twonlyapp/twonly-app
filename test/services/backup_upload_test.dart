import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:logging/logging.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';

class _BackupApi implements RustLibApi {
  late String archivePath;

  @override
  String crateBridgeApiRustApiApiBaseUrl({required String protocol}) =>
      '$protocol://backup.example/';

  @override
  Future<String?>
  crateBridgeWrapperBackupRustBackupIdentityGetBackupId() async => 'backup-id';

  @override
  Future<Uint8List>
  crateBridgeWrapperBackupRustBackupIdentityGetIdentityBackupBytes() async =>
      Uint8List.fromList([1, 2, 3]);

  @override
  Future<(String, String)>
  crateBridgeWrapperBackupRustBackupArchiveCreateBackupArchive() async =>
      ('download-token', archivePath);

  @override
  Future<Map<String, String>>
  crateBridgeApiRustApiAuthenticationHeaders() async => {
    'Authorization': 'test',
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UploadClient extends MockClient {
  _UploadClient(super.handler);

  bool closed = false;

  @override
  void close() {
    closed = true;
    super.close();
  }
}

void main() {
  final api = _BackupApi();
  late Directory directory;
  late DateTime lastSuccess;
  late Level? previousLogLevel;
  late StreamSubscription<LogRecord> logSubscription;
  final records = <LogRecord>[];
  final retryTimers = <Timer>[];

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('twonly-backup-upload-');
    AppEnvironment.initTesting(
      customCacheDir: directory.path,
      customSupportDir: directory.path,
    );
    api.archivePath = '${directory.path}/archive.bin';
    await File(api.archivePath).writeAsBytes([4, 5, 6]);
    lastSuccess = DateTime.now();
    previousLogLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    records.clear();
    logSubscription = Logger.root.onRecord.listen(records.add);
  });

  tearDown(() async {
    for (final timer in retryTimers) {
      timer.cancel();
    }
    retryTimers.clear();
    await logSubscription.cancel();
    Logger.root.level = previousLogLevel;
    await directory.delete(recursive: true);
  });

  Future<void> upload(_UploadClient client) => runZoned(
    () => http.runWithClient(BackupService.makeBackup, () => client),
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, callback) {
        final timer = parent.createTimer(zone, duration, callback);
        if (duration == const Duration(minutes: 15)) retryTimers.add(timer);
        return timer;
      },
    ),
  );

  for (final identity in [true, false]) {
    final kind = identity ? 'Identity' : 'Archive';

    group('$kind backup upload', () {
      setUp(() async {
        final status = CurrentBackupStatus()
          ..identityState = LastBackupUploadState.success
          ..identityLastSuccessFull = lastSuccess
          ..archiveState = LastBackupUploadState.success
          ..archiveLastSuccessFull = lastSuccess;
        if (identity) {
          status.identityState = LastBackupUploadState.failed;
        } else {
          status.archiveState = LastBackupUploadState.failed;
        }
        await KeyValueStore.put(
          KeyValueKeys.currentBackupState,
          status.toJson(),
        );
      });

      Future<void> expectFailure({Object? error, int statusCode = 200}) async {
        final client = _UploadClient((request) async {
          expect(request.method, identity ? 'PUT' : 'POST');
          if (error is Error) throw error;
          if (error is Exception) throw error;
          return http.Response('', statusCode);
        });
        await upload(client);

        final status = await BackupService.getData();
        expect(
          identity ? status.identityState : status.archiveState,
          LastBackupUploadState.failed,
        );
        expect(
          identity ? status.archiveState : status.identityState,
          LastBackupUploadState.success,
        );
        expect(status.identityLastSuccessFull, lastSuccess);
        expect(status.archiveLastSuccessFull, lastSuccess);
        expect(client.closed, isTrue);
        expect(retryTimers, hasLength(1));
      }

      for (final error in <Object>[
        const SocketException('Network unreachable'),
        http.ClientException('Connection closed before full header'),
        TimeoutException('Upload timed out'),
      ]) {
        test('${error.runtimeType} warns and schedules a retry', () async {
          await expectFailure(error: error);
          final record = records.singleWhere(
            (record) => record.message == '$kind backup upload failed.',
          );
          expect(record.level, Level.WARNING);
          expect(record.error, same(error));
          expect(record.stackTrace, isNotNull);
          expect(
            records.where((record) => record.level >= Level.SEVERE),
            isEmpty,
          );

          // A failed upload remains eligible without force, and a successful
          // retry records success and closes the replacement client.
          final retryClient = _UploadClient(
            (_) async => http.Response('', 200),
          );
          await upload(retryClient);
          final status = await BackupService.getData();
          expect(
            identity ? status.identityState : status.archiveState,
            LastBackupUploadState.success,
          );
          expect(
            identity
                ? status.identityLastSuccessFull
                : status.archiveLastSuccessFull,
            isNot(lastSuccess),
          );
          expect(retryClient.closed, isTrue);
        });
      }

      for (final error in <Object>[
        StateError('Unexpected upload failure'),
        const HandshakeException('Certificate verification failed'),
      ]) {
        test('${error.runtimeType} remains an error', () async {
          await expectFailure(error: error);
          final record = records.singleWhere(
            (record) => record.message == '$kind backup upload failed.',
          );
          expect(record.level, Level.SHOUT);
          expect(record.error, same(error));
          expect(record.stackTrace, isNotNull);
        });
      }

      test('server rejection remains an error', () async {
        await expectFailure(statusCode: 500);
        final record = records.singleWhere(
          (record) =>
              record.message == '$kind backup upload failed with status 500.',
        );
        expect(record.level, Level.SHOUT);
      });
    });
  }
}
