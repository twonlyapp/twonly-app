import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/database/signal/signal_protocol_store.dart';
import 'package:twonly/src/model/json/signal_identity.model.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/protocol_state.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/secure_storage.dart';

Future<IdentityKeyPair?> getSignalIdentityKeyPair() async {
  final signalIdentity = await getSignalIdentity();
  if (signalIdentity == null) return null;
  return IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);
}

// This function runs after the clients authenticated with the server.
// It then checks if it should update a new session key
Future<void> signalHandleNewServerConnection() async {
  if (userService.currentUser.signalLastSignedPreKeyUpdated != null) {
    final fortyEightHoursAgo = clock.now().subtract(const Duration(hours: 48));
    final isYoungerThan48Hours =
        (userService.currentUser.signalLastSignedPreKeyUpdated!).isAfter(
          fortyEightHoursAgo,
        );
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
  await UserService.update((user) {
    user.signalLastSignedPreKeyUpdated = clock.now();
  });
  final res = await apiService.updateSignedPreKey(
    signedPreKey.id,
    signedPreKey.getKeyPair().publicKey.serialize(),
    signedPreKey.signature,
  );
  if (res.isError) {
    Log.error('could not update the signed pre key: ${res.error}');
    await UserService.update((user) {
      user.signalLastSignedPreKeyUpdated = null;
    });
  } else {
    Log.info('updated signed pre key');
  }
}

Future<List<PreKeyRecord>> signalGetPreKeys() async {
  return lockingSignalProtocol.protect(() async {
    final start = userService.currentUser.currentPreKeyIndexStart;
    await UserService.update((u) {
      u.currentPreKeyIndexStart = (u.currentPreKeyIndexStart + 200) % maxValue;
    });
    final preKeys = generatePreKeys(start, 200);
    final signalStore = await getSignalStore();
    if (signalStore == null) return [];
    for (final p in preKeys) {
      await signalStore.preKeyStore.storePreKey(p.id, p);
    }
    return preKeys;
  });
}

Future<SignalIdentity?> getSignalIdentity() async {
  try {
    var signalIdentityJson = await SecureStorage.instance.read(
      key: SecureStorageKeys.signalIdentity,
    );
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

Future<Uint8List> getUserPublicKey() async {
  final signalIdentity = (await getSignalIdentity())!;
  final signalStore = await getSignalStoreFromIdentity(signalIdentity);
  return (await signalStore.getIdentityKeyPair()).getPublicKey().serialize();
}

Future<void> createIfNotExistsSignalIdentity() async {
  final signalIdentity = await SecureStorage.instance.read(
    key: SecureStorageKeys.signalIdentity,
  );

  if (signalIdentity != null) {
    return;
  }

  final identityKeyPair = generateIdentityKeyPair();
  final registrationId = generateRegistrationId(true);

  final signalStore = SignalSignalProtocolStore(
    identityKeyPair,
    registrationId,
  );

  final signedPreKey = generateSignedPreKey(identityKeyPair, defaultDeviceId);

  await signalStore.signedPreKeyStore.storeSignedPreKey(
    signedPreKey.id,
    signedPreKey,
  );

  final storedSignalIdentity = SignalIdentity(
    identityKeyPairU8List: identityKeyPair.serialize(),
    registrationId: registrationId,
  );

  await SecureStorage.instance.write(
    key: SecureStorageKeys.signalIdentity,
    value: jsonEncode(storedSignalIdentity),
  );
}

Future<SignedPreKeyRecord?> _getNewSignalSignedPreKey() async {
  return lockingSignalProtocol.protect(() async {
    var identityKeyPair = await getSignalIdentityKeyPair();
    final signalStore = await getSignalStore();
    if (identityKeyPair == null || signalStore == null) {
      return null;
    }

    final signedPreKeyId =
        userService.currentUser.currentSignedPreKeyIndexStart;
    await UserService.update((user) {
      user.currentSignedPreKeyIndexStart += 1;
    });

    final signedPreKey = generateSignedPreKey(
      identityKeyPair,
      signedPreKeyId,
    );

    identityKeyPair = null;

    await signalStore.storeSignedPreKey(signedPreKeyId, signedPreKey);

    return signedPreKey;
  });
}
