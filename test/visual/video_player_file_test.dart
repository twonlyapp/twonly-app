import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/visual/helpers/video_player_file.helper.dart';
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class _Players extends VideoPlayerPlatform {
  final created = Completer<int?>();
  final events = StreamController<VideoEvent>();
  Completer<void>? looping;
  final calls = <String>[];
  bool missing = false;

  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) =>
      created.future;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    if (missing) throw StateError('No active player with ID $playerId.');
    return events.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    calls.add('dispose');
  }

  @override
  Future<void> setLooping(int playerId, bool value) async {
    calls.add('loop');
    await looping?.future;
  }

  @override
  Future<void> play(int playerId) async {
    calls.add('play');
  }

  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
}

void main() {
  late VideoPlayerPlatform previous;
  late _Players players;
  setUp(() {
    previous = VideoPlayerPlatform.instance;
    players = _Players();
    VideoPlayerPlatform.instance = players;
  });
  tearDown(() async {
    unawaited(players.events.close());
    VideoPlayerPlatform.instance = previous;
  });
  Widget preview() =>
      MaterialApp(home: VideoPlayerFileHelper(videoPath: File('/video.mp4')));

  testWidgets(
    'late native creation after unmount has no unhandled player error',
    (tester) async {
      await tester.pumpWidget(preview());
      await tester.pumpWidget(const SizedBox());
      players.missing = true;
      players.created.complete(1);
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(players.calls, isNot(contains('play')));
    },
  );

  testWidgets(
    'unmount while configuring playback never starts the disposed player',
    (tester) async {
      players.looping = Completer<void>();
      await tester.pumpWidget(preview());
      players.created.complete(1);
      await tester.pump();
      players.events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 1),
          size: const Size(100, 100),
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      players.looping!.complete();
      await tester.pump();
      expect(players.calls, isNot(contains('play')));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unreadable video ends the spinner and shows a failure indicator',
    (tester) async {
      await tester.pumpWidget(preview());
      players.created.complete(1);
      await tester.pump();
      players.events.addError(
        PlatformException(code: 'VideoError', message: 'Cannot Open'),
      );
      await tester.pump();
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
