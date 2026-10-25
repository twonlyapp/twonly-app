import 'dart:async';

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
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';

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
  setUpAll(() async {
    AppEnvironment.initTesting();
    await initializeNativeDatabase(api: api);
  });
  tearDownAll(RustLib.dispose);

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
    // Cleanup must also be safe when the editor closes before media finishes
    // loading. The deliberately missing source keeps its loading animation on.
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
}
