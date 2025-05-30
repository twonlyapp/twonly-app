import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/model/json/signal_identity.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';

const int defaultDeviceId = 1;

Future<ECPrivateKey?> getSignalPrivateIdentityKey() async {
  final signalIdentity = await getSignalIdentity();
  if (signalIdentity == null) {
    return null;
  }

  final IdentityKeyPair identityKeyPair =
      IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

  return identityKeyPair.getPrivateKey();
}

Future<SignalIdentity?> getSignalIdentity() async {
  try {
    final storage = FlutterSecureStorage();
    final signalIdentityJson = await storage.read(key: "signal_identity");
    if (signalIdentityJson == null) {
      return null;
    }
    return SignalIdentity.fromJson(jsonDecode(signalIdentityJson));
  } catch (e) {
    Logger("signal.dart/getSignalIdentity").shout(e);
    return null;
  }
}

Future createIfNotExistsSignalIdentity() async {
  final storage = FlutterSecureStorage();

  final signalIdentity = await storage.read(key: "signal_identity");
  if (signalIdentity != null) {
    return;
  }

  final identityKeyPair = generateIdentityKeyPair();
  final registrationId = generateRegistrationId(true);

  ConnectSignalProtocolStore signalStore =
      ConnectSignalProtocolStore(identityKeyPair, registrationId);

  final signedPreKey = generateSignedPreKey(identityKeyPair, defaultDeviceId);

  await signalStore.signedPreKeyStore
      .storeSignedPreKey(signedPreKey.id, signedPreKey);

  final storedSignalIdentity = SignalIdentity(
    identityKeyPairU8List: identityKeyPair.serialize(),
    registrationId: registrationId,
  );

  await storage.write(
      key: "signal_identity", value: jsonEncode(storedSignalIdentity));
}
