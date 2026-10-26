import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/src/services/audio_playback.service.dart';
import 'package:twonly/src/utils/audio_player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('simform_audio_waveforms_plugin/methods');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets(
    'released waveform codec still permits complete player disposal',
    (
      tester,
    ) async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'stopExtraction') {
          throw PlatformException(
            code: 'error',
            message: 'codec is released already',
          );
        }
        return true;
      });
      final controller = AudioPlayerController()..dispose();
      await tester.pump();

      expect(calls.map((call) => call.method), [
        'releasePlayer',
        'stopExtraction',
      ]);
      expect(() => controller.addListener(() {}), throwsFlutterError);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('detaching during extraction waits before releasing the player', (
    tester,
  ) async {
    final extracted = Completer<List<double>>();
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'getDuration') return 1000;
      if (call.method == 'extractWaveformData') return extracted.future;
      return true;
    });
    final playback = AudioPlaybackService.instance.attach(
      '/pending-extraction.m4a',
      noOfSamples: 2,
    );
    await tester.pump();
    expect(calls, contains('extractWaveformData'));
    AudioPlaybackService.instance.detach(playback);
    await tester.pump(const Duration(milliseconds: 500));
    expect(calls, isNot(contains('releasePlayer')));
    expect(calls, isNot(contains('stopExtraction')));

    extracted.complete([0.2, 0.5]);
    await tester.pump();
    expect(calls, containsAllInOrder(['releasePlayer', 'stopExtraction']));
    expect(() => playback.controller.addListener(() {}), throwsFlutterError);
    expect(tester.takeException(), isNull);
  });

  test(
    'waveform extraction retains the player identity and sample count',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == 'extractWaveformData') return <double>[0.2, 0.5];
        return true;
      });
      final controller = AudioPlayerController();
      expect(
        await controller.waveformExtraction.extractWaveformData(
          path: '/audio.m4a',
          noOfSamples: 2,
        ),
        [0.2, 0.5],
      );
      expect(
        (calls.single.arguments as Map)['playerKey'],
        controller.playerKey,
      );
      expect((calls.single.arguments as Map)['noOfSamples'], 2);
      controller.dispose();
      await Future<void>.delayed(Duration.zero);
    },
  );

  test('unrelated waveform failures remain visible', () async {
    final failure = PlatformException(code: 'error', message: 'decoder failed');
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'stopExtraction') throw failure;
      return true;
    });
    final controller = AudioPlayerController();
    await expectLater(
      controller.waveformExtraction.stopWaveformExtraction(),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.message,
          'message',
          failure.message,
        ),
      ),
    );
    messenger.setMockMethodCallHandler(channel, (_) async => true);
    controller.dispose();
    await Future<void>.delayed(Duration.zero);
  });
}
