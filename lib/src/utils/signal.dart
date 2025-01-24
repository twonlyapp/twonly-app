import 'dart:convert';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/model/json/signal_identity.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart';
import 'package:twonly/src/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/utils/misc.dart';

const int defaultDeviceId = 1;

Future<ECPrivateKey?> getPrivateKey() async {
  final signalIdentity = await getSignalIdentity();
  if (signalIdentity == null) {
    return null;
  }

  final IdentityKeyPair identityKeyPair =
      IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

  return identityKeyPair.getPrivateKey();
}

Future<bool> addNewContact(Response_UserData userData) async {
  final Int64 userId = userData.userId;

  SignalProtocolAddress targetAddress =
      SignalProtocolAddress(userId.toString(), defaultDeviceId);

  SignalProtocolStore? signalStore = await getSignalStore();
  if (signalStore == null) {
    return false;
  }

  SessionBuilder sessionBuilder =
      SessionBuilder.fromSignalStore(signalStore, targetAddress);

  ECPublicKey? tempPrePublicKey;
  int? tempPreKeyId;
  if (userData.prekeys.isNotEmpty) {
    tempPrePublicKey = Curve.decodePoint(
        DjbECPublicKey(Uint8List.fromList(userData.prekeys.first.prekey))
            .serialize(),
        1);
    tempPreKeyId = userData.prekeys.first.id.toInt();
  }
  // Signed pre key calculation
  int tempSignedPreKeyId = userData.signedPrekeyId.toInt();
  // Map? tempSignedPreKey = remoteBundle["signedPreKey"];
  ECPublicKey? tempSignedPreKeyPublic;
  Uint8List? tempSignedPreKeySignature;
  // if (tempSignedPreKey != null) {
  tempSignedPreKeyPublic = Curve.decodePoint(
      DjbECPublicKey(Uint8List.fromList(userData.signedPrekey)).serialize(), 1);
  tempSignedPreKeySignature =
      Uint8List.fromList(userData.signedPrekeySignature);
  // }
  // Identity key calculation
  IdentityKey tempIdentityKey = IdentityKey(Curve.decodePoint(
      DjbECPublicKey(Uint8List.fromList(userData.publicIdentityKey))
          .serialize(),
      1));
  PreKeyBundle preKeyBundle = PreKeyBundle(
    userData.userId.toInt(),
    1,
    tempPreKeyId,
    tempPrePublicKey,
    tempSignedPreKeyId,
    tempSignedPreKeyPublic,
    tempSignedPreKeySignature,
    tempIdentityKey,
  );

  try {
    await sessionBuilder.processPreKeyBundle(preKeyBundle);
    return true;
  } catch (e) {
    Logger("signal_helper").shout("Error: $e");
    return false;
  }
}

Future<ConnectSignalProtocolStore?> getSignalStore() async {
  return await getSignalStoreFromIdentity((await getSignalIdentity())!);
}

Future<SignalIdentity?> getSignalIdentity() async {
  final storage = getSecureStorage();
  final signalIdentityJson = await storage.read(key: "signal_identity");
  if (signalIdentityJson == null) {
    return null;
  }

  return SignalIdentity.fromJson(jsonDecode(signalIdentityJson));
}

Future<ConnectSignalProtocolStore> getSignalStoreFromIdentity(
    SignalIdentity signalIdentity) async {
  final IdentityKeyPair identityKeyPair =
      IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

  return ConnectSignalProtocolStore(
      identityKeyPair, signalIdentity.registrationId.toInt());
}

Future<List<PreKeyRecord>> getPreKeys() async {
  final preKeys = generatePreKeys(0, 200);
  final signalStore = await getSignalStore();
  if (signalStore == null) return [];
  for (final p in preKeys) {
    await signalStore.preKeyStore.storePreKey(p.id, p);
  }
  return preKeys;
}

Future createIfNotExistsSignalIdentity() async {
  final storage = getSecureStorage();

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
      registrationId: Int64(registrationId));

  await storage.write(
      key: "signal_identity", value: jsonEncode(storedSignalIdentity));
}
