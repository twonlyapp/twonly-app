import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

Future<bool> createNewSignalSession(Response_UserData userData) async {
  SignalProtocolStore? signalStore = await getSignalStore();

  if (signalStore == null) {
    return false;
  }

  SignalProtocolAddress targetAddress = SignalProtocolAddress(
    userData.userId.toString(),
    defaultDeviceId,
  );

  SessionBuilder sessionBuilder = SessionBuilder.fromSignalStore(
    signalStore,
    targetAddress,
  );

  ECPublicKey? tempPrePublicKey;
  int? tempPreKeyId;

  if (userData.prekeys.isNotEmpty) {
    tempPrePublicKey = Curve.decodePoint(
      DjbECPublicKey(
        Uint8List.fromList(userData.prekeys.first.prekey),
      ).serialize(),
      1,
    );
    tempPreKeyId = userData.prekeys.first.id.toInt();
  }

  int tempSignedPreKeyId = userData.signedPrekeyId.toInt();

  ECPublicKey? tempSignedPreKeyPublic = Curve.decodePoint(
    DjbECPublicKey(Uint8List.fromList(userData.signedPrekey)).serialize(),
    1,
  );

  Uint8List? tempSignedPreKeySignature = Uint8List.fromList(
    userData.signedPrekeySignature,
  );

  IdentityKey tempIdentityKey = IdentityKey(
    Curve.decodePoint(
      DjbECPublicKey(Uint8List.fromList(userData.publicIdentityKey))
          .serialize(),
      1,
    ),
  );

  PreKeyBundle preKeyBundle = PreKeyBundle(
    userData.userId.toInt(),
    defaultDeviceId,
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
    Log.error("could not process pre key bundle: $e");
    return false;
  }
}

Future deleteSessionWithTarget(int target) async {
  ConnectSignalProtocolStore? signalStore = await getSignalStore();
  if (signalStore == null) return;
  final address = SignalProtocolAddress(target.toString(), defaultDeviceId);
  await signalStore.sessionStore.deleteSession(address);
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
