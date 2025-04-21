import 'package:drift/drift.dart';
import 'package:twonly/globals.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/database/twonly_database.dart';

class ConnectSessionStore extends SessionStore {
  @override
  Future<bool> containsSession(SignalProtocolAddress address) async {
    final sessions =
        await (twonlyDatabase.select(twonlyDatabase.signalSessionStores)
              ..where((tbl) =>
                  tbl.deviceId.equals(address.getDeviceId()) &
                  tbl.name.equals(address.getName())))
            .get();
    return sessions.isNotEmpty;
  }

  @override
  Future<void> deleteAllSessions(String name) async {
    await (twonlyDatabase.delete(twonlyDatabase.signalSessionStores)
          ..where((tbl) => tbl.name.equals(name)))
        .go();
  }

  @override
  Future<void> deleteSession(SignalProtocolAddress address) async {
    await (twonlyDatabase.delete(twonlyDatabase.signalSessionStores)
          ..where((tbl) =>
              tbl.deviceId.equals(address.getDeviceId()) &
              tbl.name.equals(address.getName())))
        .go();
  }

  @override
  Future<List<int>> getSubDeviceSessions(String name) async {
    final deviceIds = await (twonlyDatabase
            .select(twonlyDatabase.signalSessionStores)
          ..where(
              (tbl) => tbl.deviceId.equals(1).not() & tbl.name.equals(name)))
        .get();
    return deviceIds.map((row) => row.deviceId).toList();
  }

  @override
  Future<SessionRecord> loadSession(SignalProtocolAddress address) async {
    final dbSession =
        await (twonlyDatabase.select(twonlyDatabase.signalSessionStores)
              ..where((tbl) =>
                  tbl.deviceId.equals(address.getDeviceId()) &
                  tbl.name.equals(address.getName())))
            .get();

    if (dbSession.isEmpty) {
      return SessionRecord();
    }
    Uint8List session = dbSession.first.sessionRecord;
    return SessionRecord.fromSerialized(session);
  }

  @override
  Future<void> storeSession(
      SignalProtocolAddress address, SessionRecord record) async {
    final sessionCompanion = SignalSessionStoresCompanion(
      deviceId: Value(address.getDeviceId()),
      name: Value(address.getName()),
      sessionRecord: Value(record.serialize()),
    );

    if (!await containsSession(address)) {
      await twonlyDatabase
          .into(twonlyDatabase.signalSessionStores)
          .insert(sessionCompanion);
    } else {
      await (twonlyDatabase.update(twonlyDatabase.signalSessionStores)
            ..where((tbl) =>
                tbl.deviceId.equals(address.getDeviceId()) &
                tbl.name.equals(address.getName())))
          .write(sessionCompanion);
    }
  }
}
