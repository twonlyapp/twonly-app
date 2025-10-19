import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/log.dart';

class ConnectPreKeyStore extends PreKeyStore {
  @override
  Future<bool> containsPreKey(int preKeyId) async {
    final preKeyRecord = await (twonlyDB.select(twonlyDB.signalPreKeyStores)
          ..where((tbl) => tbl.preKeyId.equals(preKeyId)))
        .get();
    return preKeyRecord.isNotEmpty;
  }

  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async {
    final preKeyRecord = await (twonlyDB.select(twonlyDB.signalPreKeyStores)
          ..where((tbl) => tbl.preKeyId.equals(preKeyId)))
        .get();
    if (preKeyRecord.isEmpty) {
      throw InvalidKeyIdException('No such preKey record! - $preKeyId');
    }
    Log.info('Contact used preKey $preKeyId');
    final preKey = preKeyRecord.first.preKey;
    return PreKeyRecord.fromBuffer(preKey);
  }

  @override
  Future<void> removePreKey(int preKeyId) async {
    await (twonlyDB.delete(twonlyDB.signalPreKeyStores)
          ..where((tbl) => tbl.preKeyId.equals(preKeyId)))
        .go();
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    final preKeyCompanion = SignalPreKeyStoresCompanion(
      preKeyId: Value(preKeyId),
      preKey: Value(record.serialize()),
    );

    try {
      await twonlyDB.into(twonlyDB.signalPreKeyStores).insert(preKeyCompanion);
    } catch (e) {
      Log.error('$e');
    }
  }
}
