import 'dart:typed_data';
import 'package:clock/clock.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/signal/signal_signed_pre_key_store.dart';
import 'package:twonly/src/model/json/signal_identity.model.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/protocol_state.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';

class SignalIdentityService {
  static Future<void> onAuthenticated() async {
    if (userService.currentUser.signalLastSignedPreKeyUpdated != null) {
      final fortyEightHoursAgo = clock.now().subtract(
        const Duration(hours: 48),
      );
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
    final identity = await RustKeyManager.getSignalIdentity();
    return SignalIdentity(
      identityKeyPairU8List: identity.$1,
      registrationId: identity.$2,
    );
  } catch (e) {
    Log.error('could not load signal identity: $e');
    return null;
  }
}

Future<IdentityKeyPair?> getSignalIdentityKeyPair() async {
  final signalIdentity = await getSignalIdentity();
  if (signalIdentity == null) return null;
  return IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);
}

Future<Uint8List> getUserPublicKey() async {
  final signalIdentity = (await getSignalIdentity())!;
  final signalStore = await getSignalStoreFromIdentity(signalIdentity);
  final keyPair = await signalStore.getIdentityKeyPair();
  return keyPair.getPublicKey().serialize();
}

Future<void> createIfNotExistsSignalIdentity() async {
  // check if identity already exists
  final existingIdentity = await getSignalIdentity();
  if (existingIdentity != null) {
    final store = await getSignalStoreFromIdentity(existingIdentity);
    final keys = await store.loadSignedPreKeys();
    if (keys.isEmpty) {
      Log.warn(
        'Signal identity exists but signed prekeys are missing. Generating a new one.',
      );
      final keyPair = await store.getIdentityKeyPair();
      final signedPreKey = generateSignedPreKey(keyPair, defaultDeviceId);
      await SignalSignedPreKeyStore().storeSignedPreKey(
        signedPreKey.id,
        signedPreKey,
      );
    }
    return;
  }

  final identityKeyPair = generateIdentityKeyPair();
  final registrationId = generateRegistrationId(true);

  final signedPreKey = generateSignedPreKey(identityKeyPair, defaultDeviceId);

  await SignalSignedPreKeyStore().storeSignedPreKey(
    signedPreKey.id,
    signedPreKey,
  );

  await RustKeyManager.importSignalIdentity(
    identityKeyPairStructure: identityKeyPair.serialize(),
    registrationId: registrationId,
    signedPreKeyStore: const {},
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
