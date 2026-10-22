import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';

import '../helpers/native_database.dart';

class _MemoriesApi extends NativeTestApi {
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
  late Directory support;

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await TestDatabase.create();

    support = Directory.systemTemp.createTempSync('memories-deletion-test-');
    AppEnvironment.initTesting(customSupportDir: support.path);
    api
      ..cloudDeletes.clear()
      ..fileRemovals.clear()
      ..cloudError = null;
  });

  tearDown(() async {
    support.deleteSync(recursive: true);
  });

  Future<MediaFileService> memory(CloudState cloudState) async {
    final file = await rust_mediafiles.upsertMediaFile(
      patch: MediaFilePatch(
        mediaId: 'missing-image',
        type: MediaType.image.name,
        stored: true,
        hasThumbnail: true,
        cloudState: cloudState.name,
      ),
      transaction: currentDatabaseSession(),
    );
    return MediaFileService(file);
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
        await rust_mediafiles.getMediaFile(
          id: 'missing-image',
          transaction: currentDatabaseSession(),
        ),
        isNull,
      );
      expect(
        await watchRustDatabase(
          (control) => rust_mediafiles
              .watchMediaFiles(
                input: const db_mediafiles.MediaQuery(
                  filter: db_mediafiles.MediaFilter.stored,
                ),
                control: control,
              )
              .map(orderedMediaFiles),
        ).first,
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
        await rust_mediafiles.getMediaFile(
          id: 'missing-image',
          transaction: currentDatabaseSession(),
        ),
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
        await rust_mediafiles.getMediaFile(
          id: 'missing-image',
          transaction: currentDatabaseSession(),
        ),
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

        final file = await rust_mediafiles.getMediaFile(
          id: 'missing-image',
          transaction: currentDatabaseSession(),
        );
        expect(file!.stored, isFalse);
        expect(file.cloudState, state);
        expect(api.cloudDeletes, isEmpty);
        expect(api.fileRemovals, isEmpty);
        expect(
          await watchRustDatabase(
            (control) => rust_mediafiles
                .watchMediaFiles(
                  input: const db_mediafiles.MediaQuery(
                    filter: db_mediafiles.MediaFilter.stored,
                  ),
                  control: control,
                )
                .map(orderedMediaFiles),
          ).first,
          state == CloudState.uploaded ? hasLength(1) : isEmpty,
        );
      },
    );
  }
}
