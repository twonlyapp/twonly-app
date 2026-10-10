import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories.service.dart';

class _MemoriesApi implements RustLibApi {
  final cloudDeletes = <String>[];
  final fileRemovals = <String>[];
  Exception? cloudError;

  @override
  Future<void> crateBridgeApiRustApiDeleteMemory({
    required String mediaId,
  }) async {
    cloudDeletes.add(mediaId);
    if (cloudError != null) throw cloudError!;
  }

  @override
  Future<void> crateBridgeApiRustApiRemoveMediaFiles({
    required String mediaId,
  }) async {
    fileRemovals.add(mediaId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _MemoriesApi();
  late TwonlyDB database;
  late Directory support;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    database = TwonlyDB(NativeDatabase.memory());
    locator.registerSingleton<TwonlyDB>(database);
    support = Directory.systemTemp.createTempSync('memories-deletion-test-');
    AppEnvironment.initTesting(customSupportDir: support.path);
    api
      ..cloudDeletes.clear()
      ..fileRemovals.clear()
      ..cloudError = null;
  });

  tearDown(() async {
    await locator.unregister<TwonlyDB>();
    await database.close();
    support.deleteSync(recursive: true);
  });

  Future<MediaFileService> memory(CloudState cloudState) async {
    final file = await database.mediaFilesDao.insertOrUpdateMedia(
      MediaFilesCompanion.insert(
        mediaId: 'missing-image',
        type: MediaType.image,
        stored: const Value(true),
        hasThumbnail: const Value(true),
        cloudState: Value(cloudState),
      ),
    );
    return MediaFileService(file!);
  }

  test(
    'missing local-only image deletes without contacting the server',
    () async {
      final media = await memory(CloudState.none);
      api.cloudError = Exception('API error code 0');
      expect(media.storedPath.existsSync(), isFalse);
      expect(media.originalPath.existsSync(), isFalse);

      await MemoriesService.deleteMemory(media, completely: true);

      expect(api.cloudDeletes, isEmpty);
      expect(api.fileRemovals, ['missing-image']);
      expect(
        await database.mediaFilesDao.getMediaFileById('missing-image'),
        isNull,
      );
      expect(
        await database.mediaFilesDao.watchAllStoredMediaFiles().first,
        isEmpty,
      );
    },
  );

  for (final state in [CloudState.pending, CloudState.uploaded]) {
    test('already absent $state cloud image can still be deleted', () async {
      final media = await memory(state);
      api.cloudError = Exception('API error code 0');

      await MemoriesService.deleteMemory(media, completely: true);

      expect(api.cloudDeletes, ['missing-image']);
      expect(api.fileRemovals, ['missing-image']);
      expect(
        await database.mediaFilesDao.getMediaFileById('missing-image'),
        isNull,
      );
    });
  }

  for (final error in [
    Exception('connection timed out'),
    Exception('API error code 500'),
  ]) {
    test('$error preserves local data and reports failure', () async {
      final media = await memory(CloudState.uploaded);
      media.thumbnailPath.writeAsBytesSync([1, 2, 3]);
      api.cloudError = error;

      await expectLater(
        MemoriesService.deleteMemory(media, completely: true),
        throwsA(same(error)),
      );

      expect(api.fileRemovals, isEmpty);
      expect(media.thumbnailPath.existsSync(), isTrue);
      expect(
        await database.mediaFilesDao.getMediaFileById('missing-image'),
        isNotNull,
      );
    });
  }

  for (final state in [CloudState.none, CloudState.uploaded]) {
    test(
      'local deletion of missing $state image updates gallery state',
      () async {
        final media = await memory(state);

        await MemoriesService.deleteMemory(media, completely: false);

        final file = await database.mediaFilesDao.getMediaFileById(
          'missing-image',
        );
        expect(file!.stored, isFalse);
        expect(file.cloudState, state);
        expect(api.cloudDeletes, isEmpty);
        expect(api.fileRemovals, isEmpty);
        expect(
          await database.mediaFilesDao.watchAllStoredMediaFiles().first,
          state == CloudState.uploaded ? hasLength(1) : isEmpty,
        );
      },
    );
  }
}
