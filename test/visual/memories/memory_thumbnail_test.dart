import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/visual/views/memories/components/memory_thumbnail.comp.dart';

void main() {
  late Directory supportDir;
  var thumbnailRequests = 0;

  setUp(() {
    supportDir = Directory.systemTemp.createTempSync('twonly_thumbnail_test_');
    AppEnvironment.initTesting(
      customCacheDir: supportDir.path,
      customSupportDir: supportDir.path,
    );
    thumbnailRequests = 0;
    // Stands in for a video the platform cannot create a thumbnail for.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('pro_video_editor'), (
          call,
        ) async {
          if (call.method != 'getThumbnails') return null;
          thumbnailRequests++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return <Uint8List>[];
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('pro_video_editor'),
          null,
        );
    supportDir.deleteSync(recursive: true);
  });

  testWidgets('does not retry a video thumbnail that cannot be created', (
    tester,
  ) async {
    final media = MediaFileService(
      MediaFile(
        mediaId: 'video-without-thumbnail',
        type: MediaType.video,
        cloudState: CloudState.none,
        requiresAuthentication: false,
        stored: true,
        isDraftMedia: false,
        isFavorite: false,
        hasCropAnalyzed: false,
        hasThumbnail: false,
        createdAt: DateTime(2026, 9, 24),
      ),
    );
    media.storedPath.writeAsBytesSync([1, 2, 3]);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 120,
          height: 200,
          child: MemoriesThumbnailComp(
            galleryItem: MemoryItem(mediaService: media, messages: []),
            onTap: () {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(thumbnailRequests, 1);
    expect(media.thumbnailPath.existsSync(), isFalse);
  });
}
