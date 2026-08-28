import 'dart:typed_data';

import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/utils/log.dart';

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

Future<T?> rustApiProtobuf<T>(
  Future<Uint8List> request,
  T Function(List<int>) decode,
) async {
  try {
    return decode(await request);
  } catch (error) {
    Log.error('Rust API call failed', error: error);
    return null;
  }
}

server.Response_UserData decodeUserData(List<int> bytes) =>
    server.Response_UserData.fromBuffer(bytes);

server.Response_ProofOfWork decodeProofOfWork(List<int> bytes) =>
    server.Response_ProofOfWork.fromBuffer(bytes);

server.Response_MemoriesUrl decodeMemoriesUrl(List<int> bytes) =>
    server.Response_MemoriesUrl.fromBuffer(bytes);

server.Response_MemoriesUploadUrls decodeMemoriesUploadUrls(List<int> bytes) =>
    server.Response_MemoriesUploadUrls.fromBuffer(bytes);

server.Response_MemoriesUsage decodeMemoriesUsage(List<int> bytes) =>
    server.Response_MemoriesUsage.fromBuffer(bytes);

server.Response_PlanBallance decodePlanBalance(List<int> bytes) =>
    server.Response_PlanBallance.fromBuffer(bytes);
