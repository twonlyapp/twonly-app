import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/visual/views/camera/camera_preview_components/video_recording_budget.dart';

void main() {
  late Directory tempDir;

  const hd = Size(1280, 720);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('twonly_video_budget_test_');
    AppEnvironment.initTesting(
      customCacheDir: tempDir.path,
      customSupportDir: tempDir.path,
    );
    VideoRecordingBudget.resetForTesting();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  Duration budgetFor(SubscriptionPlan plan, {Size? size = hd}) =>
      VideoRecordingBudget.maxRecordingTime(
        plan: plan,
        recordingSize: size,
        hasAudio: true,
      );

  group('VideoRecordingBudget', () {
    test('a paid plan may record twice as long as the free plan', () {
      final free = budgetFor(SubscriptionPlan.Free);
      final pro = budgetFor(SubscriptionPlan.Pro);

      expect(pro.inMilliseconds, greaterThan(free.inMilliseconds));
      expect(pro.inMilliseconds, closeTo(2 * free.inMilliseconds, 1));
      // Every paid plan shares the same per-file limit.
      expect(budgetFor(SubscriptionPlan.Family), pro);
      expect(budgetFor(SubscriptionPlan.Tester), pro);
    });

    test('without a measurement the estimate stays under the plan limit', () {
      final free = budgetFor(SubscriptionPlan.Free);
      // 720p30 at the assumed 0.25 bits per pixel plus AAC is 880 kB/s, so
      // 50 MB is reached just after 51 seconds even before the headroom.
      expect(free.inSeconds, inInclusiveRange(45, 60));
    });

    test('an unknown recording size falls back to 720p', () {
      expect(
        budgetFor(SubscriptionPlan.Free, size: null),
        budgetFor(SubscriptionPlan.Free),
      );
      expect(
        budgetFor(SubscriptionPlan.Free, size: Size.zero),
        budgetFor(SubscriptionPlan.Free),
      );
    });

    test('a bigger recording size shortens the budget', () {
      final hdBudget = budgetFor(SubscriptionPlan.Free);
      final fullHdBudget = budgetFor(
        SubscriptionPlan.Free,
        size: const Size(1920, 1080),
      );
      expect(fullHdBudget.inMilliseconds, lessThan(hdBudget.inMilliseconds));
    });

    test('a measured recording replaces the estimate', () async {
      // The 18 MB per minute a real device wrote.
      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 18000000,
        duration: const Duration(seconds: 60),
        recordingSize: hd,
      );

      // 50 MB minus headroom at 300 kB/s.
      expect(budgetFor(SubscriptionPlan.Free).inSeconds, 150);
      // 100 MB would allow 300s, which the ceiling caps at five minutes.
      expect(budgetFor(SubscriptionPlan.Pro), const Duration(minutes: 5));
    });

    test('the measurement is reused after a restart', () async {
      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 18000000,
        duration: const Duration(seconds: 60),
        recordingSize: hd,
      );
      final beforeRestart = budgetFor(SubscriptionPlan.Free);

      VideoRecordingBudget.resetForTesting();
      // Nothing loaded yet, so the pessimistic estimate is what is on offer.
      expect(budgetFor(SubscriptionPlan.Free), lessThan(beforeRestart));

      await VideoRecordingBudget.ensureLoaded();
      expect(budgetFor(SubscriptionPlan.Free), beforeRestart);
    });

    test('the measurement is kept per resolution', () async {
      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 18000000,
        duration: const Duration(seconds: 60),
        recordingSize: hd,
      );

      // A rotated preview size is the same recording.
      expect(
        budgetFor(SubscriptionPlan.Free, size: const Size(720, 1280)),
        budgetFor(SubscriptionPlan.Free),
      );
      // A different recording size has not been measured.
      expect(
        budgetFor(SubscriptionPlan.Free, size: const Size(1920, 1080)),
        lessThan(budgetFor(SubscriptionPlan.Free)),
      );
    });

    test('a higher rate is adopted at once, a lower one eases in', () async {
      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 18000000,
        duration: const Duration(seconds: 60),
        recordingSize: hd,
      );
      final atThreeHundredKilobytes = budgetFor(SubscriptionPlan.Free);

      // A busier scene writing 600 kB/s halves the budget immediately.
      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 36000000,
        duration: const Duration(seconds: 60),
        recordingSize: hd,
      );
      expect(budgetFor(SubscriptionPlan.Free).inSeconds, 75);

      // A still scene writing 300 kB/s again does not hand the budget straight
      // back: 600 kB/s eased towards 300 kB/s is 540 kB/s.
      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 18000000,
        duration: const Duration(seconds: 60),
        recordingSize: hd,
      );
      final eased = budgetFor(SubscriptionPlan.Free);
      expect(eased.inSeconds, 83);
      expect(eased, lessThan(atThreeHundredKilobytes));
    });

    test('a recording too short to divide by is ignored', () async {
      final estimated = budgetFor(SubscriptionPlan.Free);

      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 400000,
        duration: const Duration(milliseconds: 300),
        recordingSize: hd,
      );
      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 0,
        duration: const Duration(seconds: 30),
        recordingSize: hd,
      );

      expect(budgetFor(SubscriptionPlan.Free), estimated);
    });

    test('an implausible rate is still left usable', () async {
      await VideoRecordingBudget.recordMeasurement(
        fileSizeInBytes: 500000000,
        duration: const Duration(seconds: 5),
        recordingSize: hd,
      );
      expect(budgetFor(SubscriptionPlan.Free), const Duration(seconds: 10));
    });
  });
}
