import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart' show FaIcon;
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';

void main() {
  late TwonlyDB database;
  late Directory support;

  setUp(() async {
    support = Directory.systemTemp.createTempSync('story_preview_test');
    AppEnvironment.initTesting(customSupportDir: support.path);
    database = TwonlyDB(NativeDatabase.memory());
    await database.customStatement(
      "INSERT INTO media_files(media_id, type) VALUES ('img', 'image'), ('vid', 'video')",
    );
  });

  tearDown(() async {
    await database.close();
    support.deleteSync(recursive: true);
  });

  Future<MediaFile> media(String id) async =>
      (await database.mediaFilesDao.getMediaFileById(id))!;

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
}
