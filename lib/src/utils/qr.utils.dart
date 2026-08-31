import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:collection/collection.dart' show ListExtensions;
import 'package:drift/drift.dart' show Value;
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:twonly/core/bridge/wrapper/signal.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/services/key_verification.service.dart';
import 'package:twonly/src/utils/log.dart';

class QrCodeUtils {
  static String linkPrefix = 'https://me.twonly.eu/qr/#';

  static Future<String> publicProfileLink() async {
    final publicIdentityKey = await RustSignal.getUserPublicKey();
    final secretVerificationToken =
        await KeyVerificationService.getNewSecretVerificationToken();

    final publicProfile = PublicProfile(
      userId: Int64(userService.currentUser.userId),
      username: userService.currentUser.username,
      publicIdentityKey: publicIdentityKey,
      secretVerificationToken: secretVerificationToken,
      timestamp: Int64(clock.now().millisecondsSinceEpoch),
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

    if (contact == null) {
      if (profile.username == userService.currentUser.username) {
        return null;
      }
      // NEW_USER
      return (profile, null, false);
    }

    final storedPublicKey = await RustSignal.getContactPublicKey(
      contactId: contact.userId,
    );
    if (storedPublicKey == null) return null;

    final verificationOk = profile.publicIdentityKey.equals(
      storedPublicKey.toList(),
    );

    if (verificationOk) {
      var useSecretVerificationToken = profile.hasSecretVerificationToken();
      if (profile.hasTimestamp()) {
        // Only notify the scanned user if the QR code was generated within the last 10 minutes.
        final timestamp = DateTime.fromMillisecondsSinceEpoch(
          profile.timestamp.toInt(),
        );
        final tenMinutesAgo = clock.now().subtract(const Duration(minutes: 10));
        if (timestamp.isBefore(tenMinutesAgo)) {
          useSecretVerificationToken = false;
        }
      }
      if (useSecretVerificationToken) {
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
  try {
    // The contact row has to exist before the session is established: Rust
    // marks the contact as `v2` while processing the prekey bundle, and the
    // contact request is queued against this row. Adding the contact
    // afterwards would leave it on the `v1` default, which makes every
    // message to it refetch a prekey bundle first.
    final added = await twonlyDB.contactsDao.insertOnConflictUpdate(
      ContactsCompanion(
        username: Value(profile.username),
        userId: Value(profile.userId.toInt()),
        requested: const Value(false),
        blocked: const Value(false),
        deletedByUser: const Value(false),
      ),
    );

    if (!await RustApi.tryRequestContactById(
      contactId: profile.userId.toInt(),
      expectedPublicKey: Uint8List.fromList(profile.publicIdentityKey),
    )) {
      return false;
    }

    if (added > 0) {
      // The user was added via the profile scanned from the QR code so the scanned public key was used.
      await twonlyDB.keyVerificationDao.addKeyVerification(
        profile.userId.toInt(),
        VerificationType.qrScanned,
      );

      if (profile.hasSecretVerificationToken()) {
        await KeyVerificationService.handleScannedVerificationToken(
          profile.userId.toInt(),
          Uint8List.fromList(profile.publicIdentityKey),
          profile.secretVerificationToken,
        );
      }
    }
    return true;
  } catch (e) {
    Log.error('Failed to establish session and send contact request: $e');
    return false;
  }
}
