import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/editor_bottom_bar.dart';

import '../helpers/native_database.dart';
import '../mocks/user_config.dart';

class _EditorApi extends NativeTestApi {
  late Completer<void> updateFinished;

  @override
  Future<void> crateBridgeDatabaseMediafilesUpdateMediaFiles({
    required MediaFilePatch patch,
    required DatabaseSession transaction,
    String? id,
  }) async {
    try {
      await super.crateBridgeDatabaseMediafilesUpdateMediaFiles(
        id: id,
        patch: patch,
        transaction: transaction,
      );
    } finally {
      if (!updateFinished.isCompleted) updateFinished.complete();
    }
  }
}

void main() {
  final api = _EditorApi();
  late Directory files;
  setUpAll(() async {
    files = Directory.systemTemp.createTempSync('twonly-editor-');
    AppEnvironment.initTesting(
      customCacheDir: '${files.path}/cache',
      customSupportDir: '${files.path}/support',
    );
    await initializeNativeDatabase(api: api);
  });
  tearDownAll(() async {
    RustLib.dispose();
    files.deleteSync(recursive: true);
  });

  setUp(() async {
    api.updateFinished = Completer<void>();
    await locator.reset();
    locator.registerSingleton<UserService>(
      UserService()
        ..currentUser = testUserConfig(
          userId: 1,
          username: 'me',
          displayName: 'Me',
          subscriptionPlan: 'Free',
          currentSetupPage: null,
          appVersion: 193,
        ),
    );
    await TestDatabase.create();
    await testDatabase.customStatement(
      'INSERT INTO media_files(media_id, type, is_draft_media) VALUES '
      "('edited', 'gif', 1), ('another-draft', 'gif', 1), ('finished', 'image', 0)",
    );
  });
  tearDown(() async => locator.reset());

  Future<List<(String, int)>> drafts() async => [
    for (final row
        in await testDatabase
            .customSelect(
              'SELECT media_id, is_draft_media FROM media_files ORDER BY media_id',
            )
            .get())
      (row.read<String>('media_id'), row.read<int>('is_draft_media')),
  ];

  test('omitting the media ID is rejected without changing any rows', () async {
    final before = await drafts();
    await expectLater(
      rust_mediafiles.updateMediaFiles(
        patch: const MediaFilePatch(isDraftMedia: false),
        transaction: currentDatabaseSession(),
      ),
      throwsA(
        predicate<Object>(
          (error) => error.toString().contains('A media ID is required'),
        ),
      ),
    );
    expect(await drafts(), before);
  });

  testWidgets('disposing the editor releases only its own draft', (
    tester,
  ) async {
    final edited = await runNative(
      tester,
      () => rust_mediafiles.getMediaFile(
        id: 'edited',
        transaction: currentDatabaseSession(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShareImageEditorView(
          sharedFromGallery: false,
          mediaFileService: MediaFileService(edited!),
        ),
      ),
    );
    // Cleanup must also be safe when the source image is missing.
    await tester.pump();
    expect(find.byType(ShareImageEditorView), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpNative(tester, until: () => api.updateFinished.isCompleted);
    expect(await runNative(tester, drafts), [
      ('another-draft', 1),
      ('edited', 0),
      ('finished', 0),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a damaged image shows recovery controls and retries fresh bytes',
    (
      tester,
    ) async {
      final source = File('${files.path}/damaged.png')
        ..writeAsBytesSync([0, 1, 2, 3]);
      final edited = await runNative(
        tester,
        () => rust_mediafiles.getMediaFile(
          id: 'edited',
          transaction: currentDatabaseSession(),
        ),
      );
      final media = MediaFileService(edited!);
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ShareImageEditorView(
            sharedFromGallery: true,
            mediaFileService: media,
            screenshotImage: ScreenshotImageHelper(file: source),
          ),
        ),
      );
      await pumpNative(
        tester,
        until: () => find.text('Try again').evaluate().isNotEmpty,
      );
      expect(find.text('Could not load this image.'), findsOneWidget);
      expect(find.byType(EditorBottomBar), findsNothing);
      expect(media.originalPath.existsSync(), isFalse);
      expect(tester.takeException(), isNull);

      final valid = File('assets/images/default_avatar.png').readAsBytesSync();
      source.writeAsBytesSync(valid);
      await tester.tap(find.text('Try again'));
      await pumpNative(
        tester,
        until: () =>
            find.byType(EditorBottomBar).evaluate().isNotEmpty &&
            !tester
                .widget<EditorBottomBar>(find.byType(EditorBottomBar))
                .isSending,
      );
      expect(find.text('Could not load this image.'), findsNothing);
      expect(media.originalPath.readAsBytesSync(), valid);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpNative(tester, until: () => api.updateFinished.isCompleted);
      await tester.pump(const Duration(seconds: 1));
    },
  );

  testWidgets('closing before image bytes arrive does not persist a draft', (
    tester,
  ) async {
    final bytes = Completer<Uint8List>();
    final edited = await runNative(
      tester,
      () => rust_mediafiles.getMediaFile(
        id: 'edited',
        transaction: currentDatabaseSession(),
      ),
    );
    final media = MediaFileService(edited!);
    final before = media.originalPath.existsSync()
        ? media.originalPath.readAsBytesSync()
        : null;
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ShareImageEditorView(
          sharedFromGallery: true,
          mediaFileService: media,
          screenshotImage: ScreenshotImageHelper(
            imageBytesFuture: bytes.future,
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    bytes.complete(File('assets/images/default_avatar.png').readAsBytesSync());
    await pumpNative(tester, until: () => api.updateFinished.isCompleted);
    await tester.pump(const Duration(seconds: 1));
    expect(
      media.originalPath.existsSync()
          ? media.originalPath.readAsBytesSync()
          : null,
      before,
    );
    expect(tester.takeException(), isNull);
  });
}
