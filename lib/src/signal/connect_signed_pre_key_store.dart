import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:connect/src/utils.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

class ConnectSignedPreKeyStore extends SignedPreKeyStore {
  // final store = HashMap<int, Uint8List>();

  Future<HashMap<int, Uint8List>> getStore() async {
    final storage = getSecureStorage();
    final storeSerialized = await storage.read(key: "signed_pre_key_store");
    var store = HashMap<int, Uint8List>();
    if (storeSerialized == null) {
      return store;
    }
    final storeHashMap = json.decode(storeSerialized);
    // for (final item in storeHashMap) {
    //   store[item[0]] = Uint8List.fromList(item[1].codeUnits);
    // }
    return storeHashMap;
  }

  Future safeStore(HashMap<int, Uint8List> store) async {
    final storage = getSecureStorage();
    final storeSerialized = json.encode(store);
    await storage.write(key: "signed_pre_key_store", value: storeSerialized);
  }

  @override
  Future<SignedPreKeyRecord> loadSignedPreKey(int signedPreKeyId) async {
    final store = await getStore();
    if (!store.containsKey(signedPreKeyId)) {
      throw InvalidKeyIdException(
          'No such signedprekeyrecord! $signedPreKeyId');
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
      int signedPreKeyId, SignedPreKeyRecord record) async {
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
