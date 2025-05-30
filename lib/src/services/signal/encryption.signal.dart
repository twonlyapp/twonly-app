import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/services/signal/consts.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

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

// Future<bool> checkSignalSession(String recipientId, String sessionId) async {
//   final contains = await signalProtocol.containsSession(
//     recipientId,
//     deviceId: sessionId.getDeviceId(),
//   );
//   if (!contains) {
//     final requestKeys = <BlazeMessageParamSession>[
//       BlazeMessageParamSession(userId: recipientId, sessionId: sessionId),
//     ];
//     final blazeMessage = createConsumeSessionSignalKeys(
//       createConsumeSignalKeysParam(requestKeys),
//     );
//     final data = (await signalKeysChannel(blazeMessage))?.data;
//     if (data == null) {
//       return false;
//     }
//     final keys = List<SignalKey>.from(
//       (data as List<dynamic>).map(
//         (e) => SignalKey.fromJson(e as Map<String, dynamic>),
//       ),
//     );
//     if (keys.isNotEmpty) {
//       final preKeyBundle = keys.first.createPreKeyBundle();
//       await signalProtocol.processSession(recipientId, preKeyBundle);
//     } else {
//       return false;
//     }
//   }
//   return true;
// }

Future<Uint8List?> signalEncryptMessage(int target, MessageJson msg) async {
  try {
    ConnectSignalProtocolStore signalStore = (await getSignalStore())!;
    final address = SignalProtocolAddress(target.toString(), defaultDeviceId);

    SessionCipher session = SessionCipher.fromStore(signalStore, address);

    final SessionRecord sessionRecord =
        await signalStore.sessionStore.loadSession(address);

    if (!sessionRecord.sessionState.hasUnacknowledgedPreKeyMessage()) {
      Log.info("There are now pre keys any more... load new...");
    }

    // sessionRecord.sessionState.sign

    //   session.

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
