import 'dart:io';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/story_bubble_strip.comp.dart';

void main() {
  late TwonlyDB database;
  late Directory support;
  late MediaFile media;

  setUp(() async {
    support = Directory.systemTemp.createTempSync('story_bubbles_test');
    AppEnvironment.initTesting(customSupportDir: support.path);
    database = TwonlyDB(NativeDatabase.memory());
    await database.customStatement(
      "INSERT INTO media_files(media_id, type) VALUES ('story', 'image')",
    );
    media = (await database.mediaFilesDao.getMediaFileById('story'))!;
  });

  tearDown(() async {
    await database.close();
    support.deleteSync(recursive: true);
  });

  StoryItem story({
    required int senderId,
    required String messageId,
    required DateTime postedAt,
    bool seen = false,
  }) => StoryItem(
    message: Message(
      groupId: 'group-$senderId',
      messageId: messageId,
      senderId: senderId,
      type: 'media',
      mediaId: media.mediaId,
      mediaStored: false,
      mediaReopened: false,
      isDeletedFromSender: false,
      isWidgetMedia: false,
      isStory: true,
      openedAt: seen ? postedAt.add(const Duration(minutes: 1)) : null,
      createdAt: postedAt,
    ),
    mediaFile: media,
  );

  test('only active unseen contacts get a bubble', () {
    final now = DateTime(2026, 10, 6, 12);
    final items = buildStoryBubbleItems(
      stories: [
        story(
          senderId: 1,
          messageId: 'first-old',
          postedAt: now.subtract(const Duration(hours: 2)),
        ),
        story(
          senderId: 1,
          messageId: 'first-new',
          postedAt: now.subtract(const Duration(hours: 1)),
        ),
        story(
          senderId: 2,
          messageId: 'second',
          postedAt: now.subtract(const Duration(minutes: 30)),
        ),
        story(
          senderId: 3,
          messageId: 'opened',
          postedAt: now.subtract(const Duration(minutes: 10)),
          seen: true,
        ),
        story(
          senderId: 4,
          messageId: 'expired',
          postedAt: now.subtract(const Duration(hours: 25)),
        ),
      ],
      labelFor: (story) => 'Contact ${story.senderId}',
      now: now,
    );

    expect(items.map((item) => item.story.message.messageId), [
      'second',
      'first-old',
    ]);
    expect(items.map((item) => item.label), ['Contact 2', 'Contact 1']);
  });

  testWidgets('shows a circular preview with remaining-time progress', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 6, 12);
    final item = StoryBubbleItem(
      story: story(
        senderId: 1,
        messageId: 'half-life',
        postedAt: now.subtract(const Duration(hours: 12)),
      ),
      label: 'Anna',
    );
    StoryBubbleItem? tapped;

    await withClock(Clock.fixed(now), () async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoryBubbleStrip(
              items: [item],
              onTap: (item) => tapped = item,
            ),
          ),
        ),
      );

      expect(find.text('Anna'), findsOneWidget);
      expect(
        tester.widget<StoryPreview>(find.byType(StoryPreview)).circle,
        true,
      );
      final progress = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progress.value, closeTo(0.5, 0.001));
      expect(
        tester.getSize(find.byType(CircularProgressIndicator)),
        const Size.square(64),
      );
      expect(progress.strokeWidth, 1.5);

      await tester.tap(find.byKey(const ValueKey(1)));
      expect(tapped, same(item));
      await tester.pumpWidget(const SizedBox());
    });
  });
}
