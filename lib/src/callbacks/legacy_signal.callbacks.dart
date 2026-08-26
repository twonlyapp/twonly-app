import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:twonly/core/bridge/callbacks.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/signal/encryption.signal.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/utils/log.dart';

/// Flutter boundary for the legacy libsignal_protocol_dart implementation.
///
/// Only V1 CIPHERTEXT and PREKEY_BUNDLE messages may cross this boundary.
/// CIPHERTEXT_V2 remains fully Rust-owned.
abstract final class LegacySignalCallbacks {
  static Future<LegacySignalDecryptResult> decrypt(
    PlatformInt64 fromUserId,
    Uint8List ciphertext,
    int messageType,
  ) async {
    if (!_isLegacyMessageType(messageType)) {
      return const LegacySignalDecryptResult(
        decryptionErrorType: 0,
      );
    }

    try {
      final (content, errorType) = await signalDecryptMessageV1(
        fromUserId,
        ciphertext,
        messageType,
      );
      return LegacySignalDecryptResult(
        plaintext: content == null
            ? null
            : Uint8List.fromList(content.writeToBuffer()),
        decryptionErrorType: errorType?.value,
      );
    } catch (error) {
      Log.error('Legacy Signal decryption callback failed: $error');
      return const LegacySignalDecryptResult(decryptionErrorType: 0);
    }
  }

  static Future<LegacySignalEncryptResult?> encrypt(
    PlatformInt64 targetUserId,
    Uint8List plaintext,
  ) async {
    try {
      final encrypted = await signalEncryptMessage(
        targetUserId,
        plaintext,
      );
      if (encrypted == null || !_isLegacyMessageType(encrypted.type.value)) {
        return null;
      }
      return LegacySignalEncryptResult(
        ciphertext: encrypted.ciphertext,
        messageType: encrypted.type.value,
      );
    } catch (error) {
      Log.error('Legacy Signal encryption callback failed: $error');
      return null;
    }
  }

  static Future<List<LegacySignalPreKey>> generatePrekeys() async {
    try {
      final prekeys = await signalGetPreKeys();
      return prekeys
          .map(
            (prekey) => LegacySignalPreKey(
              id: prekey.id,
              publicKey: Uint8List.fromList(
                prekey.getKeyPair().publicKey.serialize(),
              ),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      Log.error('Legacy Signal prekey callback failed: $error');
      return const [];
    }
  }

  static bool _isLegacyMessageType(int messageType) =>
      messageType == pb.Message_Type.CIPHERTEXT.value ||
      messageType == pb.Message_Type.PREKEY_BUNDLE.value;
}
