import 'dart:typed_data';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/sender_key_store_model.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

typedef DB = DbSignalSenderKeyStore;

class ConnectSenderKeyStore extends SenderKeyStore {
  @override
  Future<SenderKeyRecord> loadSenderKey(SenderKeyName senderKeyName) async {
    final dbSenderKey = await dbProvider.db!.query(DB.tableName,
        columns: [DB.columnSenderKey],
        where: '${DB.columnSenderKeyName} = ?',
        whereArgs: <Object?>[senderKeyName.serialize()]);
    if (dbSenderKey.isEmpty) {
      throw InvalidKeyIdException(
          'No such sender key record! - $senderKeyName');
    }
    Uint8List preKey = dbSenderKey.first.cast()[DB.columnSenderKey];
    return SenderKeyRecord.fromSerialized(preKey);
  }

  @override
  Future<void> storeSenderKey(
      SenderKeyName senderKeyName, SenderKeyRecord record) async {
    await dbProvider.db!.insert(DB.tableName, {
      DB.columnSenderKeyName: senderKeyName.serialize(),
      DB.columnSenderKey: record.serialize()
    });
  }
}
