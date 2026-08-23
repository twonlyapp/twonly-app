import 'package:twonly/core/bridge/callbacks.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/callbacks/logging.callbacks.dart';

Future<void> initFlutterCallbacksForRust() async {
  await initFlutterCallbacks(
    callbackId: isolateCallbackId,
    loggingGetStreamSink: LoggingCallbacks.getStreamSink,
  );
}
