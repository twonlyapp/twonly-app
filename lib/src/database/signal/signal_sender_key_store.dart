import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/signal.db.dart';

class SignalSenderKeyStore extends SenderKeyStore {
  @override
  Future<SenderKeyRecord> loadSenderKey(SenderKeyName senderKeyName) async {
    final identity =
        await (signalDB.select(signalDB.signalSenderKeyStores)
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
    await signalDB
        .into(signalDB.signalSenderKeyStores)
        .insert(
          SignalSenderKeyStoresCompanion(
            senderKey: Value(record.serialize()),
            senderKeyName: Value(senderKeyName.serialize()),
          ),
        );
  }
}
