import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:twonly/src/utils/log.dart';

class LoggingCallbacks {
  static Future<RustStreamSink<String>> getStreamSink() async {
    final dartLogSink = RustStreamSink<String>();

    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      try {
        dartLogSink.stream.listen(
          (log) {
            if (log.contains('INFO ')) {
              Log.info(log.split('INFO ')[1]);
            } else if (log.contains('DEBUG ')) {
              Log.info(log.split('DEBUG ')[1]);
            } else if (kDebugMode && !Platform.environment.containsKey('FLUTTER_TEST')) {
              // ignore: avoid_print
              print(log);
            }
          },
        );
        timer.cancel();
      } catch (e) {
        // stream not yet initialized
      }
    });

    return dartLogSink;
  }
}
