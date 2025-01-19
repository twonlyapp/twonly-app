import 'dart:typed_data';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/session_store_model.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

// make it easier to read
typedef DB = DbSignalSessionStore;

class ConnectSessionStore extends SessionStore {
  ConnectSessionStore();

  @override
  Future<bool> containsSession(SignalProtocolAddress address) async {
    var list = (await dbProvider.db!.query(DB.tableName,
        columns: [],
        where: '${DB.columnDeviceId} = ? AND ${DB.columnName} = ?',
        whereArgs: <Object?>[address.getDeviceId(), address.getName()]));
    return list.isNotEmpty;
  }

  @override
  Future<void> deleteAllSessions(String name) async {
    await dbProvider.db!.delete(DB.tableName,
        where: '${DB.columnName} = ?', whereArgs: <Object?>[name]);
  }

  @override
  Future<void> deleteSession(SignalProtocolAddress address) async {
    await dbProvider.db!.delete(DB.tableName,
        where: '${DB.columnDeviceId} = ? AND ${DB.columnName} = ?',
        whereArgs: <Object?>[address.getDeviceId(), address.getName()]);
  }

  @override
  Future<List<int>> getSubDeviceSessions(String name) async {
    var deviceIds = (await dbProvider.db!.query(DB.tableName,
        columns: [DB.columnDeviceId],
        where: '${DB.columnDeviceId} != 1 AND ${DB.columnName} = ?',
        whereArgs: <Object?>[name]));
    return deviceIds.cast();
  }

  @override
  Future<SessionRecord> loadSession(SignalProtocolAddress address) async {
    var dbSession = (await dbProvider.db!.query(DB.tableName,
        columns: [DB.columnSessionRecord],
        where: '${DB.columnDeviceId} = ? AND ${DB.columnName} = ?',
        whereArgs: <Object?>[address.getDeviceId(), address.getName()]));

    if (dbSession.isEmpty) {
      return SessionRecord();
    }
    Uint8List session = dbSession.first.cast()[DB.columnSessionRecord];
    return SessionRecord.fromSerialized(session);
  }

  @override
  Future<void> storeSession(
      SignalProtocolAddress address, SessionRecord record) async {
    if (await containsSession(address)) {
      await dbProvider.db!.insert(DB.tableName, {
        DB.columnDeviceId: address.getDeviceId(),
        DB.columnName: address.getName(),
        DB.columnSessionRecord: record.serialize()
      });
    } else {
      await dbProvider.db!.update(
          DB.tableName, {DB.columnSessionRecord: record.serialize()},
          where: '${DB.columnDeviceId} = ? AND ${DB.columnName} = ?',
          whereArgs: <Object?>[address.getDeviceId(), address.getName()]);
    }
  }
}
