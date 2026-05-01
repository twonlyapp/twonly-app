import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/utils/secure_storage.dart';

class SignalSignedPreKeyStore extends SignedPreKeyStore {
  Future<HashMap<int, Uint8List>> getStore() async {
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

  Future<void> safeStore(HashMap<int, Uint8List> store) async {
    final storeHashMap = <List<dynamic>>[];
    for (final item in store.entries) {
      storeHashMap.add([item.key, base64Encode(item.value)]);
    }
    final storeSerialized = json.encode(storeHashMap);
    await SecureStorage.instance.write(
      key: SecureStorageKeys.signalSignedPreKey,
      value: storeSerialized,
    );
  }

  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    final store = await getStore();
    if (!store.containsKey(signedPreKeyId)) {
      throw InvalidKeyIdException(
        'No such signed prekey record! $signedPreKeyId',
      );
    }
    return SignedPreKeyRecord.fromSerialized(store[signedPreKeyId]!);
  }

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
    final store = await getStore();
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
    final store = await getStore();
    store[signedPreKeyId] = record.serialize();
    await safeStore(store);
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async =>
      (await getStore()).containsKey(signedPreKeyId);

  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
    final store = await getStore();
    store.remove(signedPreKeyId);
    await safeStore(store);
  }
}
