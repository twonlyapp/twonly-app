import 'dart:async';

import 'package:twonly/src/model/error_code.dart';
import 'package:twonly/src/utils/log.dart';

export 'package:twonly/src/model/error_code.dart';

class Result<T, E> {
  Result.error(this.error) : value = null, _isSuccess = false;
  Result.success(this.value) : error = null, _isSuccess = true;

  final T? value;
  final E? error;
  final bool _isSuccess;

  bool get isSuccess => _isSuccess;
  bool get isError => !_isSuccess;
}

Future<Result<T, ErrorCode>> rustApiResult<T>(Future<T> request) async {
  try {
    return Result.success(await request);
  } catch (error) {
    final match = RegExp(r'API error code (\d+)').firstMatch(error.toString());
    if (match != null) {
      return Result.error(ErrorCode.valueOf(int.parse(match.group(1)!)));
    }
    Log.error('Rust API call failed', error: error);
    return Result.error(ErrorCode.InternalError);
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
    request.catchError((Object error) {
      Log.warn('$description failed', error);
    }),
  );
}
