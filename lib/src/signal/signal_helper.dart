import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/model/signal_identity_json.dart';
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

  // one to one implementation
  Future<void> buildSession(
    String target,
    Map<String, dynamic> remoteBundle,
  ) async {
    SignalProtocolAddress targetAddress =
        SignalProtocolAddress(target, SignalHelper.defaultDeviceId);
    SessionBuilder sessionBuilder =
        SessionBuilder.fromSignalStore(signalStore, targetAddress);
    PreKeyBundle temp = preKeyBundleFromJson(remoteBundle);
    await sessionBuilder.processPreKeyBundle(temp);
  }

  PreKeyBundle preKeyBundleFromJson(Map<String, dynamic> remoteBundle) {
    // One time pre key calculation
    List tempPreKeys = remoteBundle["preKeys"];
    ECPublicKey? tempPrePublicKey;
    int? tempPreKeyId;
    if (tempPreKeys.isNotEmpty) {
      tempPrePublicKey = Curve.decodePoint(
          DjbECPublicKey(base64Decode(tempPreKeys.first['key'])).serialize(),
          1);
      tempPreKeyId = remoteBundle["preKeys"].first['id'];
    }
    // Signed pre key calculation
    int tempSignedPreKeyId = remoteBundle["signedPreKey"]['id'];
    Map? tempSignedPreKey = remoteBundle["signedPreKey"];
    ECPublicKey? tempSignedPreKeyPublic;
    Uint8List? tempSignedPreKeySignature;
    if (tempSignedPreKey != null) {
      tempSignedPreKeyPublic = Curve.decodePoint(
          DjbECPublicKey(base64Decode(remoteBundle["signedPreKey"]['key']))
              .serialize(),
          1);
      tempSignedPreKeySignature =
          base64Decode(remoteBundle["signedPreKey"]['signature']);
    }
    // Identity key calculation
    IdentityKey tempIdentityKey = IdentityKey(Curve.decodePoint(
        DjbECPublicKey(base64Decode(remoteBundle["identityKey"])).serialize(),
        1));
    return PreKeyBundle(
      remoteBundle['registrationId'],
      1,
      tempPreKeyId,
      tempPrePublicKey,
      tempSignedPreKeyId,
      tempSignedPreKeyPublic,
      tempSignedPreKeySignature,
      tempIdentityKey,
    );
  }

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

class SignalHelper {
  static const int defaultDeviceId = 1;

  static Future<Map<String, dynamic>?> getRegisterData() async {
    final storage = getSecureStorage();
    final signalIdentityJson = await storage.read(key: "signal_identity");
    if (signalIdentityJson == null) {
      return null;
    }

    print(signalIdentityJson);
    final SignalIdentity signalIdentity =
        SignalIdentity.fromJson(jsonDecode(signalIdentityJson));

    final identityKeyPair =
        IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);
    // final publicKey = identityKeyPair.getPublicKey().serialize();

    ConnectSignalProtocolStore signalStore = ConnectSignalProtocolStore(
        identityKeyPair, signalIdentity.registrationId);

    final signedPreKey = (await signalStore.loadSignedPreKeys())[0];
    final Map<String, dynamic> req = {};
    req['registrationId'] = signalIdentity.registrationId;
    req['identityKey'] =
        (await signalStore.getIdentityKeyPair()).getPublicKey().serialize();

    req['signedPreKey'] = {
      'id': signedPreKey.id,
      'signature': signedPreKey.signature,
      'key': signedPreKey.getKeyPair().publicKey.serialize(),
    };
    // List pKeysList = [];
    // for (PreKeyRecord pKey in preKeys) {
    //   Map<String, dynamic> pKeys = {};
    //   pKeys['id'] = pKey.id;
    //   pKeys['key'] = base64Encode(pKey.getKeyPair().publicKey.serialize());
    //   pKeysList.add(pKeys);
    // }
    // req['preKeys'] = pKeysList;
    return req;
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

    final preKeys = generatePreKeys(0, 100);
    final signedPreKey =
        generateSignedPreKey(identityKeyPair, SignalHelper.defaultDeviceId);

    for (final p in preKeys) {
      await signalStore.preKeyStore.storePreKey(p.id, p);
    }

    await signalStore.signedPreKeyStore
        .storeSignedPreKey(signedPreKey.id, signedPreKey);

    final storedSignalIdentity = SignalIdentity(
        identityKeyPairU8List: identityKeyPair.serialize(),
        registrationId: registrationId);

    await storage.write(
        key: "signal_identity", value: jsonEncode(storedSignalIdentity));
  }
}
