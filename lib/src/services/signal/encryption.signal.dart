import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/model/protobuf/api/server_to_client.pb.dart'
    as server;

class OtherPreKeys {
  OtherPreKeys({
    required this.preKeys,
    required this.signedPreKey,
    required this.signedPreKeyId,
    required this.signedPreKeySignature,
  });
  final List<server.Response_PreKey> preKeys;
  final int signedPreKeyId;
  final List<int> signedPreKey;
  final List<int> signedPreKeySignature;
}

// Future<void> deleteSession(String userId) async {
//   await mixinSignalProtocolStore.sessionStore.sessionDao
//       .deleteSessionsByAddress(userId);
// }

// Future<void> processSession(String userId, PreKeyBundle preKeyBundle) async {
//   final signalProtocolAddress = SignalProtocolAddress(
//     userId,
//     preKeyBundle.getDeviceId(),
//   );
//   final sessionBuilder = SessionBuilder.fromSignalStore(
//     mixinSignalProtocolStore,
//     signalProtocolAddress,
//   );
//   try {
//     await sessionBuilder.processPreKeyBundle(preKeyBundle);
//   } on UntrustedIdentityException {
//     await mixinSignalProtocolStore.removeIdentity(signalProtocolAddress);
//     await sessionBuilder.processPreKeyBundle(preKeyBundle);
//   }
// }

Future requestNewPrekeysForContact(int contactId) async {
  final otherKeys = await apiService.getPreKeysByUserId(contactId);
  if (otherKeys != null) {
    Log.info("got fresh pre keys from other $contactId!");
    final preKeys = otherKeys.preKeys
        .map(
          (preKey) => SignalContactPreKeysCompanion(
            contactId: Value(contactId),
            preKey: Value(Uint8List.fromList(preKey.prekey)),
            preKeyId: Value(preKey.id.toInt()),
          ),
        )
        .toList();
    await twonlyDB.signalDao.insertPreKeys(preKeys);
  } else {
    Log.error("could not load new pre keys for user $contactId");
  }
}

Future<SignalContactPreKey?> getPreKeyByContactId(int contactId) async {
  int count = await twonlyDB.signalDao.countPreKeysByContactId(contactId);
  if (count < 10) {
    Log.info(
      "There are $count < 10 prekeys for $contactId. Loading fresh once from the server.",
    );
    requestNewPrekeysForContact(contactId);
  }
  return twonlyDB.signalDao.popPreKeyByContactId(contactId);
}

Future requestNewSignedPreKeyForContact(int contactId) async {
  final signedPreKey = await apiService.getSignedKeyByUserId(contactId);
  if (signedPreKey != null) {
    Log.info("got fresh signed pre keys from other $contactId!");
    await twonlyDB.signalDao.insertOrUpdateSignedPreKeyByContactId(
        SignalContactSignedPreKeysCompanion(
      contactId: Value(contactId),
      signedPreKey: Value(Uint8List.fromList(signedPreKey.signedPrekey)),
      signedPreKeySignature:
          Value(Uint8List.fromList(signedPreKey.signedPrekeySignature)),
      signedPreKeyId: Value(signedPreKey.signedPrekeyId.toInt()),
    ));
  } else {
    Log.error("could not load new signed pre key for user $contactId");
  }
}

Future<SignalContactSignedPreKey?> getSignedPreKeyByContactId(
  int contactId,
) async {
  SignalContactSignedPreKey? signedPreKey =
      await twonlyDB.signalDao.getSignedPreKeyByContactId(contactId);

  if (signedPreKey != null) {
    DateTime fortyEightHoursAgo = DateTime.now().subtract(Duration(hours: 48));
    bool isOlderThan48Hours =
        (signedPreKey.createdAt).isBefore(fortyEightHoursAgo);
    if (isOlderThan48Hours) {
      requestNewSignedPreKeyForContact(contactId);
    }
  } else {
    requestNewSignedPreKeyForContact(contactId);
    Log.error("Contact $contactId does not have a signed pre key!");
  }
  return signedPreKey;
}

Future<Uint8List?> signalEncryptMessage(int target, MessageJson msg) async {
  try {
    ConnectSignalProtocolStore signalStore = (await getSignalStore())!;
    final address = SignalProtocolAddress(target.toString(), defaultDeviceId);

    SessionCipher session = SessionCipher.fromStore(signalStore, address);

    SignalContactPreKey? preKey = await getPreKeyByContactId(target);
    SignalContactSignedPreKey? signedPreKey = await getSignedPreKeyByContactId(
      target,
    );

    if (signedPreKey != null) {
      SessionBuilder sessionBuilder = SessionBuilder.fromSignalStore(
        signalStore,
        address,
      );

      ECPublicKey? tempPrePublicKey;

      if (preKey != null) {
        tempPrePublicKey = Curve.decodePoint(
          DjbECPublicKey(
            Uint8List.fromList(preKey.preKey),
          ).serialize(),
          1,
        );
      }

      ECPublicKey? tempSignedPreKeyPublic = Curve.decodePoint(
        DjbECPublicKey(Uint8List.fromList(signedPreKey.signedPreKey))
            .serialize(),
        1,
      );

      Uint8List? tempSignedPreKeySignature = Uint8List.fromList(
        signedPreKey.signedPreKeySignature,
      );

      final IdentityKey? tempIdentityKey =
          await signalStore.getIdentity(address);
      if (tempIdentityKey != null) {
        PreKeyBundle preKeyBundle = PreKeyBundle(
          target,
          defaultDeviceId,
          preKey?.preKeyId,
          tempPrePublicKey,
          signedPreKey.signedPreKeyId,
          tempSignedPreKeyPublic,
          tempSignedPreKeySignature,
          tempIdentityKey,
        );

        try {
          await sessionBuilder.processPreKeyBundle(preKeyBundle);
        } catch (e) {
          Log.error("could not process pre key bundle: $e");
        }
      } else {
        Log.error("did not get the identity of the remote address");
      }
    }

    final ciphertext = await session.encrypt(
      Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(msg.toJson())))),
    );

    var b = BytesBuilder();
    b.add(ciphertext.serialize());
    b.add(intToBytes(ciphertext.getType()));

    return b.takeBytes();
  } catch (e) {
    Log.error(e.toString());
    return null;
  }
}

Future<MessageJson?> signalDecryptMessage(int source, Uint8List msg) async {
  try {
    ConnectSignalProtocolStore signalStore = (await getSignalStore())!;

    SessionCipher session = SessionCipher.fromStore(
        signalStore, SignalProtocolAddress(source.toString(), defaultDeviceId));

    List<Uint8List>? msgs = removeLastXBytes(msg, 4);
    if (msgs == null) {
      Log.error("Message requires at least 4 bytes.");
      return null;
    }
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
      Log.error("Type not known: $type");
      return null;
    }
    return MessageJson.fromJson(
        jsonDecode(utf8.decode(gzip.decode(plaintext))));
  } catch (e) {
    Log.error(e.toString());
    return null;
  }
}
