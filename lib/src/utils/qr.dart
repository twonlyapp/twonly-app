import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';

Future<Uint8List> getProfileQrCodeData() async {
  final signalIdentity = (await getSignalIdentity())!;

  final signalStore = await getSignalStoreFromIdentity(signalIdentity);

  final signedPreKey = (await signalStore.loadSignedPreKeys())[0];

  final publicProfile = PublicProfile(
    userId: Int64(gUser.userId),
    username: gUser.username,
    publicIdentityKey:
        (await signalStore.getIdentityKeyPair()).getPublicKey().serialize(),
    registrationId: Int64(signalIdentity.registrationId),
    signedPrekey: signedPreKey.getKeyPair().publicKey.serialize(),
    signedPrekeySignature: signedPreKey.signature,
    signedPrekeyId: Int64(signedPreKey.id),
  );

  final data = publicProfile.writeToBuffer();

  final qrEnvelope = QREnvelope(
    type: QREnvelope_Type.PublicProfile,
    data: data,
  );

  return qrEnvelope.writeToBuffer();
}

Future<Uint8List> getUserPublicKey() async {
  final signalIdentity = (await getSignalIdentity())!;
  final signalStore = await getSignalStoreFromIdentity(signalIdentity);
  return (await signalStore.getIdentityKeyPair()).getPublicKey().serialize();
}

PublicProfile? parseQrCodeData(Uint8List rawBytes) {
  try {
    final envelop = QREnvelope.fromBuffer(rawBytes);
    if (envelop.type == QREnvelope_Type.PublicProfile) {
      return PublicProfile.fromBuffer(envelop.data);
    }
  } catch (e) {
    // Log.warn(e);
  }
  return null;
}

Future<void> addNewContactFromPublicProfile(PublicProfile profile) async {
  final userdata = Response_UserData(
    userId: profile.userId,
    publicIdentityKey: profile.publicIdentityKey,
    signedPrekey: profile.signedPrekey,
    signedPrekeyId: profile.signedPrekeyId,
    signedPrekeySignature: profile.signedPrekeySignature,
  );

  final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
    ContactsCompanion(
      username: Value(profile.username),
      userId: Value(profile.userId.toInt()),
      requested: const Value(false),
      blocked: const Value(false),
      deletedByUser: const Value(false),
      verified: const Value(
        true,
      ), // This contact was added from a QR-Code scan, so the public key was not loaded from the server
    ),
  );

  if (added > 0) {
    if (await createNewSignalSession(userdata)) {
      // 1. Setup notifications keys with the other user
      await setupNotificationWithUsers(
        forceContact: userdata.userId.toInt(),
      );
      // 2. Then send user request
      await sendCipherText(
        userdata.userId.toInt(),
        EncryptedContent(
          contactRequest: EncryptedContent_ContactRequest(
            type: EncryptedContent_ContactRequest_Type.REQUEST,
          ),
        ),
      );
    }
  }
}
