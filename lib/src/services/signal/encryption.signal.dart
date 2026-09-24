import 'dart:typed_data';

import 'package:drift/drift.dart' as drift;
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/invalid_message_exception.dart';
import 'package:twonly/core/bridge/wrapper/signal.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/contacts.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api/messages.api.dart';
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
    return _signalEncryptMessageV1(target, plaintextContent);
  });
}

Future<SignalEncryptResult?> signalEncryptMessageV2(
  int target,
  Uint8List plaintextContent,
) async {
  try {
    final res = await RustSignal.encrypt(
      name: target.toString(),
      deviceId: 1,
      plaintext: plaintextContent,
    );
    return SignalEncryptResult(res, pb.Message_Type.CIPHERTEXT_V2);
  } catch (e) {
    Log.error('Could not encrypt message (V2) for target $target: $e');
    return null;
  }
}

Future<SignalEncryptResult?> _signalEncryptMessageV1(
  int target,
  Uint8List plaintextContent,
) async {
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
    Log.error('Could not encrypt message (V1) for target $target: $e');
    return null;
  }
}

/// Contacts whose session failed in the current batch of server messages, per
/// Signal version: a broken V1 session says nothing about the V2 session.
typedef BrokenSignalSessions = Set<(int, SignalVersion)>;

Future<(pb.EncryptedContent?, pb.PlaintextContent_DecryptionErrorMessage_Type?)>
signalDecryptMessageV2(
  int fromUserId,
  Uint8List encryptedContentRaw, {
  BrokenSignalSessions? brokenSessionsInCurrentBatch,
}) async {
  Log.info('Acquiring lockingSignalProtocol for $fromUserId (V2)');
  final (
    decryptedContent,
    errorType,
    needsResync,
  ) = await lockingSignalProtocol.protect(() async {
    Log.info('Lock acquired for $fromUserId (V2)');
    try {
      final plaintext = await RustSignal.decrypt(
        name: fromUserId.toString(),
        deviceId: 1,
        ciphertext: encryptedContentRaw,
      );
      recordResyncAttempt(fromUserId, SignalVersion.v2, success: true);
      return (pb.EncryptedContent.fromBuffer(plaintext), null, false);
    } catch (e) {
      if (_isDuplicatedMessageError(e)) {
        // Same as the DuplicateMessageException in V1: the message was
        // decrypted before but not processed, so the session is intact and
        // only the message has to be requested again.
        Log.info('Message (V2) from $fromUserId was already decrypted: $e');
        return (
          null,
          pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
          false,
        );
      }
      Log.error('Could not decrypt message (V2) from $fromUserId: $e');
      return (
        null,
        pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
        true, // Needs resync on failure
      );
    }
  });

  Log.info('Released lockingSignalProtocol for $fromUserId (V2)');

  if (decryptedContent != null) {
    await _useSignalV2For(fromUserId);
  }

  if (needsResync) {
    brokenSessionsInCurrentBatch?.add((fromUserId, SignalVersion.v2));
    if (shouldAttemptResync(fromUserId, SignalVersion.v2)) {
      if (await handleSessionResync(fromUserId)) {
        recordResyncAttempt(fromUserId, SignalVersion.v2, success: false);
        await sendCipherText(
          fromUserId,
          pb.EncryptedContent(
            errorMessages: pb.EncryptedContent_ErrorMessages(
              type: pb.EncryptedContent_ErrorMessages_Type.SESSION_OUT_OF_SYNC,
            ),
          ),
        );
      }
    }
  }

  return (decryptedContent, errorType);
}

Future<(pb.EncryptedContent?, pb.PlaintextContent_DecryptionErrorMessage_Type?)>
signalDecryptMessageV1(
  int fromUserId,
  Uint8List encryptedContentRaw,
  int type, {
  BrokenSignalSessions? brokenSessionsInCurrentBatch,
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

      final signalStore = (await getSignalStore())!;
      final address = getSignalAddress(fromUserId);
      final session = SessionCipher.fromStore(signalStore, address);

      Uint8List plaintext;

      switch (type) {
        case CiphertextMessage.prekeyType:
          plaintext = await session.decrypt(
            PreKeySignalMessage(encryptedContentRaw),
          );
        case CiphertextMessage.whisperType:
          final message = SignalMessage.fromSerialized(encryptedContentRaw);
          if (isBeyondReceivingWindow(
            await signalStore.loadSession(address),
            message,
          )) {
            throw InvalidMessageException(
              'No valid sessions. Counter ${message.getCounter()} is beyond '
              'the receiving window of every session state.',
            );
          }
          plaintext = await session.decryptFromSignal(message);
        default:
          Log.error('Unknown Message Decryption Type: $type');
          return (
            null,
            pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN,
            false,
          );
      }

      recordResyncAttempt(fromUserId, SignalVersion.v1, success: true);
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
    brokenSessionsInCurrentBatch?.add((fromUserId, SignalVersion.v1));
    if (shouldAttemptResync(fromUserId, SignalVersion.v1)) {
      return (decryptedContent, await _recoverFromBrokenV1Session(fromUserId));
    }
  }

  return (decryptedContent, errorType);
}

