import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/core/bridge/wrapper/signal.dart';
import 'package:twonly/core/signal/engine.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/protocol_state.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';

Future<bool> processSignalUserData(Response_UserData userData) async {
  return lockingSignalProtocol.protect(() async {
    return _processSignalUserData(userData);
  });
}

Future<bool> _processSignalUserData(Response_UserData userData) async {
  if (userData.hasPqcBundle()) {
    return _processSignalUserDataV2(userData);
  }
  return _processSignalUserDataV1(userData);
}

Future<bool> _processSignalUserDataV2(Response_UserData userData) async {
  try {
    final tempIdentityKey = IdentityKey(
      Curve.decodePoint(
        DjbECPublicKey(
          Uint8List.fromList(userData.publicIdentityKey),
        ).serialize(),
        1,
      ),
    );

    final signalStore = await getSignalStore();
    if (signalStore != null) {
      final existingIdentity = await signalStore.getIdentity(
        SignalProtocolAddress(userData.userId.toString(), defaultDeviceId),
      );

      if (existingIdentity != null && existingIdentity != tempIdentityKey) {
        Log.error(
          'Identity key mismatch for contact ${userData.userId}! Existing V1 key does not match the incoming V2 identity key.',
        );
        return false;
      }
    }

    int? tempEccPreKeyId;
    Uint8List? tempEccPreKeyPublic;
    if (userData.pqcBundle.hasPrekey()) {
      tempEccPreKeyId = userData.pqcBundle.prekey.eccPreKeyId.toInt();
      tempEccPreKeyPublic = Uint8List.fromList(
        userData.pqcBundle.prekey.eccPreKey,
      );
    } else if (userData.prekeys.isNotEmpty) {
      tempEccPreKeyId = userData.prekeys.first.id.toInt();
      tempEccPreKeyPublic = Curve.decodePoint(
        DjbECPublicKey(
          Uint8List.fromList(userData.prekeys.first.prekey),
        ).serialize(),
        1,
      ).serialize();
    }

    final tempKyberPreKeyId = userData.pqcBundle.hasPrekey()
        ? userData.pqcBundle.prekey.kyberPreKeyId.toInt()
        : userData.pqcBundle.kyberSignedPrekeyId.toInt();
    final tempKyberPreKeyPublic = userData.pqcBundle.hasPrekey()
        ? Uint8List.fromList(userData.pqcBundle.prekey.kyberPreKey)
        : Uint8List.fromList(userData.pqcBundle.kyberSignedPrekey);
    final tempKyberPreKeySignature = userData.pqcBundle.hasPrekey()
        ? Uint8List.fromList(userData.pqcBundle.prekey.kyberPreKeySignature)
        : Uint8List.fromList(userData.pqcBundle.kyberSignedPrekeySignature);

    final rustBundle = FrbPreKeyBundle(
      registrationId: userData.registrationId.toInt(),
      deviceId: 1,
      preKeyId: tempEccPreKeyId,
      preKeyPublic: tempEccPreKeyPublic,
      signedPreKeyId: userData.pqcBundle.eccSignedPrekeyId.toInt(),
      signedPreKeyPublic: Uint8List.fromList(
        userData.pqcBundle.eccSignedPrekey,
      ),
      signedPreKeySignature: Uint8List.fromList(
        userData.pqcBundle.eccSignedPrekeySignature,
      ),
      identityKey: tempIdentityKey.publicKey.serialize(),
      kyberPreKeyId: tempKyberPreKeyId,
      kyberPreKeyPublic: tempKyberPreKeyPublic,
      kyberPreKeySignature: tempKyberPreKeySignature,
    );

    await RustSignal.processPrekeyBundle(
      name: userData.userId.toString(),
      deviceId: 1,
      bundle: rustBundle,
    );

    final contact = await twonlyDB.contactsDao.getContactById(
      userData.userId.toInt(),
    );
    if (contact != null && contact.signalVersion != SignalVersion.v2) {
      await twonlyDB.contactsDao.updateContact(
        contact.userId,
        const ContactsCompanion(signalVersion: drift.Value(SignalVersion.v2)),
      );
    }

    return true;
  } catch (e) {
    Log.error('could not process pqc bundle: $e');
    return false;
  }
}

Future<bool> _processSignalUserDataV1(Response_UserData userData) async {
  final SignalProtocolStore? signalStore = await getSignalStore();

  if (signalStore == null) {
    return false;
  }

  final targetAddress = getSignalAddress(userData.userId.toInt());

  final sessionBuilder = SessionBuilder.fromSignalStore(
    signalStore,
    targetAddress,
  );

  ECPublicKey? tempPrePublicKey;
  int? tempPreKeyId;

  if (userData.prekeys.isNotEmpty) {
    tempPrePublicKey = Curve.decodePoint(
      DjbECPublicKey(
        Uint8List.fromList(userData.prekeys.first.prekey),
      ).serialize(),
      1,
    );
    tempPreKeyId = userData.prekeys.first.id.toInt();
  }

  final tempSignedPreKeyId = userData.signedPrekeyId.toInt();

  final tempSignedPreKeyPublic = Curve.decodePoint(
    DjbECPublicKey(Uint8List.fromList(userData.signedPrekey)).serialize(),
    1,
  );

  final tempSignedPreKeySignature = Uint8List.fromList(
    userData.signedPrekeySignature,
  );

  final tempIdentityKey = IdentityKey(
    Curve.decodePoint(
      DjbECPublicKey(
        Uint8List.fromList(userData.publicIdentityKey),
      ).serialize(),
      1,
    ),
  );

  final preKeyBundle = PreKeyBundle(
    userData.registrationId.toInt(),
    defaultDeviceId,
    tempPreKeyId,
    tempPrePublicKey,
    tempSignedPreKeyId,
    tempSignedPreKeyPublic,
    tempSignedPreKeySignature,
    tempIdentityKey,
  );

  try {
    await sessionBuilder.processPreKeyBundle(preKeyBundle);
    return true;
  } catch (e) {
    Log.error('could not process pre key bundle: $e');
    return false;
  }
}

Future<Uint8List?> getPublicKeyFromContact(int contactId) async {
  final signalStore = await getSignalStore();
  if (signalStore == null) return null;
  try {
    final targetIdentity = await signalStore.getIdentity(
      SignalProtocolAddress(
        contactId.toString(),
        defaultDeviceId,
      ),
    );
    if (targetIdentity != null) {
      return targetIdentity.publicKey.serialize();
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<bool> handleSessionResync(int fromUserId) async {
  final userData = await apiService.getUserById(fromUserId);
  if (userData != null) {
    Log.info('Got new session data from the server to re-sync the session');
    return processSignalUserData(userData);
  }
  Log.info('Could not download userdata from the server.');
  return false;
}
