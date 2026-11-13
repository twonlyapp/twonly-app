import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' show FaIcon;
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/bridge/database/stories.dart' as rust_stories;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';

import '../../helpers/native_database.dart';

void main() {
  late TestDatabase database;
  late Directory support;

  setUp(() async {
    support = Directory.systemTemp.createTempSync('story_preview_test');
    AppEnvironment.initTesting(customSupportDir: support.path);
    database = await TestDatabase.create();
    await database.customStatement(
      "INSERT INTO media_files(media_id, type) VALUES ('img', 'image'), ('vid', 'video')",
    );
  });

  tearDown(() async {
    support.deleteSync(recursive: true);
  });

  Future<MediaFile> media(String id) async => (await rust_mediafiles
      .getMediaFile(id: id, transaction: currentDatabaseSession()))!;

  /// The file behind the preview, past the downscaling it is loaded with.
  String shownFile(WidgetTester tester) {
    final image = tester.widget<Image>(find.byType(Image)).image;
    final resized = image as ResizeImage;
    return (resized.imageProvider as FileImage).file.path;
  }

  Future<void> pump(WidgetTester tester, MediaFile file, {Widget? badge}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: StoryPreview(
              mediaFile: file,
              width: 40,
              height: 40,
              badge: badge,
            ),
          ),
        ),
      );

  testWidgets('an image story is previewed from its own file', (
    tester,
  ) async {
    final image = await tester.runAsync(() => media('img'));
    await pump(tester, image!);
    expect(shownFile(tester), MediaFileService(image).tempPath.path);
  });

  testWidgets('a video story is previewed from its frame', (tester) async {
    final video = await tester.runAsync(() => media('vid'));
    await pump(tester, video!);
    expect(shownFile(tester), MediaFileService(video).thumbnailPath.path);
  });

  testWidgets('a story not downloaded yet shows a tile with its owner', (
    tester,
  ) async {
    // The file is not there, so loading it fails and the tile stands in.
    // Reading a file is real I/O, which only completes outside fake time.
    await tester.runAsync(() async {
      final image = await media('img');
      await pump(tester, image, badge: const Text('owner'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pump();
    expect(find.byType(FaIcon), findsOneWidget);
    expect(find.text('owner'), findsOneWidget);
  });

  testWidgets(
    'own story image appears after preparation without reopening the list',
    (tester) async {
      await runNative(tester, () async {
        await database.customStatement(
          "INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat')",
        );
        await database.customStatement(
          "UPDATE media_files SET upload_state = 'preprocessing' WHERE media_id = 'img'",
        );
        await database.customStatement(
          "INSERT INTO messages(message_id, group_id, type, media_id, is_story) VALUES ('own-story', 'chat', 'media', 'img', 1)",
        );
      });
      final stories = watchRustDatabase(
        (control) => rust_stories
            .watchOwnStories(cutoff: 0, control: control)
            .map(ownStoryItems),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: StreamBuilder<List<OwnStoryItem>>(
              stream: stories,
              builder: (context, snapshot) {
                final story = snapshot.data?.firstOrNull;
                if (story == null) return const SizedBox.shrink();
                return StoryPreview(
                  mediaFile: story.mediaFile,
                  width: 28,
                  height: 28,
                  circle: true,
                );
              },
            ),
          ),
        ),
      );
      await pumpNative(
        tester,
        until: () => find.byType(FaIcon).evaluate().isNotEmpty,
      );
      await runNative(tester, () async {
        final file = await media('img');
        await File(
          'assets/images/default_avatar.png',
        ).copy(MediaFileService(file).tempPath.path);
        await rust_mediafiles.updateMediaFiles(
          id: 'img',
          patch: const MediaFilePatch(
            uploadState: NullableText(value: 'backgroundUploadTaskStarted'),
          ),
          transaction: currentDatabaseSession(),
        );
      });
      await pumpNative(
        tester,
        until: () =>
            tester
                .widget<StoryPreview>(find.byType(StoryPreview))
                .mediaFile
                .uploadStateName ==
            'backgroundUploadTaskStarted',
      );
      await pumpNative(
        tester,
        until: () => find
            .byType(RawImage)
            .evaluate()
            .any((element) => (element.widget as RawImage).image != null),
      );
      expect(find.byType(FaIcon), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
