import 'package:fixnum/fixnum.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pb.dart'
    as client;
import 'package:twonly/src/services/signal/identity.signal.dart';

Future<client.Response> handleRequestNewPreKey() async {
  final localPreKeys = await signalGetPreKeys();

  final prekeysList = <client.Response_PreKey>[];
  for (var i = 0; i < localPreKeys.length; i++) {
    prekeysList.add(
      client.Response_PreKey()
        ..id = Int64(localPreKeys[i].id)
        ..prekey = localPreKeys[i].getKeyPair().publicKey.serialize(),
    );
  }
  final prekeys = client.Response_Prekeys(prekeys: prekeysList);
  final ok = client.Response_Ok()..prekeys = prekeys;
  return client.Response()..ok = ok;
}
