import 'package:flutter/services.dart';
import 'package:twonly/src/utils/log.dart';

abstract class VideoCompressionChannel {
  static const MethodChannel _channel =
      MethodChannel('eu.twonly/videoCompression');

  static void Function(double)? _currentProgressCallback;
  static bool _handlerSetup = false;

  static void _setupProgressHandler() {
    if (_handlerSetup) return;

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onProgress') {
        // ignore: avoid_dynamic_calls
        final progress = call.arguments['progress'] as int;
        _currentProgressCallback?.call(progress / 100.0);
      }
    });

    _handlerSetup = true;
  }

  static Future<String?> compressVideo({
    required String inputPath,
    required String outputPath,
    void Function(double progress)? onProgress,
  }) async {
    try {
      _setupProgressHandler();
      _currentProgressCallback = onProgress;
      await _channel.invokeMethod('compressVideo', {
        'input': inputPath,
        'output': outputPath,
      });
      return outputPath;
    } on PlatformException catch (e) {
      Log.error('Failed to compress video: $e');
      return null;
    } finally {
      _currentProgressCallback = null;
    }
  }
}
