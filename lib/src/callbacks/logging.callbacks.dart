import 'dart:async';
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
            } else if (kDebugMode) {
              print(log);
            }
          },
          onDone: () => Log.error('Log stream closed'),
        );
        timer.cancel();
      } catch (e) {
        // stream not yet initialized
      }
    });

    return dartLogSink;
  }
}
