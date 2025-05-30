import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/model/json/signal_identity.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';

const int defaultDeviceId = 1;

Future<ConnectSignalProtocolStore?> getSignalStore() async {
  return await getSignalStoreFromIdentity((await getSignalIdentity())!);
}

Future<ConnectSignalProtocolStore> getSignalStoreFromIdentity(
    SignalIdentity signalIdentity) async {
  final IdentityKeyPair identityKeyPair =
      IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

  return ConnectSignalProtocolStore(
      identityKeyPair, signalIdentity.registrationId.toInt());
}

Future<List<PreKeyRecord>> signalGetPreKeys() async {
  final preKeys = generatePreKeys(0, 200);
  final signalStore = await getSignalStore();
  if (signalStore == null) return [];
  for (final p in preKeys) {
    await signalStore.preKeyStore.storePreKey(p.id, p);
  }
  return preKeys;
}
