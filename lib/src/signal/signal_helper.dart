import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/model/signal_identity_json.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart';
import 'package:twonly/src/utils.dart';

import 'connect_sender_key_store.dart';
import 'connect_signal_protocol_store.dart';

class SignalDataModel {
  Uint8List userId;
  ConnectSignalProtocolStore signalStore;
  ConnectSenderKeyStore senderKeyStore;
  SignalDataModel({
    required this.userId,
    required this.senderKeyStore,
    required this.signalStore,
  });
  // Session validation
  Future<Fingerprint?> generateSessionFingerPrint(String target) async {
    try {
      IdentityKey? targetIdentity = await signalStore.getIdentity(
          SignalProtocolAddress(target, SignalHelper.defaultDeviceId));
      if (targetIdentity != null) {
        final generator = NumericFingerprintGenerator(5200);
        final localFingerprint = generator.createFor(
          1,
          userId,
          (await signalStore.getIdentityKeyPair()).getPublicKey(),
          Uint8List.fromList(utf8.encode(target)),
          targetIdentity,
        );
        return localFingerprint;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // PreKeyBundle preKeyBundleFromJson(Map<String, dynamic> remoteBundle) {

  // }

  Future<String?> getEncryptedText(String text, String target) async {
    try {
      SessionCipher session = SessionCipher.fromStore(signalStore,
          SignalProtocolAddress(target, SignalHelper.defaultDeviceId));
      final ciphertext =
          await session.encrypt(Uint8List.fromList(utf8.encode(text)));
      Map<String, dynamic> data = {
        "msg": base64Encode(ciphertext.serialize()),
        "type": ciphertext.getType(),
      };
      return jsonEncode(data);
    } catch (e) {
      log(e.toString());
      return null;
    }
  }

  Future<String?> getDecryptedText(String source, String msg) async {
    try {
      SessionCipher session = SessionCipher.fromStore(signalStore,
          SignalProtocolAddress(source, SignalHelper.defaultDeviceId));
      Map data = jsonDecode(msg);
      if (data["type"] == CiphertextMessage.prekeyType) {
        PreKeySignalMessage pre =
            PreKeySignalMessage(base64Decode(data["msg"]));
        Uint8List plaintext = await session.decrypt(pre);
        String dectext = utf8.decode(plaintext);
        return dectext;
      } else if (data["type"] == CiphertextMessage.whisperType) {
        SignalMessage signalMsg =
            SignalMessage.fromSerialized(base64Decode(data["msg"]));
        Uint8List plaintext = await session.decryptFromSignal(signalMsg);
        String dectext = utf8.decode(plaintext);
        return dectext;
      } else {
        return null;
      }
    } catch (e) {
      log(e.toString());
      return null;
    }
  }
}

int userIdToRegistrationId(List<int> userId) {
  int result = 0;
  for (int i = 8; i < 16; i++) {
    result = (result << 8) | userId[i];
  }
  return result;
}

String uint8ListToHex(List<int> list) {
  final StringBuffer hexBuffer = StringBuffer();
  for (int byte in list) {
    hexBuffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return hexBuffer.toString().toUpperCase();
}

class SignalHelper {
  static const int defaultDeviceId = 1;

  static Future<ECPrivateKey?> getPrivateKey() async {
    final signalIdentity = await getSignalIdentity();
    if (signalIdentity == null) {
      return null;
    }

    final IdentityKeyPair identityKeyPair =
        IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

    return identityKeyPair.getPrivateKey();
  }

  static Future<bool> addNewContact(Response_UserData userData) async {
    final Int64 userId = userData.userId;

    SignalProtocolAddress targetAddress =
        SignalProtocolAddress(userId.toString(), SignalHelper.defaultDeviceId);

    SignalProtocolStore? signalStore = await SignalHelper.getSignalStore();
    if (signalStore == null) {
      return false;
    }

    SessionBuilder sessionBuilder =
        SessionBuilder.fromSignalStore(signalStore, targetAddress);

    ECPublicKey? tempPrePublicKey;
    int? tempPreKeyId;
    if (userData.prekeys.isNotEmpty) {
      tempPrePublicKey = Curve.decodePoint(
          DjbECPublicKey(Uint8List.fromList(userData.prekeys.first.prekey))
              .serialize(),
          1);
      tempPreKeyId = userData.prekeys.first.id.toInt();
    }
    // Signed pre key calculation
    int tempSignedPreKeyId = userData.signedPrekeyId.toInt();
    // Map? tempSignedPreKey = remoteBundle["signedPreKey"];
    ECPublicKey? tempSignedPreKeyPublic;
    Uint8List? tempSignedPreKeySignature;
    // if (tempSignedPreKey != null) {
    tempSignedPreKeyPublic = Curve.decodePoint(
        DjbECPublicKey(Uint8List.fromList(userData.signedPrekey)).serialize(),
        1);
    tempSignedPreKeySignature =
        Uint8List.fromList(userData.signedPrekeySignature);
    // }
    // Identity key calculation
    IdentityKey tempIdentityKey = IdentityKey(Curve.decodePoint(
        DjbECPublicKey(Uint8List.fromList(userData.publicIdentityKey))
            .serialize(),
        1));
    PreKeyBundle preKeyBundle = PreKeyBundle(
      userData.userId.toInt(),
      1,
      tempPreKeyId,
      tempPrePublicKey,
      tempSignedPreKeyId,
      tempSignedPreKeyPublic,
      tempSignedPreKeySignature,
      tempIdentityKey,
    );

    try {
      await sessionBuilder.processPreKeyBundle(preKeyBundle);
      return true;
    } catch (e) {
      Logger("signal_helper").shout("Error: $e");
      return false;
    }
  }

  static Future<ConnectSignalProtocolStore?> getSignalStore() async {
    return await getSignalStoreFromIdentity((await getSignalIdentity())!);
  }

  static Future<SignalIdentity?> getSignalIdentity() async {
    final storage = getSecureStorage();
    final signalIdentityJson = await storage.read(key: "signal_identity");
    if (signalIdentityJson == null) {
      return null;
    }

    return SignalIdentity.fromJson(jsonDecode(signalIdentityJson));
  }

  static Future<ConnectSignalProtocolStore> getSignalStoreFromIdentity(
      SignalIdentity signalIdentity) async {
    final IdentityKeyPair identityKeyPair =
        IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

    return ConnectSignalProtocolStore(
        identityKeyPair, signalIdentity.registrationId.toInt());
  }

  static Future<List<PreKeyRecord>> getPreKeys() async {
    final preKeys = generatePreKeys(0, 200);
    final signalStore = await getSignalStore();
    if (signalStore == null) return [];
    for (final p in preKeys) {
      await signalStore.preKeyStore.storePreKey(p.id, p);
    }
    return preKeys;
  }

  static Future createIfNotExistsSignalIdentity() async {
    final storage = getSecureStorage();

    final signalIdentity = await storage.read(key: "signal_identity");
    if (signalIdentity != null) {
      return;
    }

    final identityKeyPair = generateIdentityKeyPair();
    final registrationId = generateRegistrationId(true);

    ConnectSignalProtocolStore signalStore =
        ConnectSignalProtocolStore(identityKeyPair, registrationId);

    final signedPreKey =
        generateSignedPreKey(identityKeyPair, SignalHelper.defaultDeviceId);

    await signalStore.signedPreKeyStore
        .storeSignedPreKey(signedPreKey.id, signedPreKey);

    final storedSignalIdentity = SignalIdentity(
        identityKeyPairU8List: identityKeyPair.serialize(),
        registrationId: Int64(registrationId));

    await storage.write(
        key: "signal_identity", value: jsonEncode(storedSignalIdentity));
  }
}
