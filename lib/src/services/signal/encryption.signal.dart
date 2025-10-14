import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/prekeys.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

/// This caused some troubles, so protection the encryption...
final lockingSignalEncryption = Mutex();

Future<Uint8List?> signalEncryptMessage(
  int target,
  Uint8List plaintextContent,
) async {
  return lockingSignalEncryption.protect<Uint8List?>(() async {
    try {
      final signalStore = (await getSignalStore())!;
      final address = SignalProtocolAddress(target.toString(), defaultDeviceId);

      final session = SessionCipher.fromStore(signalStore, address);

      final preKey = await getPreKeyByContactId(target);
      final signedPreKey = await getSignedPreKeyByContactId(target);

      if (signedPreKey != null) {
        final sessionBuilder = SessionBuilder.fromSignalStore(
          signalStore,
          address,
        );

        ECPublicKey? tempPrePublicKey;

        if (preKey != null) {
          tempPrePublicKey = Curve.decodePoint(
            DjbECPublicKey(
              Uint8List.fromList(preKey.preKey),
            ).serialize(),
            1,
          );
        }

        final tempSignedPreKeyPublic = Curve.decodePoint(
          DjbECPublicKey(Uint8List.fromList(signedPreKey.signedPreKey))
              .serialize(),
          1,
        );

        final tempSignedPreKeySignature = Uint8List.fromList(
          signedPreKey.signedPreKeySignature,
        );

        final tempIdentityKey = await signalStore.getIdentity(address);
        if (tempIdentityKey != null) {
          final preKeyBundle = PreKeyBundle(
            target,
            defaultDeviceId,
            preKey?.preKeyId,
            tempPrePublicKey,
            signedPreKey.signedPreKeyId,
            tempSignedPreKeyPublic,
            tempSignedPreKeySignature,
            tempIdentityKey,
          );

          try {
            await sessionBuilder.processPreKeyBundle(preKeyBundle);
          } catch (e) {
            Log.error('could not process pre key bundle: $e');
          }
        } else {
          Log.error('did not get the identity of the remote address');
        }
      }

      final ciphertext = await session.encrypt(plaintextContent);

      final b = BytesBuilder()
        ..add(ciphertext.serialize())
        ..add(intToBytes(ciphertext.getType()));

      return b.takeBytes();
    } catch (e) {
      Log.error(e.toString());
      return null;
    }
  });
}

Future<MessageJson?> signalDecryptMessage(int source, Uint8List msg) async {
  try {
    final signalStore = (await getSignalStore())!;

    final session = SessionCipher.fromStore(
      signalStore,
      SignalProtocolAddress(source.toString(), defaultDeviceId),
    );

    final msgs = removeLastXBytes(msg, 4);
    if (msgs == null) {
      Log.error('Message requires at least 4 bytes.');
      return null;
    }
    final body = msgs[0];
    final type = bytesToInt(msgs[1]);
    Uint8List plaintext;
    if (type == CiphertextMessage.prekeyType) {
      final pre = PreKeySignalMessage(body);
      plaintext = await session.decrypt(pre);
    } else if (type == CiphertextMessage.whisperType) {
      final signalMsg = SignalMessage.fromSerialized(body);
      plaintext = await session.decryptFromSignal(signalMsg);
    } else {
      Log.error('Type not known: $type');
      return null;
    }
    return MessageJson.fromJson(
      jsonDecode(
        utf8.decode(
          gzip.decode(plaintext),
        ),
      ) as Map<String, dynamic>,
    );
  } catch (e) {
    Log.error(e.toString());
    return null;
  }
}
