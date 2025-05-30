import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/model/json/signal_identity.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

Future<IdentityKeyPair?> getSignalIdentityKeyPair() async {
  final signalIdentity = await getSignalIdentity();
  if (signalIdentity == null) return null;
  return IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);
}

// This function runs after the clients authenticated with the server.
// It then checks if it should update a new session key
Future signalHandleNewServerConnection() async {
  final UserData? user = await getUser();
  if (user == null) return;
  if (user.signalLastSignedPreKeyUpdated != null) {
    DateTime fortyEightHoursAgo = DateTime.now().subtract(Duration(hours: 48));
    bool isYoungerThan48Hours =
        (user.signalLastSignedPreKeyUpdated!).isAfter(fortyEightHoursAgo);
    if (isYoungerThan48Hours) {
      // The key does live for 48 hours then it expires and a new key is generated.
      return;
    }
  }
  SignedPreKeyRecord? signedPreKey = await _getNewSignalSignedPreKey();
  if (signedPreKey == null) {
    Log.error("could not generate a new signed pre key!");
    return;
  }
  user.signalLastSignedPreKeyUpdated = DateTime.now();
  await updateUser(user);
  Result res = await apiService.updateSignedPreKey(
    signedPreKey.id,
    signedPreKey.getKeyPair().publicKey.serialize(),
    signedPreKey.signature,
  );
  if (res.isError) {
    Log.error("could not update the signed pre key: ${res.error}");
    final UserData? user = await getUser();
    if (user == null) return;
    user.signalLastSignedPreKeyUpdated = null;
    await updateUser(user);
  } else {
    Log.info("updated signed pre key");
  }
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

Future<SignalIdentity?> getSignalIdentity() async {
  try {
    final storage = FlutterSecureStorage();
    final signalIdentityJson =
        await storage.read(key: SecureStorageKeys.signalIdentity);
    if (signalIdentityJson == null) {
      return null;
    }
    return SignalIdentity.fromJson(jsonDecode(signalIdentityJson));
  } catch (e) {
    Log.error("could not load signal identity: $e");
    return null;
  }
}

Future createIfNotExistsSignalIdentity() async {
  final storage = FlutterSecureStorage();

  final signalIdentity = await storage.read(
    key: SecureStorageKeys.signalIdentity,
  );

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
    key: SecureStorageKeys.signalIdentity,
    value: jsonEncode(storedSignalIdentity),
  );
}

Future<SignedPreKeyRecord?> _getNewSignalSignedPreKey() async {
  final identityKeyPair = await getSignalIdentityKeyPair();
  if (identityKeyPair == null) return null;
  final signalStore = await getSignalStore();
  if (signalStore == null) return null;

  int signedPreKeyId = await signalStore.signedPreKeyStore.getNextKeyId();

  final SignedPreKeyRecord signedPreKey = generateSignedPreKey(
    identityKeyPair,
    signedPreKeyId,
  );

  await signalStore.storeSignedPreKey(signedPreKeyId, signedPreKey);

  return signedPreKey;
}
