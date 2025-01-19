import 'dart:typed_data';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/pre_key_model.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

typedef DB = DbSignalPreKeyStore;

class ConnectPreKeyStore extends PreKeyStore {
  @override
  Future<bool> containsPreKey(int preKeyId) async {
    final dbPreKey = await dbProvider.db!.query(DB.tableName,
        columns: [DB.columnPreKey],
        where: '${DB.columnPreKeyId} = ?',
        whereArgs: <Object?>[preKeyId]);
    return dbPreKey.isNotEmpty;
  }

  @override
  Future<PreKeyRecord> loadPreKey(int preKeyId) async {
    final dbPreKey = await dbProvider.db!.query(DB.tableName,
        columns: [DB.columnPreKey],
        where: '${DB.columnPreKeyId} = ?',
        whereArgs: <Object?>[preKeyId]);
    if (dbPreKey.isEmpty) {
      throw InvalidKeyIdException('No such preKey record! - $preKeyId');
    }
    Uint8List preKey = dbPreKey.first.cast()[DB.columnPreKey];
    return PreKeyRecord.fromBuffer(preKey);
  }

  @override
  Future<void> removePreKey(int preKeyId) async {
    await dbProvider.db!.delete(DB.tableName,
        where: '${DB.columnPreKeyId} = ?',
        whereArgs: <Object?>[DB.columnPreKeyId]);
  }

  @override
  Future<void> storePreKey(int preKeyId, PreKeyRecord record) async {
    if (await containsPreKey(preKeyId)) {
      await dbProvider.db!.insert(DB.tableName,
          {DB.columnPreKeyId: preKeyId, DB.columnPreKey: record.serialize()});
    } else {
      await dbProvider.db!.update(
          DB.tableName, {DB.columnPreKey: record.serialize()},
          where: '${DB.columnPreKeyId} = ?', whereArgs: <Object?>[preKeyId]);
    }
  }
}
