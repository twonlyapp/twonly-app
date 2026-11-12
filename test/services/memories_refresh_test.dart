import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart' as media;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';

import '../helpers/native_database.dart';

class _MemoriesApi extends NativeTestApi {
  StreamController<List<Contact>>? blockedContacts;
  StreamController<media.MediaCollection>? migrationResume;
  bool interruptMetadata = false;
  int metadataAttempts = 0;

  @override
  Stream<media.MediaCollection> crateBridgeDatabaseMediafilesWatchMediaFiles({
    required media.MediaQuery input,
    required DatabaseWatch control,
  }) {
    if (input.filter == media.MediaFilter.pendingMigration &&
        migrationResume != null) {
      return migrationResume!.stream;
    }
    return super.crateBridgeDatabaseMediafilesWatchMediaFiles(
      input: input,
      control: control,
    );
  }

  @override
  Future<void> crateBridgeApiRustApiMediaStepFinished({
    required String mediaId,
    required String kind,
  }) async {
    if (kind != 'stored') {
      return super.crateBridgeApiRustApiMediaStepFinished(
        mediaId: mediaId,
        kind: kind,
      );
    }
    metadataAttempts++;
    if (interruptMetadata) {
      interruptMetadata = false;
      migrationResume = StreamController<media.MediaCollection>();
      throw StateError('attempted to acquire a connection on a closed pool');
    }
    await testDatabase.customStatement(
      'UPDATE media_files SET stored_file_hash = ? WHERE media_id = ?',
      ['hash', mediaId],
    );
  }

  // Reproduce the command failure from #4058. Gallery refreshes must use the
  // native watches that wait through pool suspension instead of these reads.
  @override
  Future<List<StoredMessage>> crateBridgeDatabaseMessagesListMessages({
    required MessageQuery input,
    required DatabaseSession transaction,
  }) async =>
      throw StateError('error returned from database: (code: 9) interrupted');

  @override
  Future<List<Contact>> crateBridgeDatabaseContactsListContacts({
    required ContactQuery input,
    required DatabaseSession transaction,
  }) async =>
      throw StateError('error returned from database: (code: 9) interrupted');

  @override
  Stream<List<Contact>> crateBridgeDatabaseContactsWatchContacts({
    required ContactQuery input,
    required DatabaseWatch control,
  }) {
    final blocked = blockedContacts;
    if (blocked != null) {
      blockedContacts = null;
      return blocked.stream;
    }
    return super.crateBridgeDatabaseContactsWatchContacts(
      input: input,
      control: control,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = _MemoriesApi();
  late Directory support;
  late MemoriesService service;

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await TestDatabase.create();
    support = Directory.systemTemp.createTempSync('memories-refresh-test-');
    AppEnvironment.initTesting(customSupportDir: support.path);
    api
      ..blockedContacts = null
      ..migrationResume = null
      ..interruptMetadata = false
      ..metadataAttempts = 0;
    await testDatabase.customStatement(
      "INSERT INTO contacts(user_id,username) VALUES (7,'Alice')",
    );
    await testDatabase.customStatement(
      "INSERT INTO groups(group_id,group_name) VALUES ('chat','Chat')",
    );
    await testDatabase.customStatement('''
      INSERT INTO media_files(media_id,type,stored,has_thumbnail,
        stored_file_hash,blurhash,has_crop_analyzed,size_in_bytes)
      VALUES ('memory','image',1,1,'hash','blurhash',1,123)
    ''');
    await testDatabase.customStatement('''
      INSERT INTO messages(message_id,group_id,sender_id,type,media_id)
      VALUES ('message','chat',7,'media','memory')
    ''');
  });

  tearDown(() async {
    // Wait for any cache write queued immediately after a state emission.
    await KeyValueStore.get('memories_cache');
    support.deleteSync(recursive: true);
  });

  Future<void> waitFor(bool Function() ready) async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (!ready() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(ready(), isTrue);
  }

