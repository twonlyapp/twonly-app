import 'package:twonly/core/bridge/callbacks.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/callbacks/logging.callbacks.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/services/user.service.dart';

Future<void> initFlutterCallbacksForRust() async {
  await initFlutterCallbacks(
    callbackId: isolateCallbackId,
    loggingGetStreamSink: LoggingCallbacks.getStreamSink,
    apiVerificationSucceeded:
        KeyVerificationService.handleVerificationSucceeded,
    apiUserConfigChanged: UserService.handleRustUserConfigChanged,
  );
}
