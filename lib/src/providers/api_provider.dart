import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiProvider {
  ApiProvider({required this.apiUrl});

  final String apiUrl;
  final log = Logger("connect::ApiProvider");
  final HashMap<String, List<Function>> _callbacks = HashMap();

  final HashMap<Uint64, Map<dynamic, dynamic>?> messagesV0 = HashMap();

  WebSocketChannel? _channel;

  Future<bool> connect() async {
    if (_channel != null && _channel!.closeCode != null) {
      return true;
    }
    log.info("Trying to connect to the backend!");
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

  void _onData(dynamic msgJson) {
    try {
      Map<String, dynamic> msg = jsonDecode(msgJson);
      if (!msg.containsKey("v")) {
        log.shout("Got invalid data from server!");
        return;
      }
      if (msg["v"] != "0") {
        log.shout("Server msg not supported by client!\n $msgJson");
        return;
      }
      if (!msg.containsKey("seq") || !msg.containsKey("kind")) {
        log.shout("Invalid server msg. No seq number or kind given: $msgJson!");
        return;
      }
      if (msg["kind"] == "Response") {
        if (messagesV0[msg["seq"]] != null) {
          log.shout("Seq no unknown: $msgJson!");
          return;
        }
        messagesV0[msg["seq"]] = msg;
      }
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
  Future<Map<dynamic, dynamic>?> _waitForResponse(Uint64 seq) async {
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

  Future<Map<dynamic, dynamic>?> _sendRequestV0(
      Map<dynamic, dynamic> request) async {
    var seq = Random().nextInt(0xFFFFFFFFFFFFFF) as Uint64;
    while (!messagesV0.containsKey(seq)) {
      seq = Random().nextInt(0xFFFFFFFFFFFFFF) as Uint64;
    }
    request["v"] = "0";
    request["seq"] = seq;
    final requestJson = jsonEncode(request);

    // check if it is connected to the backend. if not try to reconnect.
    if (!await connect()) {
      return null;
    }

    // reserve seq no
    messagesV0[seq] = null;
    _channel!.sink.add(requestJson);

    return await _waitForResponse(seq);
  }

  String? _getErrorMsg(Map<dynamic, dynamic> msg) {
    if (msg.containsKey("Ok")) {
      return null;
    }
    if (msg.containsKey("Error")) {
      if (msg["Error"] != null) {
        if (msg["Error"].containsKey("AlertUser")) {
          return msg["Error"]["AlertUser"];
        }
      }
      return "There was an unknown error :/";
    }
    return null;
  }

  Future<String?> handshakeCheckRegister(
      String username, String inviteCode) async {
    final resp = await _sendRequestV0({
      "kind": "Handshake",
      "CheckRegister": {"username": username, "inviteCode": inviteCode}
    });
    if (resp == null) {
      return "Server is not reachable!";
    }
    return _getErrorMsg(resp);
  }
}
