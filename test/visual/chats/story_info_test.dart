import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/elements/my_icon_button.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/media_viewer.view.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/own_story_bottom_bar.comp.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_viewers.bottom_sheet.dart';

import '../../helpers/native_database.dart';

class _StoryApi extends NativeTestApi {
  final deleted = <String>[];

  @override
  Future<String?> crateBridgeApiRustApiEnsureAvatarPng({
    required int contactId,
  }) async => File('assets/images/default_avatar.png').absolute.path;

  @override
  Future<void> crateBridgeStoriesDeleteStoryItem({
    required String mediaId,
  }) async {
    deleted.add(mediaId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _StoryApi();
  late TestDatabase database;
  late Directory directory;
  late MediaFile media;

  setUpAll(() => initializeNativeDatabase(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    api.deleted.clear();
    directory = await Directory.systemTemp.createTemp('story-info-');
    AppEnvironment.initTesting(customSupportDir: directory.path);
    database = await TestDatabase.create();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final statement in [
      "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'Opened friend', 1), (8, 'Received friend', 1), (9, 'Pending friend', 1)",
      "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('a', 'A', 1), ('b', 'B', 1), ('c', 'C', 1)",
      "INSERT INTO group_members(group_id, contact_id) VALUES ('a', 7), ('b', 8), ('c', 9)",
      "INSERT INTO media_files(media_id, type, upload_state) VALUES ('story', 'image', 'preprocessing')",
      "INSERT INTO messages(message_id, group_id, type, media_id, is_story) VALUES ('s7', 'a', 'media', 'story', 1), ('s8', 'b', 'media', 'story', 1), ('s9', 'c', 'media', 'story', 1)",
      "INSERT INTO message_actions(message_id, contact_id, type, action_at) VALUES ('s7', 7, 'openedAt', $now), ('s8', 8, 'ackByUserAt', $now)",
    ]) {
      await database.customStatement(statement);
    }
    media = (await rust_mediafiles.getMediaFile(
      id: 'story',
      transaction: currentDatabaseSession(),
    ))!;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('screen_protector'),
          (_) async => null,
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('screen_protector'),
          null,
        );

    await locator.reset();
    await directory.delete(recursive: true);
    AppEnvironment.initTesting();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
    await settle(tester);
  }

  testWidgets(
    'story info shows received, opened and pending recipients on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pump(tester, StoryViewersBottomSheet(mediaFile: media));
      expect(find.text('Opened friend'), findsOneWidget);
      expect(find.text('Received friend'), findsOneWidget);
      expect(find.text('Pending friend'), findsOneWidget);
      expect(find.text('Received (2)'), findsOneWidget);
      expect(find.text('Opened (1)'), findsOneWidget);
      expect(find.text('Received: —'), findsOneWidget);
      expect(find.text('Opened: —'), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      // Receipt updates are shown while the sheet stays open.
      await tester.runAsync(
        () => database.customUpdate(
          "INSERT INTO message_actions(message_id, contact_id, type) VALUES ('s9', 9, 'ackByUserAt')",
        ),
      );
      await settle(tester);
      expect(find.text('Received (3)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('an unfinished story can be deleted from its info', (
    tester,
  ) async {
    await pump(tester, StoryViewersBottomSheet(mediaFile: media));
    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete story?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(api.deleted, ['story']);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('an unfinished story can be deleted from the viewer toolbar', (
    tester,
  ) async {
    var deleted = false;
    await pump(
      tester,
      OwnStoryBottomBar(
        mediaFile: media,
        onDeleted: () async {
          deleted = true;
        },
      ),
    );
    await tester.tap(find.byType(MyIconButton).last);
    await tester.pumpAndSettle();
    expect(find.text('Delete story?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(api.deleted, ['story']);
    expect(deleted, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'a sent story stays deletable when upload finishes with the viewer open',
    (tester) async {
      await tester.runAsync(() async {
        await database.customUpdate(
          "UPDATE media_files SET upload_state = 'backgroundUploadTaskStarted' WHERE media_id = 'story'",
        );
        final localMedia = MediaFileService(media);
        await File(
          'assets/images/default_avatar.png',
        ).copy(localMedia.tempPath.path);
      });
      await pump(tester, const MediaViewerView.story(StorySource.own()));
      await pumpNative(
        tester,
        until: () => find.byType(OwnStoryBottomBar).evaluate().isNotEmpty,
      );
      expect(find.byType(OwnStoryBottomBar), findsOneWidget);

      await tester.runAsync(
        () => database.customUpdate(
          "UPDATE media_files SET upload_state = 'uploaded' WHERE media_id = 'story'",
        ),
      );
      await settle(tester);
      await tester.tap(find.byType(MyIconButton).last);
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Delete story?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pump(const Duration(milliseconds: 350));
      expect(api.deleted, ['story']);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
