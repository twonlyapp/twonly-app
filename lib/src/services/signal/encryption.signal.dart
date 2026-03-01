import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';

/// This caused some troubles, so protection the encryption...
final lockingSignalEncryption = Mutex();

Future<CiphertextMessage?> signalEncryptMessage(
  int target,
  Uint8List plaintextContent,
) async {
  return lockingSignalEncryption.protect<CiphertextMessage?>(() async {
    try {
      final signalStore = (await getSignalStore())!;
      final address = SignalProtocolAddress(target.toString(), defaultDeviceId);
      final session = SessionCipher.fromStore(signalStore, address);
      return await session.encrypt(plaintextContent);
    } catch (e) {
      Log.error(e.toString());
      return null;
    }
  });
}

Future<(EncryptedContent?, PlaintextContent_DecryptionErrorMessage_Type?)>
    signalDecryptMessage(
  int source,
  Uint8List encryptedContentRaw,
  int type,
) async {
  try {
    final session = SessionCipher.fromStore(
      (await getSignalStore())!,
      SignalProtocolAddress(source.toString(), defaultDeviceId),
    );

    Uint8List plaintext;

    switch (type) {
      case CiphertextMessage.prekeyType:
        plaintext = await session.decrypt(
          PreKeySignalMessage(encryptedContentRaw),
        );
      case CiphertextMessage.whisperType:
        plaintext = await session.decryptFromSignal(
          SignalMessage.fromSerialized(encryptedContentRaw),
        );
      default:
        Log.error('Unknown Message Decryption Type: $type');
        return (null, PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN);
    }

    return (EncryptedContent.fromBuffer(plaintext), null);
  } on InvalidKeyIdException catch (e) {
    Log.warn(e);
    return (null, PlaintextContent_DecryptionErrorMessage_Type.PREKEY_UNKNOWN);
  } catch (e) {
    Log.error(e);
    return (null, PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN);
  }
}
