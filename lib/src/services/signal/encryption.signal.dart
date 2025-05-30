import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/database/signal/connect_signal_protocol_store.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

Future<Uint8List?> signalEncryptMessage(int target, MessageJson msg) async {
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
