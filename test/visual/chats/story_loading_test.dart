import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/media_viewer.view.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/media_content_renderer.comp.dart';

import '../../helpers/native_database.dart';
import '../../mocks/user_config.dart';

class _StoryLoadingApi extends NativeTestApi {
  final opened = <(int, String)>[];
  final downloads = <String>[];
  final pendingReceipts = <Completer<void>>[];
  Future<void> Function(String)? onDownload;
  int bulkDownloads = 0;

  @override
  Future<void> crateBridgeApiRustApiNotifyMessagesOpened({
    required int contactId,
    required List<String> messageIds,
  }) async {
    opened.addAll([for (final id in messageIds) (contactId, id)]);
    final pending = Completer<void>();
    pendingReceipts.add(pending);
    await pending.future;
  }

  @override
  Future<void> crateBridgeApiRustApiDownloadMedia({
    required String mediaId,
  }) async {
    downloads.add(mediaId);
    await onDownload?.call(mediaId);
  }

  @override
  Future<void> crateBridgeApiRustApiDownloadPendingMedia() async {
    bulkDownloads++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final api = _StoryLoadingApi();
  final cache = PaintingBinding.instance.imageCache;
  final media = <String, MediaFileService>{};
  late TestDatabase database;
  late Directory directory;

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    locator.registerSingleton<UserService>(
      UserService()
        ..currentUser = testUserConfig(
          userId: 1,
          username: 'me',
          displayName: 'Me',
          subscriptionPlan: 'Free',
          currentSetupPage: null,
          appVersion: 0,
        ),
    );
    api
      ..opened.clear()
      ..downloads.clear()
      ..pendingReceipts.clear()
      ..onDownload = null
      ..bulkDownloads = 0;
    cache
      ..clear()
      ..clearLiveImages();
    media.clear();
    directory = await Directory.systemTemp.createTemp('story-loading-');
    AppEnvironment.initTesting(customSupportDir: directory.path);
    database = await TestDatabase.create();
    await database.customStatement(
      "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'Friend', 1)",
    );
    await database.customStatement(
      "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('chat', 'Friend', 1)",
    );
    await database.customStatement(
      "INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 7)",
    );
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (var index = 0; index < 4; index++) {
      final id = 'image-$index';
      await database.customStatement(
        "INSERT INTO media_files(media_id, type, download_state) VALUES (?, 'image', 'ready')",
        [id],
      );
      await database.customStatement(
        "INSERT INTO messages(message_id, group_id, sender_id, type, media_id, is_story, created_at) VALUES (?, 'chat', 7, 'media', ?, 1, ?)",
        ['message-$index', id, now - 60 + index],
      );
      final file = (await rust_mediafiles.getMediaFile(
        id: id,
        transaction: currentDatabaseSession(),
      ))!;
      media[id] = MediaFileService(file);
      await File(
        'assets/images/default_avatar.png',
      ).copy(media[id]!.tempPath.path);
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('screen_protector'),
          (_) async => null,
        );
  });

  tearDown(() async {
    for (final receipt in api.pendingReceipts) {
      if (!receipt.isCompleted) receipt.complete();
    }
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('screen_protector'),
          null,
        );
    cache
      ..clear()
      ..clearLiveImages();
    await locator.reset();
    await directory.delete(recursive: true);
    AppEnvironment.initTesting();
  });

  bool cached(String id) =>
      cache.statusForKey(FileImage(media[id]!.tempPath)).keepAlive;

  String? displayed(WidgetTester tester) {
    final renderer = find.byType(MediaContentRenderer);
    if (renderer.evaluate().isEmpty) return null;
    return tester
        .widget<MediaContentRenderer>(renderer)
        .currentMedia
        ?.mediaFile
        .mediaId;
  }

  Future<void> pumpViewer(WidgetTester tester, {bool own = false}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaViewerView.story(
          own ? const StorySource.own() : const StorySource.contact(7),
        ),
      ),
    );
    await pumpNative(
      tester,
      until: () => find.byType(MediaContentRenderer).evaluate().isNotEmpty,
    );
  }

  testWidgets('images display and advance while opened receipts are pending', (
    tester,
  ) async {
    await pumpViewer(tester);
    await pumpNative(
      tester,
      until: () => cached('image-1') && cached('image-2'),
    );
    expect(displayed(tester), 'image-0');
    expect(api.opened, [(7, 'message-0')]);
    expect(api.pendingReceipts.single.isCompleted, isFalse);
    expect(cached('image-3'), isFalse);
    // Preloading never marks an upcoming story as opened.
    expect(api.downloads, isEmpty);

    await tester.tap(find.byType(MediaContentRenderer));
    await pumpNative(tester, until: () => displayed(tester) == 'image-1');
    expect(api.opened, [(7, 'message-0'), (7, 'message-1')]);
    expect(
      api.pendingReceipts.every((receipt) => !receipt.isCompleted),
      isTrue,
    );
    await pumpNative(tester, until: () => cached('image-3'));
    api.pendingReceipts.first.completeError(StateError('receipt unavailable'));
    await tester.pump();
    expect(displayed(tester), 'image-1');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('upcoming images download and decode before they are opened', (
    tester,
  ) async {
    await runNative(tester, () async {
      await media['image-1']!.tempPath.delete();
      await rust_mediafiles.updateMediaFiles(
        id: 'image-1',
        patch: const MediaFilePatch(
          downloadState: NullableText(value: 'pending'),
        ),
        transaction: currentDatabaseSession(),
      );
    });
    final download = Completer<void>();
    api.onDownload = (id) async {
      await download.future;
      await File(
        'assets/images/default_avatar.png',
      ).copy(media[id]!.tempPath.path);
      await rust_mediafiles.updateMediaFiles(
        id: id,
        patch: const MediaFilePatch(
          downloadState: NullableText(value: 'ready'),
        ),
        transaction: currentDatabaseSession(),
      );
    };
    await pumpViewer(tester);
    await pumpNative(tester, until: () => api.downloads.isNotEmpty);
    expect(displayed(tester), 'image-0');
    expect(api.downloads, ['image-1']);
    expect(cached('image-1'), isFalse);
    expect(api.bulkDownloads, 0);
    download.complete();
    await pumpNative(tester, until: () => cached('image-1'));
    expect(api.opened, [(7, 'message-0')]);
    await tester.tap(find.byType(MediaContentRenderer));
    await pumpNative(tester, until: () => displayed(tester) == 'image-1');
    expect(api.downloads, ['image-1']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'closing a story during preloading safely finishes its download',
    (
      tester,
    ) async {
      await runNative(
        tester,
        () => rust_mediafiles.updateMediaFiles(
          id: 'image-1',
          patch: const MediaFilePatch(
            downloadState: NullableText(value: 'pending'),
          ),
          transaction: currentDatabaseSession(),
        ),
      );
      final download = Completer<void>();
      api.onDownload = (_) => download.future;
      await pumpViewer(tester);
      await pumpNative(tester, until: () => api.downloads.isNotEmpty);
      await tester.pumpWidget(const SizedBox());
      download.complete();
      await pumpNative(tester);
      expect(cached('image-1'), isFalse);
      expect(api.opened, [(7, 'message-0')]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('own stories preload without sending opened receipts', (
    tester,
  ) async {
    await runNative(
      tester,
      () => database.customStatement('UPDATE messages SET sender_id = NULL'),
    );
    await pumpViewer(tester, own: true);
    await pumpNative(
      tester,
      until: () => cached('image-1') && cached('image-2'),
    );
    expect(displayed(tester), 'image-0');
    expect(api.opened, isEmpty);
    expect(api.downloads, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
