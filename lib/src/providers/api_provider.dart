import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';

import 'package:logging/logging.dart';
import 'package:twonly/src/proto/api/client_to_server.pb.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:twonly/src/signal/signal_helper.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiProvider {
  ApiProvider({required this.apiUrl});

  final String apiUrl;
  final log = Logger("connect::ApiProvider");
  final HashMap<String, List<Function>> _callbacks = HashMap();

  final HashMap<Int64, server.ServerToClient?> messagesV0 = HashMap();

  WebSocketChannel? _channel;

  Future<bool> connect() async {
    if (_channel != null && _channel!.closeCode != null) {
      return true;
    }
    log.info("Trying to connect to the backend $apiUrl!");
    try {
      var channel = WebSocketChannel.connect(
        Uri.parse(apiUrl),
      );
      _channel = channel;
      _channel!.stream.listen(_onData);
      await _channel!.ready;
      log.info("Websocket is connected!");
      return true;
    } on WebSocketChannelException catch (e) {
      log.shout("Error: $e");
      return false;
    }
  }

  void _onData(dynamic msgBuffer) {
    try {
      final msg = server.ServerToClient.fromBuffer(msgBuffer);
      print("New message: $msg");
      messagesV0[msg.v0.seq] = msg;
    } catch (e) {
      log.shout("Error parsing the servers message: $e");
    }
  }

  // void _reconnect() {}

  void addNotifier(String messageType, Function callBackFunction) {
    if (!_callbacks.containsKey(messageType)) {
      _callbacks[messageType] = [];
    }
    _callbacks[messageType]!.add(callBackFunction);
  }

  // TODO: There must be a smarter move to do that :/
  Future<server.ServerToClient?> _waitForResponse(Int64 seq) async {
    final startTime = DateTime.now();

    final timeout = Duration(seconds: 5);

    while (true) {
      if (messagesV0[seq] != null) {
        final tmp = messagesV0[seq];
        messagesV0.remove(seq);
        return tmp;
      }
      if (DateTime.now().difference(startTime) > timeout) {
        log.shout("Timeout for message $seq");
        return null;
      }
      await Future.delayed(Duration(milliseconds: 1));
    }
  }

  Future<server.ServerToClient?> _sendRequestV0(ClientToServer request) async {
    var seq = Int64(Random().nextInt(4294967296));
    while (messagesV0.containsKey(seq)) {
      seq = Int64(Random().nextInt(4294967296));
    }
    request.v0.seq = seq;

    final requestBytes = request.writeToBuffer();

    log.info("Check if is connected?");
    // check if it is connected to the backend. if not try to reconnect.
    if (!await connect()) {
      return null;
    }

    _channel!.sink.add(requestBytes);

    return await _waitForResponse(seq);
  }

  String? _getErrorMsg(server.ServerToClient msg) {
    // if (msg.containsKey("Ok")) {
    //   return null;
    // }
    // if (msg.containsKey("Error")) {
    //   if (msg["Error"] != null) {
    //     if (msg["Error"].containsKey("AlertUser")) {
    //       return msg["Error"]["AlertUser"];
    //     }
    //   }
    //   return "There was an unknown error :/";
    // }
    return null;
  }

  ClientToServer createClientToServerFromHandshake(Handshake handshake) {
    // Create the V0 message
    var v0 = V0()
      ..seq = Int64(0) // You can set this to the appropriate sequence number
      ..handshake = handshake;

    // Create the ClientToServer message
    var clientToServer = ClientToServer()..v0 = v0;

    return clientToServer;
  }

  Future<String?> register(
      String username,
      // Uint8List publicIdentityKey,
      // Uint8List signedPrekey,
      // Uint8List signedPrekeySignature,
      String? inviteCode) async {
    final reqSignal = await SignalHelper.getRegisterData();

    if (reqSignal == null) {
      print("NULL");
      return null;
    }

    print(reqSignal);
    var register = Handshake_Register()
      ..username = username
      ..signedPrekey = reqSignal["signedPreKey"]?["key"]
      ..signedPrekeySignature = reqSignal["signedPreKey"]?["signature"]
      ..signedPrekeyId = Int64(reqSignal["signedPreKey"]?["id"]);

    if (inviteCode != null) {
      register.inviteCode = inviteCode;
    }
    // Create the Handshake message
    var handshake = Handshake()..register = register;
    var req = createClientToServerFromHandshake(handshake);

    final resp = await _sendRequestV0(req);
    if (resp == null) {
      return "Server is not reachable!";
    }
    return _getErrorMsg(resp);
  }
}