/// Repairs the connection after a V1 message could not be decrypted and
/// returns the decryption error to report back to the sender.
Future<pb.PlaintextContent_DecryptionErrorMessage_Type>
_recoverFromBrokenV1Session(int fromUserId) async {
  var contact = await twonlyDB.contactsDao.getContactById(fromUserId);
  if (contact?.signalVersion == SignalVersion.v2) {
    // Our V2 session is not affected, rebuilding it would not help.
    recordResyncAttempt(fromUserId, SignalVersion.v1, success: false);
  } else {
    if (!await handleSessionResync(fromUserId)) {
      return pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN;
    }
    // This flag prevents from resyncing the session the client received
    // multiple new messages from the server he could not decrypt
    recordResyncAttempt(fromUserId, SignalVersion.v1, success: false);

    // This message contains a new PreKeyBundle establishing a new signal
    // session
    await sendCipherText(
      fromUserId,
      pb.EncryptedContent(
        errorMessages: pb.EncryptedContent_ErrorMessages(
          type: pb.EncryptedContent_ErrorMessages_Type.SESSION_OUT_OF_SYNC,
        ),
      ),
    );
    contact = await twonlyDB.contactsDao.getContactById(fromUserId);
    if (contact?.signalVersion != SignalVersion.v2) {
      return pb.PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN;
    }
  }
  // We answer this contact over V2, so a SESSION_OUT_OF_SYNC travels over V2
  // as well and leaves the sender's V1 session broken: versions before 0.5.3
  // keep sending V1 until they process our bundle. PREKEY_UNKNOWN makes the
  // sender (any version) rebuild its session from our current bundle, which
  // is V2 once we publish one, and resend the message.
  return pb.PlaintextContent_DecryptionErrorMessage_Type.PREKEY_UNKNOWN;
}

/// Receiving over V2 proves that the Rust store holds a working session with
/// the sender. A contact still marked V1 is switched, so replies no longer go
/// over a V1 session that the sender may have repaired over V2 only.
Future<void> _useSignalV2For(int contactId) async {
  final contact = await twonlyDB.contactsDao.getContactById(contactId);
  if (contact == null || contact.signalVersion == SignalVersion.v2) return;
  Log.info('Got a V2 message from $contactId, switching the contact to V2.');
  await twonlyDB.contactsDao.updateContact(
    contactId,
    const ContactsCompanion(signalVersion: drift.Value(SignalVersion.v2)),
  );
}

/// Rust reports libsignal's DuplicatedMessage as
/// `TwonlyError::DuplicatedSignalMessage`, which reaches Dart as text only.
bool _isDuplicatedMessageError(Object error) =>
    error.toString().contains('Duplicated Signal message');

/// libsignal_protocol_dart refuses to skip more message keys than this on a
/// single receiving chain (see SessionCipher._getOrCreateMessageKeys).
const _maxSkippedMessageKeys = 2000;

/// Whether libsignal_protocol_dart is certain to reject [message] because its
/// counter lies more than [_maxSkippedMessageKeys] ahead in every session state
/// that could otherwise decrypt it.
///
/// libsignal only reaches that verdict after deriving a new receiving chain,
/// two ECDH operations and a key generation, for each archived state. With a
/// few dozen states that blocks the isolate for seconds per message, while the
/// chain indices alone give the same answer.
bool isBeyondReceivingWindow(SessionRecord record, SignalMessage message) {
  final ratchetKey = message.getSenderRatchetKey();
  final counter = message.getCounter();
  var rejectedStates = 0;
  for (final state in [record.sessionState, ...record.previousSessionStates]) {
    // libsignal rejects these states before it looks at the counter.
    if (!state.hasSenderChain() ||
        state.getSessionVersion() != message.getMessageVersion()) {
      continue;
    }
    // Without a chain for this ratchet key libsignal starts one at index 0.
    final index = state.getReceiverChainKey(ratchetKey)?.index ?? 0;
    if (counter - index <= _maxSkippedMessageKeys) return false;
    rejectedStates++;
  }
  return rejectedStates > 0;
}
