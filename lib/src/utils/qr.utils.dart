import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart' show ListExtensions;
import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/api/utils.api.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';

class QrCodeUtils {
  static String linkPrefix = 'https://me.twonly.eu/qr/#';

  static Future<String> publicProfileLink() async {
    final signalIdentity = (await getSignalIdentity())!;

    final signalStore = await getSignalStoreFromIdentity(signalIdentity);

    final signedPreKey = (await signalStore.loadSignedPreKeys())[0];

    final secretVerificationToken =
        await KeyVerificationService.getNewSecretVerificationToken();

    final publicProfile = PublicProfile(
      userId: Int64(userService.currentUser.userId),
      username: userService.currentUser.username,
      publicIdentityKey: (await signalStore.getIdentityKeyPair())
          .getPublicKey()
          .serialize(),
      registrationId: Int64(signalIdentity.registrationId),
      signedPrekey: signedPreKey.getKeyPair().publicKey.serialize(),
      signedPrekeySignature: signedPreKey.signature,
      signedPrekeyId: Int64(signedPreKey.id),
      secretVerificationToken: secretVerificationToken,
    );

    final data = publicProfile.writeToBuffer();

    final qrEnvelope = QREnvelope(
      type: QREnvelope_Type.PUBLIC_PROFILE,
      data: data,
    );

    final bytes = qrEnvelope.writeToBuffer();
    final urlSafeBase64 = base64Url.encode(bytes);

    final link = '$linkPrefix$urlSafeBase64';
    if (kDebugMode) Log.info(link);
    return link;
  }

  // returns: profile, NEW_USER=true/VERIFIED_USER=false, VERIFICATION_OK
  static Future<(PublicProfile, Contact?, bool)?> handleQrCodeLink(
    String link,
  ) async {
    late PublicProfile profile;

    try {
      final bytes = base64Url.decode(link.replaceFirst(linkPrefix, ''));
      final envelope = QREnvelope.fromBuffer(bytes);
      if (envelope.type != QREnvelope_Type.PUBLIC_PROFILE) return null;
      profile = PublicProfile.fromBuffer(envelope.data);
    } catch (e) {
      Log.error(e);
      return null;
    }

    final contact = await twonlyDB.contactsDao.getContactById(
      profile.userId.toInt(),
    );

    if (contact == null || !contact.accepted) {
      if (profile.username == userService.currentUser.username) {
        return null;
      }
      // NEW_USER
      return (profile, null, false);
    }

    final storedPublicKey = await getPublicKeyFromContact(contact.userId);
    if (storedPublicKey == null) return null;

    final verificationOk = profile.publicIdentityKey.equals(
      storedPublicKey.toList(),
    );

    if (verificationOk) {
      if (profile.hasSecretVerificationToken()) {
        unawaited(
          KeyVerificationService.handleScannedVerificationToken(
            contact.userId,
            storedPublicKey,
            profile.secretVerificationToken,
          ),
        );
      }
      await twonlyDB.keyVerificationDao.addKeyVerification(
        contact.userId,
        VerificationType.qrScanned,
      );
    }

    return (profile, contact, verificationOk);
  }
}

Future<bool> addNewContactFromPublicProfile(PublicProfile profile) async {
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
    ),
  );

  // The user was added via the profile scanned from the QR code so the scanned public key was used.
  await twonlyDB.keyVerificationDao.addKeyVerification(
    profile.userId.toInt(),
    VerificationType.qrScanned,
  );

  if (added > 0) {
    if (await importSignalContactAndCreateRequest(userdata)) {
      if (profile.hasSecretVerificationToken()) {
        await KeyVerificationService.handleScannedVerificationToken(
          profile.userId.toInt(),
          Uint8List.fromList(profile.publicIdentityKey),
          profile.secretVerificationToken,
        );
      }
      return true;
    }
    return false;
  }

  return false;
}