  test('metadata migration retries the interrupted file after resume', () async {
    await testDatabase.customStatement(
      "UPDATE media_files SET stored_file_hash = NULL WHERE media_id = 'memory'",
    );
    api.interruptMetadata = true;
    service = MemoriesService();
    addTearDown(service.dispose);
    await waitFor(() => api.migrationResume?.hasListener ?? false);
    expect(api.metadataAttempts, 1);
    final pending = await api.crateBridgeDatabaseMediafilesListMediaFiles(
      input: const media.MediaQuery(filter: media.MediaFilter.pendingMigration),
      transaction: DatabaseSession(),
    );
    api.migrationResume!.add(
      media.MediaCollection(
        files: pending,
        order: pending.map((f) => f.mediaId).toList(),
      ),
    );
    await waitFor(() => api.metadataAttempts == 2);
    await waitFor(() => !api.migrationResume!.hasListener);
    final saved = await api.crateBridgeDatabaseMediafilesListMediaFiles(
      input: const media.MediaQuery(filter: media.MediaFilter.pendingMigration),
      transaction: DatabaseSession(),
    );
    expect(saved, isEmpty);
    await api.migrationResume!.close();
  });

  test(
    'disposing a paused migration cancels its wait without retrying',
    () async {
      await testDatabase.customStatement(
        "UPDATE media_files SET stored_file_hash = NULL WHERE media_id = 'memory'",
      );
      api.interruptMetadata = true;
      service = MemoriesService();
      await waitFor(() => api.migrationResume?.hasListener ?? false);
      service.dispose();
      await waitFor(() => !api.migrationResume!.hasListener);
      expect(api.metadataAttempts, 1);
      await api.migrationResume!.close();
    },
  );

  test('gallery and sender load through lifecycle-aware snapshots', () async {
    service = MemoriesService();
    addTearDown(service.dispose);
    final state = await service.watchState
        .firstWhere(
          (state) => state.galleryItems.length == 1,
        )
        .timeout(const Duration(seconds: 5));
    expect(state.galleryItems.single.mediaService.mediaFile.mediaId, 'memory');
    expect(state.galleryItems.single.sender?.username, 'Alice');
    final cache = await KeyValueStore.get('memories_cache');
    expect((cache!['items'] as List).single, {
      'mediaId': 'memory',
      'senderUserId': 7,
    });
  });

  test('an older refresh cannot publish over a newer media snapshot', () async {
    service = MemoriesService();
    addTearDown(service.dispose);
    await service.watchState
        .firstWhere(
          (state) => state.galleryItems.length == 1,
        )
        .timeout(const Duration(seconds: 5));
    final blocked = StreamController<List<Contact>>();
    api.blockedContacts = blocked;
    final emitted = <MemoriesState>[];
    final subscription = service.watchState.listen(emitted.add);
    addTearDown(subscription.cancel);

    await testDatabase.customStatement(
      "UPDATE media_files SET stored = 0 WHERE media_id = 'memory'",
    );
    await waitFor(() => blocked.hasListener);
    // A newer snapshot arrives while the old batch waits for its contact read.
    await testDatabase.customStatement(
      "UPDATE media_files SET stored = 1 WHERE media_id = 'memory'",
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    blocked.add([]);
    await waitFor(() => emitted.isNotEmpty);
    expect(emitted.every((state) => state.galleryItems.length == 1), isTrue);
    expect(emitted.last.galleryItems.single.sender?.username, 'Alice');
    await blocked.close();
  });

  test(
    'disposing cancels a suspended snapshot without publishing or caching',
    () async {
      final blocked = StreamController<List<Contact>>();
      api.blockedContacts = blocked;
      await KeyValueStore.put('memories_cache', {'sentinel': true});
      service = MemoriesService();
      final emitted = <MemoriesState>[];
      final subscription = service.watchState.listen(emitted.add);
      await waitFor(() => blocked.hasListener);
      service.dispose();
      await waitFor(() => !blocked.hasListener);
      expect(emitted, isEmpty);
      expect(await KeyValueStore.get('memories_cache'), {'sentinel': true});
      await subscription.cancel();
      await blocked.close();
    },
  );
}
