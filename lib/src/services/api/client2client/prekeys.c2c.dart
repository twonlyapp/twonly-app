import 'package:fixnum/fixnum.dart';
import 'package:twonly/core/bridge/wrapper/signal.dart';
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

Future<client.Response?> handleRequestNewPqcPreKey() async {
  final pqcKeys = await RustSignal.generatePqcPrekeys();
  if (pqcKeys.isEmpty) return null;

  final prekeysList = <client.ApplicationData_PqcPreKey>[];
  for (final pqcKey in pqcKeys) {
    prekeysList.add(
      client.ApplicationData_PqcPreKey(
        eccPreKeyId: Int64(pqcKey.eccPreKeyId),
        eccPreKey: pqcKey.eccPreKey,
        kyberPreKeyId: Int64(pqcKey.kyberPreKeyId),
        kyberPreKey: pqcKey.kyberPreKey,
        kyberPreKeySignature: pqcKey.kyberPreKeySignature,
      ),
    );
  }

  final prekeys = client.Response_PqcPrekeys(prekeys: prekeysList);
  final ok = client.Response_Ok()..prekeysPqc = prekeys;
  return client.Response()..ok = ok;
}
