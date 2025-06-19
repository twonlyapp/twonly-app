import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';

class ConnectSignedPreKeyStore extends SignedPreKeyStore {
  Future<HashMap<int, Uint8List>> getStore() async {
    final storage = FlutterSecureStorage();
    final storeSerialized = await storage.read(
      key: SecureStorageKeys.signalSignedPreKey,
    );
    var store = HashMap<int, Uint8List>();
    if (storeSerialized == null) {
      return store;
    }
    final storeHashMap = json.decode(storeSerialized);
    for (final item in storeHashMap) {
      store[item[0]] = base64Decode(item[1]);
    }
    return store;
  }

  Future safeStore(HashMap<int, Uint8List> store) async {
    final storage = FlutterSecureStorage();
    var storeHashMap = [];
    for (final item in store.entries) {
      storeHashMap.add([item.key, base64Encode(item.value)]);
    }
    final storeSerialized = json.encode(storeHashMap);
    await storage.write(
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
