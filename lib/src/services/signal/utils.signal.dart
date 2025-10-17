import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/model/json/signal_identity.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';

Future<ConnectSignalProtocolStore?> getSignalStore() async {
  return getSignalStoreFromIdentity((await getSignalIdentity())!);
}

Future<ConnectSignalProtocolStore> getSignalStoreFromIdentity(
  SignalIdentity signalIdentity,
) async {
  final identityKeyPair =
      IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

  return ConnectSignalProtocolStore(
    identityKeyPair,
    signalIdentity.registrationId,
  );
}
