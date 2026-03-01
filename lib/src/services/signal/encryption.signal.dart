import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/invalid_message_exception.dart';
import 'package:mutex/mutex.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
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
      final address = getSignalAddress(target);
      final session = SessionCipher.fromStore(signalStore, address);
      return await session.encrypt(plaintextContent);
    } catch (e) {
      Log.error(e.toString());
      return null;
    }
  });
}

bool alreadyPerformedAnResync = false;

Future<(EncryptedContent?, PlaintextContent_DecryptionErrorMessage_Type?)>
    signalDecryptMessage(
  int fromUserId,
  Uint8List encryptedContentRaw,
  int type,
) async {
  try {
    final session = SessionCipher.fromStore(
      (await getSignalStore())!,
      getSignalAddress(fromUserId),
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
  } on InvalidMessageException catch (e) {
    if (!alreadyPerformedAnResync) {
      if (await handleSessionResync(fromUserId)) {
        // This flag prevents from resyncing the session the client received multiple new
        // messages from the server he could not decrypt
        alreadyPerformedAnResync = true;

        // This message contains a new PreKeyBundle establishing a new signal session
        await sendCipherText(
          fromUserId,
          EncryptedContent(
            errorMessages: EncryptedContent_ErrorMessages(
              type: EncryptedContent_ErrorMessages_Type.SESSION_OUT_OF_SYNC,
            ),
          ),
        );
      }
    }
    Log.warn(e);
    return (null, PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN);
  } catch (e) {
    Log.error(e);
    return (null, PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN);
  }
}
