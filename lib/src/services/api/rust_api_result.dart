import 'package:twonly/src/model/error_code.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/utils/log.dart';

export 'package:twonly/src/model/error_code.dart';

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
