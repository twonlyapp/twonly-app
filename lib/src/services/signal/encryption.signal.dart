import 'dart:typed_data';

import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/invalid_message_exception.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/signal/protocol_state.signal.dart';
import 'package:twonly/src/services/signal/session.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';

class SignalEncryptResult {
  SignalEncryptResult(this.ciphertext, this.type);
  final Uint8List ciphertext;
  final pb.Message_Type type;
}

Future<SignalEncryptResult?> signalEncryptMessage(
  int target,
  Uint8List plaintextContent,
) async {
  return lockingSignalProtocol.protect<SignalEncryptResult?>(() async {
    try {
      final signalStore = (await getSignalStore())!;
      final address = getSignalAddress(target);
      final session = SessionCipher.fromStore(signalStore, address);
      final cipherText = await session.encrypt(plaintextContent);

      pb.Message_Type type;
      switch (cipherText.getType()) {
        case CiphertextMessage.prekeyType:
          type = pb.Message_Type.PREKEY_BUNDLE;
        case CiphertextMessage.whisperType:
          type = pb.Message_Type.CIPHERTEXT;
        default:
          Log.error('Invalid ciphertext type: ${cipherText.getType()}.');
          return null;
      }

      return SignalEncryptResult(cipherText.serialize(), type);
    } catch (e) {
      Log.error('Could not encrypt message for target $target: $e');
      return null;
    }
  });
}

Future<(pb.EncryptedContent?, pb.PlaintextContent_DecryptionErrorMessage_Type?)>
signalDecryptMessageV1(
  int fromUserId,
  Uint8List encryptedContentRaw,
  int type, {
  Set<int>? brokenSessionsInCurrentBatch,
}) async {
  Log.info('Acquiring lockingSignalProtocol for $fromUserId (V1)');
  final (
    decryptedContent,
    errorType,
    needsResync,
  ) = await lockingSignalProtocol.protect(() async {
    Log.info('Lock acquired for $fromUserId (V1)');
    try {
      // Yield execution to the event loop to prevent UI freezing during bulk decryption
      await Future.delayed(Duration.zero);

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
            pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
            false,
          );
      }

      recordResyncAttempt(fromUserId, success: true);
      return (pb.EncryptedContent.fromBuffer(plaintext), null, false);
    } on InvalidKeyIdException catch (e) {
      Log.warn(e);
      return (
        null,
        pb.PlaintextContent_DecryptionErrorMessage_Type.PREKEY_UNKNOWN,
        false,
      );
    } on DuplicateMessageException catch (e) {
      // This is normal behavior: This can happen in case a message was decrypted, but before further processing
      // the user killed the app. This results in a new transmission from the server, but as the message was already
      // decrypted, this error happens. In this case, request the message again.
      Log.info(e);
      return (
        null,
        pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
        false,
      );
    } on InvalidMessageException catch (e) {
      Log.warn(e);
      return (
        null,
        pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
        true,
      );
    } catch (e) {
      Log.error(e);
      return (
        null,
        pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
        false,
      );
    }
  });

  Log.info('Released lockingSignalProtocol for $fromUserId (V1)');

  // Handle session resync OUTSIDE the lock to avoid holding it during
  // network round-trips (which can block for up to 60 seconds)
  if (needsResync) {
    brokenSessionsInCurrentBatch?.add(fromUserId);
    if (shouldAttemptResync(fromUserId)) {
      if (await handleSessionResync(fromUserId)) {
        // This flag prevents from resyncing the session the client received
        // multiple new messages from the server he could not decrypt
        recordResyncAttempt(fromUserId, success: false);

        // This message contains a new PreKeyBundle establishing a new signal
        // session
        await RustApi.sendEncryptedContent(
          contactId: fromUserId,
          content: pb.EncryptedContent(
            errorMessages: pb.EncryptedContent_ErrorMessages(
              type: pb.EncryptedContent_ErrorMessages_Type.SESSION_OUT_OF_SYNC,
            ),
          ).writeToBuffer(),
          onlySendIfNoReceiptsAreOpen: false,
          onlyReturnEncryptedData: false,
          blocking: true,
        );
      }
    }
  }

  return (decryptedContent, errorType);
}
