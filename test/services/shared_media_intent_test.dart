import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/services/intent/links.intent.dart';

void main() {
  late Level previousLogLevel;
  late StreamSubscription<LogRecord> subscription;
  late List<LogRecord> records;

  setUp(() {
    previousLogLevel = Logger.root.level;
    Logger.root.level = Level.ALL;
    records = [];
    subscription = Logger.root.onRecord.listen(records.add);
  });

  tearDown(() async {
    Logger.root.level = previousLogLevel;
    await subscription.cancel();
  });

  for (final (description, value) in [
    ('null', null),
    ('empty', ''),
    ('whitespace', ' \t\n'),
  ]) {
    testWidgets('skips $description shared values without reporting errors', (
      tester,
    ) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (builderContext) {
              context = builderContext;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final receivedMedia = <(String, MediaType)>[];
      await handleIntentSharedFile(
        context,
        [
          for (final type in [
            SharedMediaType.URL,
            SharedMediaType.IMAGE,
            SharedMediaType.VIDEO,
          ])
            SharedFile(value: value, type: type),
          SharedFile(value: '/shared/photo.jpg', type: SharedMediaType.IMAGE),
          SharedFile(value: '/shared/video.mp4', type: SharedMediaType.VIDEO),
        ],
        (_) async => fail('Empty shared URLs must not be handled'),
        (path, type) => receivedMedia.add((path, type)),
      );

      expect(receivedMedia, [('/shared/photo.jpg', MediaType.image)]);
      expect(
        records.where((record) => record.level >= Level.SEVERE),
        isEmpty,
      );
      expect(
        records.where((record) => record.level == Level.WARNING),
        hasLength(3),
      );
    });
  }
}
