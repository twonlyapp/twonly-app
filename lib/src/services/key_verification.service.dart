import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/providers/routing.provider.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_success_dialog.comp.dart';

class KeyVerificationService {
  static Future<List<int>> getNewSecretVerificationToken() async {
    final token = getRandomUint8List(16);
    await twonlyDB.keyVerificationDao.insertVerificationToken(token);
    return token.toList();
  }

  static Future<void> handleScannedVerificationToken(
    int contactId,
    Uint8List contactPubKey,
    List<int> secretToken,
  ) async {
    Log.info('Notifying verified user using the secret token');

    final calculatedMac = await _createVerificationBytes(
      contactId,
      contactPubKey,
      secretToken,
      false,
    );

    await sendCipherText(
      contactId,
      pb.EncryptedContent(
        keyVerificationProof: pb.EncryptedContent_KeyVerificationProof(
          calculatedMac: calculatedMac,
        ),
      ),
    );
  }

  static Future<void> handleVerificationProof(
    int fromUserId,
    List<int> receivedMac,
  ) async {
    Log.info('Received a verification proof. Verifying the calculated mac...');

    final contactPubKey = await getPublicKeyFromContact(fromUserId);
    if (contactPubKey == null) {
      Log.error('No public key stored..');
      return;
    }

    final secretTokens = await twonlyDB.keyVerificationDao
        .getRecentVerificationTokens();
    for (final secretToken in secretTokens) {
      final recalculatedMac = await _createVerificationBytes(
        fromUserId,
        contactPubKey,
        secretToken.token,
        true,
      );
      if (recalculatedMac.equals(receivedMac)) {
        await twonlyDB.keyVerificationDao.addKeyVerification(
          fromUserId,
          VerificationType.secretQrToken,
        );
        Log.info('Contact was verified via secretQrToken');

        final contact = await twonlyDB.contactsDao.getContactById(fromUserId);
        final context = rootNavigatorKey.currentContext;
        if (context != null && context.mounted && contact != null) {
          unawaited(
            VerificationSuccessDialog.show(
              context,
              contact,
              message: context.lang.secretQrTokenVerifiedSnackbar(
                getContactDisplayName(contact),
              ),
            ),
          );
        }
        return;
      }
    }

    Log.error('No valid secret token could be found...');
  }

  static Future<void> verifySharedContact({
    required int contactId,
    required List<int> sharedPublicIdentityKey,
    required int senderId,
  }) async {
    final publicIdentityKey = await getPublicKeyFromContact(contactId);
    if (publicIdentityKey == null) {
      Log.info('No public key stored for contact $contactId');
      return;
    }

    if (publicIdentityKey.equals(sharedPublicIdentityKey)) {
      Log.info('Verified a user which was shared by a contact');
      await twonlyDB.keyVerificationDao.addKeyVerification(
        contactId,
        VerificationType.contactSharedByVerified,
        verifiedBy: senderId,
      );
    } else {
      Log.error('Public identity keys do not match for contact $contactId');
    }
  }
}

Future<List<int>> _createVerificationBytes(
  int contactId,
  Uint8List contactPubKey,
  List<int> secretToken,
  bool verifying,
) async {
  final bytes = <int>[];

  final userPublicKey = await getUserPublicKey();

  final ownBytes = [
    ..._userIdToLeBytes(userService.currentUser.userId),
    ...userPublicKey,
  ];

  final contactBytes = [..._userIdToLeBytes(contactId), ...contactPubKey];

  if (verifying) {
    bytes
      ..addAll(ownBytes)
      ..addAll(contactBytes);
  } else {
    bytes
      ..addAll(contactBytes)
      ..addAll(ownBytes);
  }

  final hmac = Hmac.sha256();
  final mac = await hmac.calculateMac(
    Uint8List.fromList(bytes),
    secretKey: SecretKey(secretToken),
  );

  return mac.bytes;
}

List<int> _userIdToLeBytes(int userId) {
  final byteData = ByteData(8)..setInt64(0, userId, Endian.little);
  return byteData.buffer.asUint8List();
}
