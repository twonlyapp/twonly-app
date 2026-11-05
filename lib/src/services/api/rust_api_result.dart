import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:twonly/src/model/error_code.dart';
import 'package:twonly/src/utils/log.dart';

export 'package:twonly/src/model/error_code.dart';

class Result<T, E> {
  Result.error(this.error, {this.cause}) : value = null, _isSuccess = false;
  Result.success(this.value) : error = null, cause = null, _isSuccess = true;

  final T? value;
  final E? error;

  /// The original exception when the call failed without a server error
  /// code, for example on the connection or in local Rust code.
  final Object? cause;
  final bool _isSuccess;

  bool get isSuccess => _isSuccess;
  bool get isError => !_isSuccess;
}

/// The server error code a failed Rust API call carries, or null when it
/// failed for another reason, such as the connection.
int? apiErrorCodeOf(Object error) {
  final match = RegExp(r'API error code (\d+)').firstMatch(error.toString());
  return match == null ? null : int.parse(match.group(1)!);
}

/// Whether a failed Rust API call never got an answer from the server: the
/// WebSocket was not connected, sending failed, or the response timed out.
bool isConnectionError(Object error) {
  if (error is! AnyhowException) return false;
  final message = error.message;
  return message == 'Not connected' ||
      message == 'API request timed out' ||
      message == 'response channel closed' ||
      message.startsWith('send error:');
}

Future<Result<T, ErrorCode>> rustApiResult<T>(Future<T> request) async {
  try {
    return Result.success(await request);
  } catch (error) {
    final code = apiErrorCodeOf(error);
    if (code != null) {
      return Result.error(ErrorCode.valueOf(code));
    }
    if (isConnectionError(error) || isBackgroundCancellation(error)) {
      Log.warn('Rust API call deferred', error);
    } else {
      Log.error('Rust API call failed', error: error);
    }
    return Result.error(ErrorCode.InternalError, cause: error);
  }
}

/// Starts a Rust API call that nothing waits on.
///
/// Anything crossing the bridge can fail on transport alone — the WebSocket is
/// still connecting at startup, or it drops mid-request — and a rejected future
/// with no listener surfaces as an unhandled exception in the root zone. These
/// calls are all retried by Rust or repeated by the next tick, so the failure
/// only has to be logged.
void unawaitedRustCall(Future<void> request, String description) {
  unawaited(
    request.catchError((Object error, StackTrace stackTrace) {
      if (isBackgroundCancellation(error)) {
        Log.info('$description stopped: the app left the foreground');
        return;
      }
      Log.warn('$description failed', error, stackTrace);
    }),
  );
}

/// Whether [error] only says the app left the foreground while the call ran.
///
/// Rust cancels database work and closes the foreground pools when the app
/// goes to the background, so a call still in flight at that moment fails
/// with one of these. The next resume repeats it; nothing is lost.
bool isBackgroundCancellation(Object error) {
  final text = error.toString();
  return text.contains('retry when active') ||
      text.contains('Database operation deferred until foreground') ||
      text.contains('Native database admission cancelled') ||
      text.contains('(code: 9) interrupted') ||
      text.contains('attempted to acquire a connection on a closed pool');
}
