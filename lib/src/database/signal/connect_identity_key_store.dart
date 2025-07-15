import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';

class ConnectIdentityKeyStore extends IdentityKeyStore {
  ConnectIdentityKeyStore(this.identityKeyPair, this.localRegistrationId);

  final IdentityKeyPair identityKeyPair;
  final int localRegistrationId;

  @override
  Future<IdentityKey?> getIdentity(SignalProtocolAddress address) async {
    final identity = await (twonlyDB.select(twonlyDB.signalIdentityKeyStores)
          ..where((t) =>
              t.deviceId.equals(address.getDeviceId()) &
              t.name.equals(address.getName())))
        .getSingleOrNull();
    if (identity == null) return null;
    return IdentityKey.fromBytes(identity.identityKey, 0);
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
    return trusted == null ||
        const ListEquality<dynamic>()
            .equals(trusted.serialize(), identityKey.serialize());
  }

  @override
  Future<bool> saveIdentity(
      SignalProtocolAddress address, IdentityKey? identityKey) async {
    if (identityKey == null) {
      return false;
    }
    if (await getIdentity(address) == null) {
      await twonlyDB.into(twonlyDB.signalIdentityKeyStores).insert(
            SignalIdentityKeyStoresCompanion(
              deviceId: Value(address.getDeviceId()),
              name: Value(address.getName()),
              identityKey: Value(identityKey.serialize()),
            ),
          );
    } else {
      await (twonlyDB.update(twonlyDB.signalIdentityKeyStores)
            ..where((t) =>
                t.deviceId.equals(address.getDeviceId()) &
                t.name.equals(address.getName())))
          .write(
        SignalIdentityKeyStoresCompanion(
          identityKey: Value(identityKey.serialize()),
        ),
      );
    }
    return true;
  }
}
