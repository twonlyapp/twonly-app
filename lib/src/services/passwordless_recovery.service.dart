import 'dart:async';
import 'dart:convert' show base64Encode, utf8;
import 'dart:typed_data';

import 'package:cryptography_flutter_plus/cryptography_flutter_plus.dart'
    show FlutterChacha20;
import 'package:cryptography_plus/cryptography_plus.dart' show SecretKey;
import 'package:hashlib/hashlib.dart' show Scrypt;
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/json/userdata.model.dart'
    show PasswordLessRecovery;
import 'package:twonly/src/model/protobuf/client/generated/passwordless_recovery/types.pb.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

enum SecondFactorType { none, pin, email }

class PasswordlessRecoveryService {
  static Future<bool> enablePasswordlessRecovery({
    required List<int> trustedFriendIds,
    required SecondFactorType secondFactorType,
    required String secondFactorValue,
    required int threshold,
  }) async {
    await twonlyDB.contactsDao.resetRecoveryDataForAllContacts();

    // 2. Update the user model configuration

    final config = PasswordLessRecovery();

    final serverKey = getRandomUint8List(32);
    Uint8List? protectedEmailServerKey;
    Uint8List? pinUnlockToken;
    Uint8List? protectedPin;

    switch (secondFactorType) {
      case SecondFactorType.email:
        final emailSeed = getRandomUint8List(32);

        // Store it, so the user can see it again.
        config.email = secondFactorValue;

        final chacha20 = FlutterChacha20.poly1305Aead();

        final scrypt = Scrypt(
          cost: 65536,
          salt: emailSeed,
        );

        final protectedEmailKey = scrypt
            .convert(utf8.encode(secondFactorValue))
            .bytes;

        // there must be a emailSeed like for the pin...

        // The serverKey is encrypted with the email; this protects the server from seeing the user's email address, while
        // also ensuring that the server can only send the real secret to the user's configured email, as a different
        // email will result in a different secret key.
        final secretBox = await chacha20.encrypt(
          serverKey,
          secretKey: SecretKey(
            Uint8List.fromList(protectedEmailKey),
          ),
          nonce: chacha20.newNonce(),
        );

        protectedEmailServerKey = EncryptedEnvelope(
          encryptedData: secretBox.cipherText,
          // iv: secretBox.nonce,
          mac: secretBox.mac.bytes,
        ).writeToBuffer();

      case SecondFactorType.pin:
        final pinSeed = getRandomUint8List(32);
        pinUnlockToken = getRandomUint8List(32);

        // The pin seed is to ensure that the server does never learns the real 4-digit pin. The seed is never send to
        // the server. As the pin are heavily protected against brute-forcing and will be discared by the server after X
        // tries, this prevents that a malicous user trigger this deletion...
        config.pinSeed = base64Encode(pinSeed);
        config.pinUnlockToken = base64Encode(pinUnlockToken);

        final scrypt = Scrypt(
          cost: 65536,
          salt: pinSeed,
        );

        final key = scrypt.convert(utf8.encode(secondFactorValue)).bytes;
        protectedPin = key.sublist(0, 32);

      case SecondFactorType.none:
    }

    // 3. Use the second factor and generate the shares...

    // Generate the shares, and store them in the contacrs.table.

    Log.info('Enabling passwordless recovery with:');
    Log.info('  - Trusted Friends: $trustedFriendIds');
    Log.info('  - Second Factor Type: $secondFactorType');
    Log.info('  - Second Factor Value: $secondFactorValue');
    Log.info('  - Threshold: $threshold');

    // Use the serverKey to protect the recovery_data_encrypted

    // 4. Send the data to the server:

    // to th server
    // protectedPin, pinUnlockToken, protectedEmailServerKey;

    // 5. send to the contacts / implement the heartbeat check, and notify the user in case the hearbeath shows that to few users are active...

    return true;
  }
}
