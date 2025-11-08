import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/model/json/signal_identity.dart';
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
Future<void> signalHandleNewServerConnection() async {
  if (gUser.signalLastSignedPreKeyUpdated != null) {
    final fortyEightHoursAgo =
        DateTime.now().subtract(const Duration(hours: 48));
    final isYoungerThan48Hours =
        (gUser.signalLastSignedPreKeyUpdated!).isAfter(fortyEightHoursAgo);
    if (isYoungerThan48Hours) {
      // The key does live for 48 hours then it expires and a new key is generated.
      return;
    }
  }
  final signedPreKey = await _getNewSignalSignedPreKey();
  if (signedPreKey == null) {
    Log.error('could not generate a new signed pre key!');
    return;
  }
  await updateUserdata((user) {
    user.signalLastSignedPreKeyUpdated = DateTime.now();
    return user;
  });
  final res = await apiService.updateSignedPreKey(
    signedPreKey.id,
    signedPreKey.getKeyPair().publicKey.serialize(),
    signedPreKey.signature,
  );
  if (res.isError) {
    Log.error('could not update the signed pre key: ${res.error}');
    await updateUserdata((user) {
      user.signalLastSignedPreKeyUpdated = null;
      return user;
    });
  } else {
    Log.info('updated signed pre key');
  }
}

Future<List<PreKeyRecord>> signalGetPreKeys() async {
  final user = await getUser();
  if (user == null) return [];

  final start = user.currentPreKeyIndexStart;
  await updateUserdata((user) {
    user.currentPreKeyIndexStart =
        (user.currentPreKeyIndexStart + 200) % maxValue;
    return user;
  });
  final preKeys = generatePreKeys(start, 200);
  final signalStore = await getSignalStore();
  if (signalStore == null) return [];
  for (final p in preKeys) {
    await signalStore.preKeyStore.storePreKey(p.id, p);
  }
  return preKeys;
}

Future<SignalIdentity?> getSignalIdentity() async {
  try {
    const storage = FlutterSecureStorage();
    var signalIdentityJson =
        await storage.read(key: SecureStorageKeys.signalIdentity);
    if (signalIdentityJson == null) {
      return null;
    }
    final decoded = jsonDecode(signalIdentityJson);
    signalIdentityJson = null;
    return SignalIdentity.fromJson(decoded as Map<String, dynamic>);
  } catch (e) {
    Log.error('could not load signal identity: $e');
    return null;
  }
}

Future<void> createIfNotExistsSignalIdentity() async {
  const storage = FlutterSecureStorage();

  final signalIdentity = await storage.read(
    key: SecureStorageKeys.signalIdentity,
  );

  if (signalIdentity != null) {
    return;
  }

  final identityKeyPair = generateIdentityKeyPair();
  final registrationId = generateRegistrationId(true);

  final signalStore =
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
  var identityKeyPair = await getSignalIdentityKeyPair();
  final user = await getUser();
  final signalStore = await getSignalStore();
  if (identityKeyPair == null || signalStore == null || user == null) {
    return null;
  }

  final signedPreKeyId = user.currentSignedPreKeyIndexStart;
  await updateUserdata((user) {
    user.currentSignedPreKeyIndexStart += 1;
    return user;
  });

  final signedPreKey = generateSignedPreKey(
    identityKeyPair,
    signedPreKeyId,
  );

  identityKeyPair = null;

  await signalStore.storeSignedPreKey(signedPreKeyId, signedPreKey);

  return signedPreKey;
}
