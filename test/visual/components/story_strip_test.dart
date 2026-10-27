import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/globals.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';
import 'package:twonly/src/visual/components/story_strip.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/last_message_time.comp.dart';

import '../../helpers/native_database.dart';

void main() {
  late TestDatabase database;
  late Directory support;

  setUp(() async {
    support = Directory.systemTemp.createTempSync('story_strip_test');
    AppEnvironment.initTesting(customSupportDir: support.path);
    database = await TestDatabase.create();
    await database.customStatement(
      "INSERT INTO media_files(media_id, type) VALUES ('new', 'image'), ('old', 'video')",
    );
  });

  tearDown(() async {
    support.deleteSync(recursive: true);
  });

  Future<List<StoryStripItem>> items(WidgetTester tester) async {
    final files = await tester.runAsync(
      () async => [
        (await rust_mediafiles.getMediaFile(
          id: 'new',
          transaction: currentDatabaseSession(),
        ))!,
        (await rust_mediafiles.getMediaFile(
          id: 'old',
          transaction: currentDatabaseSession(),
        ))!,
      ],
    );
    final now = DateTime.now();
    return [
      StoryStripItem(
        mediaFile: files![0],
        postedAt: now.subtract(const Duration(minutes: 5)),
        viewerCount: 3,
      ),
      StoryStripItem(
        mediaFile: files[1],
        postedAt: now.subtract(const Duration(hours: 3)),
        viewerCount: 3,
      ),
    ];
  }

  Future<void> pump(
    WidgetTester tester,
    List<StoryStripItem> items, {
    ValueChanged<StoryStripItem>? onTap,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StoryStrip(
          title: 'Story',
          items: items,
          onTap: onTap ?? (_) {},
        ),
      ),
    ),
  );

  // The time labels tick; taking the strip down stops them.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('without a story the strip takes no room', (tester) async {
    await pump(tester, const []);
    expect(find.text('Story'), findsNothing);
    expect(find.byType(StoryPreview), findsNothing);
  });

  testWidgets('items show how many viewed them', (tester) async {
    await pump(tester, await items(tester));
    expect(find.text('3'), findsNWidgets(2));
    // The time takes all the width the count leaves, not a share of it.
    final label = tester.getSize(find.byType(LastMessageTimeComp).first);
    final count = tester.getSize(
      find.ancestor(of: find.text('3').first, matching: find.byType(Row)).first,
    );
    expect(label.width + count.width, closeTo(72, 0.5));
    await unmount(tester);
  });

  testWidgets('tapping an item hands it back', (tester) async {
    StoryStripItem? tapped;
    await pump(tester, await items(tester), onTap: (item) => tapped = item);
    await tester.tap(find.byType(StoryPreview).last);
    expect(tapped?.mediaFile.mediaId, 'old');
    await unmount(tester);
  });
}
