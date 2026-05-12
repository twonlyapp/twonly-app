import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/utils/secure_storage.dart';

Future<HashMap<int, Uint8List>> getSignalSignedPreKeyStoreOld() async {
  final storeSerialized = await SecureStorage.instance.read(
    key: SecureStorageKeys.signalSignedPreKey,
  );
  final store = HashMap<int, Uint8List>();
  if (storeSerialized == null) {
    return store;
  }
  final storeHashMap = json.decode(storeSerialized) as List<dynamic>;
  for (final item in storeHashMap) {
    // ignore: avoid_dynamic_calls
    store[item[0] as int] = base64Decode(item[1] as String);
  }
  return store;
}

class SignalSignedPreKeyStore extends SignedPreKeyStore {
  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    final store = await RustKeyManager.loadSignedPrekey(
      signedPreKeyId: signedPreKeyId,
    );
    if (store == null) {
      throw InvalidKeyIdException(
        'No such signed prekey record! $signedPreKeyId',
      );
    }
    return SignedPreKeyRecord.fromSerialized(store);
  }

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
    final store = await RustKeyManager.loadSignedPrekeys();
    final results = <SignedPreKeyRecord>[];
    for (final serialized in store.values) {
      results.add(SignedPreKeyRecord.fromSerialized(serialized));
    }
    return results;
  }

  @override
  Future<void> storeSignedPreKey(
    int signedPreKeyId,
    SignedPreKeyRecord record,
  ) async {
    await RustKeyManager.storeSignedPrekey(
      signedPreKeyId: signedPreKeyId,
      record: record.serialize(),
    );
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async =>
      await RustKeyManager.loadSignedPrekey(
        signedPreKeyId: signedPreKeyId,
      ) !=
      null;

  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
    await RustKeyManager.removeSignedPrekey(signedPreKeyId: signedPreKeyId);
  }
}
