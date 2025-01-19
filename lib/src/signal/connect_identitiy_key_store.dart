import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/identity_key_store_model.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';

bool eq<E>(List<E>? list1, List<E>? list2) =>
    ListEquality<E>().equals(list1, list2);

// make it easier to read
typedef DB = DbSignalIdentityKeyStore;

class ConnectIdentityKeyStore extends IdentityKeyStore {
  ConnectIdentityKeyStore(this.identityKeyPair, this.localRegistrationId);

  final IdentityKeyPair identityKeyPair;
  final int localRegistrationId;

  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async {
    var dbIdentityKey = (await dbProvider.db!.query(DB.tableName,
        columns: [DB.columnIdentityKey],
        where: '${DB.columnDeviceId} = ? AND ${DB.columnName} = ?',
        whereArgs: <Object?>[address.getDeviceId(), address.getName()]));
    if (dbIdentityKey.isEmpty) {
      return null;
    }
    Uint8List identityKey = dbIdentityKey.first.cast()[DB.columnIdentityKey];
    return IdentityKey.fromBytes(identityKey, 0);
  }

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async => identityKeyPair;

  @override
  Future<int> getLocalRegistrationId() async => localRegistrationId;

  @override
  Future<bool> isTrustedIdentity(SignalProtocolAddress address,
      IdentityKey? identityKey, Direction? direction) async {
    final trusted = await getIdentity(address);
    if (identityKey == null) {
      return false;
    }
    return trusted == null || eq(trusted.serialize(), identityKey.serialize());
  }

  @override
  Future<bool> saveIdentity(
      SignalProtocolAddress address, IdentityKey? identityKey) async {
    if (identityKey == null) {
      return false;
    }
    if (await getIdentity(address) == null) {
      await dbProvider.db!.insert(DB.tableName, {
        DB.columnDeviceId: address.getDeviceId(),
        DB.columnName: address.getName(),
        DB.columnIdentityKey: identityKey.serialize()
      });
    } else {
      await dbProvider.db!.update(
          DB.tableName, {DB.columnIdentityKey: identityKey.serialize()},
          where: '${DB.columnDeviceId} = ? AND ${DB.columnName} = ?',
          whereArgs: <Object?>[address.getDeviceId(), address.getName()]);
    }
    return true;
  }
}
