import 'dart:collection';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';
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
    final record = await (twonlyDB.select(
      twonlyDB.signalSignedPreKeyStores,
    )..where((tbl) => tbl.signedPreKeyId.equals(signedPreKeyId))).get();
    if (record.isEmpty) {
      throw InvalidKeyIdException(
        'No such signed prekey record! $signedPreKeyId',
      );
    }
    return SignedPreKeyRecord.fromSerialized(record.first.signedPreKey);
  }

  @override
  Future<List<SignedPreKeyRecord>> loadSignedPreKeys() async {
    final records = await twonlyDB
        .select(twonlyDB.signalSignedPreKeyStores)
        .get();
    return records
        .map((r) => SignedPreKeyRecord.fromSerialized(r.signedPreKey))
        .toList();
  }

  @override
  Future<void> storeSignedPreKey(
    int signedPreKeyId,
    SignedPreKeyRecord record,
  ) async {
    final companion = SignalSignedPreKeyStoresCompanion(
      signedPreKeyId: Value(signedPreKeyId),
      signedPreKey: Value(record.serialize()),
    );

    try {
      await twonlyDB
          .into(twonlyDB.signalSignedPreKeyStores)
          .insert(companion, mode: InsertMode.insertOrReplace);
    } catch (e) {
      Log.error('$e');
    }
  }

  @override
  Future<bool> containsSignedPreKey(int signedPreKeyId) async {
    final record = await (twonlyDB.select(
      twonlyDB.signalSignedPreKeyStores,
    )..where((tbl) => tbl.signedPreKeyId.equals(signedPreKeyId))).get();
    return record.isNotEmpty;
  }

  @override
  Future<void> removeSignedPreKey(int signedPreKeyId) async {
    await (twonlyDB.delete(
      twonlyDB.signalSignedPreKeyStores,
    )..where((tbl) => tbl.signedPreKeyId.equals(signedPreKeyId))).go();
  }
}
