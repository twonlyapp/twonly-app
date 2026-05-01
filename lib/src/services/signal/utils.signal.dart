import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/database/signal/signal_protocol_store.dart';
import 'package:twonly/src/model/json/signal_identity.model.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';

Future<SignalSignalProtocolStore?> getSignalStore() async {
  return getSignalStoreFromIdentity((await getSignalIdentity())!);
}

Future<SignalSignalProtocolStore> getSignalStoreFromIdentity(
  SignalIdentity signalIdentity,
) async {
  final identityKeyPair = IdentityKeyPair.fromSerialized(
    signalIdentity.identityKeyPairU8List,
  );

  return SignalSignalProtocolStore(
    identityKeyPair,
    signalIdentity.registrationId,
  );
}

SignalProtocolAddress getSignalAddress(int userId) {
  return SignalProtocolAddress(userId.toString(), defaultDeviceId);
}
