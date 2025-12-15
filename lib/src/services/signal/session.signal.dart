import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';

Future<bool> createNewSignalSession(Response_UserData userData) async {
  final SignalProtocolStore? signalStore = await getSignalStore();

  if (signalStore == null) {
    return false;
  }

  final targetAddress = SignalProtocolAddress(
    userData.userId.toString(),
    defaultDeviceId,
  );

  final sessionBuilder = SessionBuilder.fromSignalStore(
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

  final tempSignedPreKeyId = userData.signedPrekeyId.toInt();

  final tempSignedPreKeyPublic = Curve.decodePoint(
    DjbECPublicKey(Uint8List.fromList(userData.signedPrekey)).serialize(),
    1,
  );

  final tempSignedPreKeySignature = Uint8List.fromList(
    userData.signedPrekeySignature,
  );

  final tempIdentityKey = IdentityKey(
    Curve.decodePoint(
      DjbECPublicKey(Uint8List.fromList(userData.publicIdentityKey))
          .serialize(),
      1,
    ),
  );

  final preKeyBundle = PreKeyBundle(
    userData.registrationId.toInt(),
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
    Log.error('could not process pre key bundle: $e');
    return false;
  }
}

Future<void> deleteSessionWithTarget(int target) async {
  final signalStore = await getSignalStore();
  if (signalStore == null) return;
  final address = SignalProtocolAddress(target.toString(), defaultDeviceId);
  await signalStore.sessionStore.deleteSession(address);
}

Future<Fingerprint?> generateSessionFingerPrint(int target) async {
  final signalStore = await getSignalStore();
  if (signalStore == null) return null;
  try {
    final targetIdentity = await signalStore
        .getIdentity(SignalProtocolAddress(target.toString(), defaultDeviceId));
    if (targetIdentity != null) {
      final generator = NumericFingerprintGenerator(5200);
      final localFingerprint = generator.createFor(
        1,
        Uint8List.fromList([gUser.userId]),
        (await signalStore.getIdentityKeyPair()).getPublicKey(),
        Uint8List.fromList([target]),
        targetIdentity,
      );

      return localFingerprint;
    }
    return null;
  } catch (e) {
    return null;
  }
}

Future<Uint8List?> getPublicKeyFromContact(int contactId) async {
  final signalStore = await getSignalStore();
  if (signalStore == null) return null;
  try {
    final targetIdentity = await signalStore.getIdentity(
      SignalProtocolAddress(
        contactId.toString(),
        defaultDeviceId,
      ),
    );
    if (targetIdentity != null) {
      return targetIdentity.publicKey.serialize();
    }
    return null;
  } catch (e) {
    return null;
  }
}
