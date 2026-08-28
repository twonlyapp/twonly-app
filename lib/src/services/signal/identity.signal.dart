import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/src/database/signal/signal_signed_pre_key_store.dart';
import 'package:twonly/src/model/json/signal_identity.model.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';

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
