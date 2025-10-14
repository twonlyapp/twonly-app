import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';

class ConnectSenderKeyStore extends SenderKeyStore {
  @override
  Future<SenderKeyRecord> loadSenderKey(SenderKeyName senderKeyName) async {
    final identity = await (twonlyDB.select(twonlyDB.signalSenderKeyStores)
          ..where((t) => t.senderKeyName.equals(senderKeyName.serialize())))
        .getSingleOrNull();
    if (identity == null) {
      throw InvalidKeyIdException(
        'No such sender key record! - $senderKeyName',
      );
    }
    return SenderKeyRecord.fromSerialized(identity.senderKey);
  }

  @override
  Future<void> storeSenderKey(
    SenderKeyName senderKeyName,
    SenderKeyRecord record,
  ) async {
    await twonlyDB.into(twonlyDB.signalSenderKeyStores).insert(
          SignalSenderKeyStoresCompanion(
            senderKey: Value(record.serialize()),
            senderKeyName: Value(senderKeyName.serialize()),
          ),
        );
  }
}
