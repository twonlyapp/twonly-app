import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/json/signal_identity.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart';
import 'package:twonly/src/providers/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

const int defaultDeviceId = 1;

Future<ECPrivateKey?> getPrivateKey() async {
  final signalIdentity = await getSignalIdentity();
  if (signalIdentity == null) {
    return null;
  }

  final IdentityKeyPair identityKeyPair =
      IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

  return identityKeyPair.getPrivateKey();
}

Future<bool> addNewContact(Response_UserData userData) async {
  final int userId = userData.userId.toInt();

  SignalProtocolAddress targetAddress =
      SignalProtocolAddress(userId.toString(), defaultDeviceId);

  SignalProtocolStore? signalStore = await getSignalStore();
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

  int tempSignedPreKeyId = userData.signedPrekeyId.toInt();

  ECPublicKey? tempSignedPreKeyPublic = Curve.decodePoint(
      DjbECPublicKey(Uint8List.fromList(userData.signedPrekey)).serialize(), 1);

  Uint8List? tempSignedPreKeySignature =
      Uint8List.fromList(userData.signedPrekeySignature);

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

Future<ConnectSignalProtocolStore?> getSignalStore() async {
  return await getSignalStoreFromIdentity((await getSignalIdentity())!);
}

Future<SignalIdentity?> getSignalIdentity() async {
  try {
    final storage = FlutterSecureStorage();
    final signalIdentityJson = await storage.read(key: "signal_identity");
    if (signalIdentityJson == null) {
      return null;
    }
    return SignalIdentity.fromJson(jsonDecode(signalIdentityJson));
  } catch (e) {
    Logger("signal.dart/getSignalIdentity").shout(e);
    return null;
  }
}

Future<ConnectSignalProtocolStore> getSignalStoreFromIdentity(
    SignalIdentity signalIdentity) async {
  final IdentityKeyPair identityKeyPair =
      IdentityKeyPair.fromSerialized(signalIdentity.identityKeyPairU8List);

  return ConnectSignalProtocolStore(
      identityKeyPair, signalIdentity.registrationId.toInt());
}

Future<List<PreKeyRecord>> getPreKeys() async {
  final preKeys = generatePreKeys(0, 200);
  final signalStore = await getSignalStore();
  if (signalStore == null) return [];
  for (final p in preKeys) {
    await signalStore.preKeyStore.storePreKey(p.id, p);
  }
  return preKeys;
}

Future createIfNotExistsSignalIdentity() async {
  final storage = FlutterSecureStorage();

  final signalIdentity = await storage.read(key: "signal_identity");
  if (signalIdentity != null) {
    return;
  }

  final identityKeyPair = generateIdentityKeyPair();
  final registrationId = generateRegistrationId(true);

  ConnectSignalProtocolStore signalStore =
      ConnectSignalProtocolStore(identityKeyPair, registrationId);

  final signedPreKey = generateSignedPreKey(identityKeyPair, defaultDeviceId);

  await signalStore.signedPreKeyStore
      .storeSignedPreKey(signedPreKey.id, signedPreKey);

  final storedSignalIdentity = SignalIdentity(
    identityKeyPairU8List: identityKeyPair.serialize(),
    registrationId: registrationId,
  );

  await storage.write(
      key: "signal_identity", value: jsonEncode(storedSignalIdentity));
}

Future<Fingerprint?> generateSessionFingerPrint(int target) async {
  ConnectSignalProtocolStore? signalStore = await getSignalStore();
  UserData? user = await getUser();
  if (signalStore == null || user == null) return null;
  try {
    IdentityKey? targetIdentity = await signalStore
        .getIdentity(SignalProtocolAddress(target.toString(), defaultDeviceId));
    if (targetIdentity != null) {
      final generator = NumericFingerprintGenerator(5200);
      final localFingerprint = generator.createFor(
        1,
        Uint8List.fromList([user.userId.toInt()]),
        (await signalStore.getIdentityKeyPair()).getPublicKey(),
        Uint8List.fromList([target.toInt()]),
        targetIdentity,
      );

      return localFingerprint;
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<Uint8List?> encryptMessage(MessageJson msg, int target) async {
  try {
    ConnectSignalProtocolStore signalStore = (await getSignalStore())!;

    SessionCipher session = SessionCipher.fromStore(
        signalStore, SignalProtocolAddress(target.toString(), defaultDeviceId));

    final ciphertext = await session.encrypt(
        Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(msg.toJson())))));

    var b = BytesBuilder();
    b.add(ciphertext.serialize());
    b.add(intToBytes(ciphertext.getType()));

    return b.takeBytes();
  } catch (e) {
    Logger("utils/signal").shout(e.toString());
    return null;
  }
}

Future<MessageJson?> getDecryptedText(int source, Uint8List msg) async {
  try {
    ConnectSignalProtocolStore signalStore = (await getSignalStore())!;

    SessionCipher session = SessionCipher.fromStore(
        signalStore, SignalProtocolAddress(source.toString(), defaultDeviceId));

    List<Uint8List>? msgs = removeLastXBytes(msg, 4);
    if (msgs == null) return null;
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
      return null;
    }
    MessageJson dectext =
        MessageJson.fromJson(jsonDecode(utf8.decode(gzip.decode(plaintext))));
    return dectext;
  } catch (e) {
    Logger("utils/signal").shout(e.toString());
    return null;
  }
}
