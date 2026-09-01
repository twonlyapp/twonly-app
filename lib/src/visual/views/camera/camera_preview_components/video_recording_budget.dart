import 'dart:ui' show Size;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';

/// How long the camera may keep recording before the file outgrows the largest
/// single object the user's plan lets them upload.
///
/// A recorded video is sent exactly as the camera wrote it: nothing re-encodes
/// it between the recorder and the upload, and the upload encrypts in place,
/// so the recorder's output size *is* the size the server measures against
/// `maximal_upload_size_of_single_media_size`. That makes the recording budget
/// a plain division: plan limit divided by the rate the encoder writes at.
///
/// The rate is the part that cannot be known up front. Both platforms record
/// `ResolutionPreset.high`, which is 720p, but what an encoder spends on those
/// pixels differs by a factor of several between devices - the same minute
/// that costs 18 MB on one phone costs far more on a phone whose camcorder
/// profile asks for a high bitrate. So the first recording on a device is
/// budgeted from a deliberately pessimistic estimate, and every recording
/// after that is budgeted from what this device actually wrote.
abstract final class VideoRecordingBudget {
  /// Mirrors `maximal_upload_size_of_single_media_size` of the server's plans.
  /// Every paid plan shares the same per-file limit.
  static const int freePlanUploadLimitBytes = 50000000;
  static const int paidPlanUploadLimitBytes = 100000000;

  /// Bits the encoder is assumed to spend per pixel per frame before this
  /// device has recorded anything. Devices measured so far sit well below
  /// this; guessing high only costs a shorter first recording, while guessing
  /// low costs a recording the server refuses once it is already made.
  static const double _assumedBitsPerPixel = 0.25;

  /// Neither platform reports the recording frame rate, and both record at
  /// 30 fps unless the scene is too dark for it.
  static const double _assumedFrameRate = 30;

  /// AAC alongside the video, when the microphone is available.
  static const double _audioBitsPerSecond = 128000;

  /// Falls back to 720p when the camera has not reported its preview size.
  static const Size _assumedRecordingSize = Size(1280, 720);

  /// Leaves the container overhead and a scene busier than the one that was
  /// measured somewhere to go.
  static const double _headroom = 0.9;

  /// A budget shorter than this makes the camera useless, and one longer than
  /// this makes an unwieldy file however well it fits the plan.
  static const Duration _shortestBudget = Duration(seconds: 10);
  static const Duration _longestBudget = Duration(minutes: 5);

  static const String _storeKey = 'video_recording_bitrate';
  static const String _samplesField = 'bytesPerSecondByResolution';

  /// Measured write rates in bytes per second, keyed by recording resolution
  /// so that a different camera or preset does not inherit a rate that was
  /// never measured for it.
  static Map<String, double> _measured = {};
  static bool _loaded = false;

  static int uploadLimitBytesFor(SubscriptionPlan plan) =>
      plan == SubscriptionPlan.Free
      ? freePlanUploadLimitBytes
      : paidPlanUploadLimitBytes;

  /// Reads back what earlier recordings measured. Cheap to call repeatedly;
  /// the camera view calls it while it is starting up, long before the first
  /// recording can be started.
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final stored = await KeyValueStore.get(_storeKey);
      final samples = stored?[_samplesField];
      if (samples is Map) {
        _measured = {
          for (final entry in samples.entries)
            if (entry.value is num)
              entry.key.toString(): (entry.value as num).toDouble(),
        };
      }
    } catch (e) {
      Log.warn('Could not read the measured video bitrate: $e');
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _measured = {};
    _loaded = false;
  }

  /// How long the camera may record for [plan] before the file would no longer
  /// be uploadable.
  static Duration maxRecordingTime({
    required SubscriptionPlan plan,
    required Size? recordingSize,
    required bool hasAudio,
  }) {
    final bytesPerSecond = _bytesPerSecond(
      recordingSize: recordingSize,
      hasAudio: hasAudio,
    );
    final seconds = (uploadLimitBytesFor(plan) * _headroom) / bytesPerSecond;
    final budget = Duration(milliseconds: (seconds * 1000).round());
    if (budget < _shortestBudget) return _shortestBudget;
    if (budget > _longestBudget) return _longestBudget;
    return budget;
  }

  /// Feeds back what the encoder really wrote, so the next recording on this
  /// device is budgeted from a measurement instead of the estimate.
  ///
  /// A rate above the one on record is adopted at once - it is proof the
  /// budget in use was too generous - while a lower one is eased in, because a
  /// single still scene encodes far smaller than the device's usual output and
  /// should not talk the budget up.
  static Future<void> recordMeasurement({
    required int fileSizeInBytes,
    required Duration duration,
    required Size? recordingSize,
  }) async {
    // Too short to divide by: the fixed cost of the container and the first
    // key frame would swamp the rate.
    if (duration.inMilliseconds < 2000 || fileSizeInBytes <= 0) return;

    await ensureLoaded();

    final key = _resolutionKey(recordingSize);
    final observed = fileSizeInBytes / (duration.inMilliseconds / 1000);
    final previous = _measured[key];
    final updated = (previous == null || observed > previous)
        ? observed
        : previous * 0.8 + observed * 0.2;

    _measured[key] = updated;
    try {
      await KeyValueStore.put(_storeKey, {_samplesField: _measured});
    } catch (e) {
      Log.warn('Could not store the measured video bitrate: $e');
    }
  }

  static double _bytesPerSecond({
    required Size? recordingSize,
    required bool hasAudio,
  }) {
    final measured = _measured[_resolutionKey(recordingSize)];
    if (measured != null && measured > 0) return measured;

    final size = _sizeOrDefault(recordingSize);
    final videoBitsPerSecond =
        _assumedBitsPerPixel * size.width * size.height * _assumedFrameRate;
    final bitsPerSecond =
        videoBitsPerSecond + (hasAudio ? _audioBitsPerSecond : 0);
    return bitsPerSecond / 8;
  }

  static Size _sizeOrDefault(Size? recordingSize) {
    if (recordingSize == null ||
        recordingSize.width <= 0 ||
        recordingSize.height <= 0) {
      return _assumedRecordingSize;
    }
    return recordingSize;
  }

  /// Orientation is not part of the key: the camera reports the preview size
  /// rotated on one platform and not on the other, and only the pixel count
  /// matters here.
  static String _resolutionKey(Size? recordingSize) {
    final size = _sizeOrDefault(recordingSize);
    final shorter = size.shortestSide.round();
    final longer = size.longestSide.round();
    return '${longer}x$shorter';
  }
}
