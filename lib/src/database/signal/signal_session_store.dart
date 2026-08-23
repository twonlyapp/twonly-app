import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/signal.db.dart';

class SignalSessionStore extends SessionStore {
  @override
  Future<bool> containsSession(SignalProtocolAddress address) async {
    final sessions =
        await (signalDB.select(signalDB.signalSessionStores)..where(
              (tbl) =>
                  tbl.deviceId.equals(address.getDeviceId()) &
                  tbl.name.equals(address.getName()),
            ))
            .get();
    return sessions.isNotEmpty;
  }

  @override
  Future<void> deleteAllSessions(String name) async {
    await (signalDB.delete(
      signalDB.signalSessionStores,
    )..where((tbl) => tbl.name.equals(name))).go();
  }

  @override
  Future<void> deleteSession(SignalProtocolAddress address) async {
    await (signalDB.delete(signalDB.signalSessionStores)..where(
          (tbl) =>
              tbl.deviceId.equals(address.getDeviceId()) &
              tbl.name.equals(address.getName()),
        ))
        .go();
  }

  @override
  Future<List<int>> getSubDeviceSessions(String name) async {
    final deviceIds =
        await (signalDB.select(signalDB.signalSessionStores)..where(
              (tbl) => tbl.deviceId.equals(1).not() & tbl.name.equals(name),
            ))
            .get();
    return deviceIds.map((row) => row.deviceId).toList();
  }

  @override
  Future<SessionRecord> loadSession(SignalProtocolAddress address) async {
    final dbSession =
        await (signalDB.select(signalDB.signalSessionStores)..where(
              (tbl) =>
                  tbl.deviceId.equals(address.getDeviceId()) &
                  tbl.name.equals(address.getName()),
            ))
            .get();

    if (dbSession.isEmpty) {
      return SessionRecord();
    }
    final session = dbSession.first.sessionRecord;
    return SessionRecord.fromSerialized(session);
  }

  @override
  Future<void> storeSession(
    SignalProtocolAddress address,
    SessionRecord record,
  ) async {
    final sessionCompanion = SignalSessionStoresCompanion(
      deviceId: Value(address.getDeviceId()),
      name: Value(address.getName()),
      sessionRecord: Value(record.serialize()),
    );

    if (!await containsSession(address)) {
      await signalDB
          .into(signalDB.signalSessionStores)
          .insert(sessionCompanion);
    } else {
      await (signalDB.update(signalDB.signalSessionStores)..where(
            (tbl) =>
                tbl.deviceId.equals(address.getDeviceId()) &
                tbl.name.equals(address.getName()),
          ))
          .write(sessionCompanion);
    }
  }
}
