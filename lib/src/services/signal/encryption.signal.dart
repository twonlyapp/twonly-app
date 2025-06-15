import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/prekeys.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

/// This caused some troubles, so protection the encryption...
final lockingSignalEncryption = Mutex();

Future<Uint8List?> signalEncryptMessage(
    int target, Uint8List plaintextContent) async {
  return await lockingSignalEncryption.protect<Uint8List?>(() async {
    try {
      ConnectSignalProtocolStore signalStore = (await getSignalStore())!;
      final address = SignalProtocolAddress(target.toString(), defaultDeviceId);

      SessionCipher session = SessionCipher.fromStore(signalStore, address);

      SignalContactPreKey? preKey = await getPreKeyByContactId(target);
      SignalContactSignedPreKey? signedPreKey =
          await getSignedPreKeyByContactId(target);

      if (signedPreKey != null) {
        SessionBuilder sessionBuilder = SessionBuilder.fromSignalStore(
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

        ECPublicKey? tempSignedPreKeyPublic = Curve.decodePoint(
          DjbECPublicKey(Uint8List.fromList(signedPreKey.signedPreKey))
              .serialize(),
          1,
        );

        Uint8List? tempSignedPreKeySignature = Uint8List.fromList(
          signedPreKey.signedPreKeySignature,
        );

        final IdentityKey? tempIdentityKey =
            await signalStore.getIdentity(address);
        if (tempIdentityKey != null) {
          PreKeyBundle preKeyBundle = PreKeyBundle(
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
            Log.error("could not process pre key bundle: $e");
          }
        } else {
          Log.error("did not get the identity of the remote address");
        }
      }

      final ciphertext = await session.encrypt(plaintextContent);

      var b = BytesBuilder();
      b.add(ciphertext.serialize());
      b.add(intToBytes(ciphertext.getType()));

      return b.takeBytes();
    } catch (e) {
      Log.error(e.toString());
      return null;
    }
  });
}

Future<MessageJson?> signalDecryptMessage(int source, Uint8List msg) async {
  try {
    ConnectSignalProtocolStore signalStore = (await getSignalStore())!;

    SessionCipher session = SessionCipher.fromStore(
        signalStore, SignalProtocolAddress(source.toString(), defaultDeviceId));

    List<Uint8List>? msgs = removeLastXBytes(msg, 4);
    if (msgs == null) {
      Log.error("Message requires at least 4 bytes.");
      return null;
    }
    Uint8List body = msgs[0];
    int type = bytesToInt(msgs[1]);
    Uint8List plaintext;
    if (type == CiphertextMessage.prekeyType) {
      PreKeySignalMessage pre = PreKeySignalMessage(body);
      plaintext = await session.decrypt(pre);
    } else if (type == CiphertextMessage.whisperType) {
      SignalMessage signalMsg = SignalMessage.fromSerialized(body);
      plaintext = await session.decryptFromSignal(signalMsg);
    } else {
      Log.error("Type not known: $type");
      return null;
    }
    return MessageJson.fromJson(
      jsonDecode(
        utf8.decode(
          gzip.decode(plaintext),
        ),
      ),
    );
  } catch (e) {
    Log.error(e.toString());
    return null;
  }
}
