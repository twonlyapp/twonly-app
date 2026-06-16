import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/invalid_message_exception.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/signal/protocol_state.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';

Future<CiphertextMessage?> signalEncryptMessage(
  int target,
  Uint8List plaintextContent,
) async {
  return lockingSignalProtocol.protect<CiphertextMessage?>(() async {
    return _signalEncryptMessage(target, plaintextContent);
  });
}

Future<CiphertextMessage?> _signalEncryptMessage(
  int target,
  Uint8List plaintextContent,
) async {
  try {
    final signalStore = (await getSignalStore())!;
    final address = getSignalAddress(target);
    final session = SessionCipher.fromStore(signalStore, address);
    return await session.encrypt(plaintextContent);
  } catch (e) {
    Log.error('Could not encrypt message for target $target: $e');
    return null;
  }
}

Future<(EncryptedContent?, PlaintextContent_DecryptionErrorMessage_Type?)>
signalDecryptMessage(
  int fromUserId,
  Uint8List encryptedContentRaw,
  int type,
) async {
  // Hold the lock only for the cryptographic operation, not for network I/O
  Log.info('Acquiring lockingSignalProtocol for $fromUserId');
  final (
    decryptedContent,
    errorType,
    needsResync,
  ) = await lockingSignalProtocol.protect(() async {
    Log.info('Lock acquired for $fromUserId');
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
          return (
            null,
            PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
            false,
          );
      }

      return (EncryptedContent.fromBuffer(plaintext), null, false);
    } on InvalidKeyIdException catch (e) {
      Log.warn(e);
      return (
        null,
        PlaintextContent_DecryptionErrorMessage_Type.PREKEY_UNKNOWN,
        false,
      );
    } on DuplicateMessageException catch (e) {
      // This is normal behavior: This can happen in case a message was decrypted, but before further processing
      // the user killed the app. This results in a new transmission from the server, but as the message was already
      // decrypted, this error happens. In this case, request the message again.
      Log.info(e);
      return (
        null,
        PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
        false,
      );
    } on InvalidMessageException catch (e) {
      Log.warn(e);
      return (
        null,
        PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
        true,
      );
    } catch (e) {
      Log.error(e);
      return (
        null,
        PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
        false,
      );
    }
  });

  Log.info('Released lockingSignalProtocol for $fromUserId');

  // Handle session resync OUTSIDE the lock to avoid holding it during
  // network round-trips (which can block for up to 60 seconds)
  if (needsResync && !resyncedUsers.contains(fromUserId)) {
    if (await handleSessionResync(fromUserId)) {
      // This flag prevents from resyncing the session the client received
      // multiple new messages from the server he could not decrypt
      resyncedUsers.add(fromUserId);

      // This message contains a new PreKeyBundle establishing a new signal
      // session
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

  return (decryptedContent, errorType);
}
