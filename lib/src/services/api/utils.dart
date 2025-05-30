import 'package:fixnum/fixnum.dart';
import 'package:twonly/src/model/protobuf/api/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/model/protobuf/api/client_to_server.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart'
    as server;

class Result<T, E> {
  final T? value;
  final E? error;

  bool get isSuccess => value != null;
  bool get isError => error != null;

  Result.success(this.value) : error = null;
  Result.error(this.error) : value = null;
}

Result asResult(server.ServerToClient? msg) {
  if (msg == null) {
    return Result.error(ErrorCode.InternalError);
  }
  if (msg.v0.response.hasOk()) {
    return Result.success(msg.v0.response.ok);
  } else {
    return Result.error(msg.v0.response.error);
  }
}

ClientToServer createClientToServerFromHandshake(Handshake handshake) {
  var v0 = client.V0()
    ..seq = Int64(0)
    ..handshake = handshake;
  return ClientToServer()..v0 = v0;
}

ClientToServer createClientToServerFromApplicationData(
    ApplicationData applicationData) {
  var v0 = client.V0()
    ..seq = Int64(0)
    ..applicationdata = applicationData;
  return ClientToServer()..v0 = v0;
}
