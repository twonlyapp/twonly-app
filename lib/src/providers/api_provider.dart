import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:logging/logging.dart';
import 'package:twonly/src/proto/api/client_to_server.pb.dart' as c;
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:twonly/src/proto/api/server_to_client.pbserver.dart';
import 'package:twonly/src/signal/signal_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Result<T, E> {
  final T? value;
  final E? error;

  bool get isSuccess => value != null;
  bool get isError => error != null;

  Result.success(this.value) : error = null;
  Result.error(this.error) : value = null;
}

enum ExchangeKind { connectionStateChange, sendRequestV0 }

class Exchange {
  Exchange({required this.kind, required this.body, required this.seq});
  final int seq;
  final ExchangeKind kind;
  final dynamic body;
}

c.ClientToServer createClientToServerFromHandshake(c.Handshake handshake) {
  // Create the V0 message
  var v0 = c.V0()
    ..seq = Int64(0) // You can set this to the appropriate sequence number
    ..handshake = handshake;

  // Create the ClientToServer message
  var clientToServer = c.ClientToServer()..v0 = v0;

  return clientToServer;
}

Result asResult(server.ServerToClient msg) {
  if (msg.v0.response.hasOk()) {
    return Result.success(msg.v0.response.ok);
  } else {
    return Result.error(msg.v0.response.error);
  }
}

class BackendIsolatedArgs {
  BackendIsolatedArgs(
      {required this.apiUrl,
      required this.backupApiUrl,
      required this.receivePort,
      required this.sendPort});
  final String apiUrl;
  final String backupApiUrl;
  final ReceivePort receivePort;
  final SendPort sendPort;
}

class ApiProvider with ChangeNotifier {
  ApiProvider({required this.apiUrl, required this.backupApiUrl});

  final String apiUrl;
  final String backupApiUrl;
  bool _isConnected = false;
  final Map<int, ServerToClient> _sendRequestV0Resp = HashMap();
  final log = Logger("twonly::ApiProvider");

  final ReceivePort _receivePort = ReceivePort();
  SendPort? _sendPort;

  Future<ServerToClient?> _waitForResponse(int seq) async {
    final startTime = DateTime.now();

    final timeout = Duration(seconds: 5);

    while (true) {
      if (_sendRequestV0Resp[seq] != null) {
        final tmp = _sendRequestV0Resp[seq];
        _sendRequestV0Resp.remove(seq);
        return tmp;
      }
      if (DateTime.now().difference(startTime) > timeout) {
        log.shout("Timeout for message $seq");
        return null;
      }
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  static void _startBackendIsolated(BackendIsolatedArgs args) async {
    final backend =
        Backend(apiUrl: args.apiUrl, backupApiUrl: args.backupApiUrl);

    await backend.connect();

    args.receivePort.listen((msg) async {
      switch (msg.kind) {
        case ExchangeKind.sendRequestV0:
          final resp = await backend._sendRequestV0(msg.body);
          args.sendPort.send(Exchange(
              kind: ExchangeKind.sendRequestV0, body: resp, seq: msg.seq));
          break;
        default:
      }
    });
    args.sendPort.send(
        Exchange(kind: ExchangeKind.connectionStateChange, body: true, seq: 0));
  }

  Future<bool> startBackend() async {
    ReceivePort port = ReceivePort();
    _sendPort = port.sendPort;

    await Isolate.spawn(
        _startBackendIsolated,
        BackendIsolatedArgs(
            sendPort: _receivePort.sendPort,
            receivePort: port,
            apiUrl: apiUrl,
            backupApiUrl: backupApiUrl));

    _receivePort.listen((msg) {
      switch (msg.kind) {
        case ExchangeKind.sendRequestV0:
          _sendRequestV0Resp[msg.seq] = msg.body;
          // final resp = await backend._sendRequestV0(msg.body);
          // args.sendPort.send(Exchange(
          //     kind: ExchangeKind.sendRequestV0, body: resp, seq: msg.seq));
          break;
        case ExchangeKind.connectionStateChange:
          _isConnected = msg.body;
        default:
      }
    });
    return true;
  }

  bool get isConnected => _isConnected;

  Future<Result> register(String username, String? inviteCode) async {
    if (_sendPort == null) return Result.error("Unknown error");
    final reqSignal = await SignalHelper.getRegisterData();

    if (reqSignal == null) {
      return Result.error(
          "There was an fatal error. Try reinstalling the app.");
    }

    var register = c.Handshake_Register()
      ..username = username
      ..publicIdentityKey = reqSignal["identityKey"]
      ..signedPrekey = reqSignal["signedPreKey"]?["key"]
      ..signedPrekeySignature = reqSignal["signedPreKey"]?["signature"]
      ..signedPrekeyId = Int64(reqSignal["signedPreKey"]?["id"]);

    if (inviteCode != null && inviteCode != "") {
      register.inviteCode = inviteCode;
    }
    // Create the Handshake message
    var handshake = c.Handshake()..register = register;
    var req = createClientToServerFromHandshake(handshake);

    var seq = Random().nextInt(4294967296);
    final tmp = Exchange(seq: seq, kind: ExchangeKind.sendRequestV0, body: req);
    _sendPort!.send(tmp);

    final resp = await _waitForResponse(seq);

    if (resp == null) {
      return Result.error("Server is not reachable!");
    }
    return asResult(resp);
  }
}

class Backend {
  Backend({required this.apiUrl, required this.backupApiUrl});

  final String apiUrl;
  final String? backupApiUrl;
  final log = Logger("twonly::backend");

  final HashMap<Int64, server.ServerToClient?> messagesV0 = HashMap();

  WebSocketChannel? _channel;

  Future<bool> _connectTo(String apiUrl) async {
    try {
      var channel = WebSocketChannel.connect(
        Uri.parse(apiUrl),
      );
      _channel = channel;
      _channel!.stream.listen(_onData);
      await _channel!.ready;
      log.info("Websocket is connected!");
      print("Websocket is connected!");
      return true;
    } on WebSocketChannelException catch (e) {
      log.shout("Error: $e");
      return false;
    }
  }

  Future<bool> connect() async {
    print("Trying to connect to the backend $apiUrl!");
    if (_channel != null && _channel!.closeCode != null) {
      return true;
    }
    log.info("Trying to connect to the backend $apiUrl!");
    if (await _connectTo(apiUrl)) {
      return true;
    }
    if (backupApiUrl != null) {
      log.info("Trying to connect to the backup backend $backupApiUrl!");
      if (await _connectTo(backupApiUrl!)) {
        return true;
      }
    }
    return false;
  }

  bool get isConnected => _channel != null && _channel!.closeCode != null;

  void _onData(dynamic msgBuffer) {
    try {
      final msg = server.ServerToClient.fromBuffer(msgBuffer);
      if (msg.v0.hasResponse()) {
        messagesV0[msg.v0.seq] = msg;
      } else {
        print("Got a new message from the server: $msg");
      }
    } catch (e) {
      log.shout("Error parsing the servers message: $e");
    }
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
      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  Future<server.ServerToClient?> _sendRequestV0(
      c.ClientToServer request) async {
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

  static String getLocalizedString(BuildContext context, ErrorCode code) {
    switch (code.toString()) {
      case "Unknown":
        return AppLocalizations.of(context)!.errorUnknown;
      case "BadRequest":
        return AppLocalizations.of(context)!.errorBadRequest;
      case "TooManyRequests":
        return AppLocalizations.of(context)!.errorTooManyRequests;
      case "InternalError":
        return AppLocalizations.of(context)!.errorInternalError;
      case "InvalidInvitationCode":
        return AppLocalizations.of(context)!.errorInvalidInvitationCode;
      case "UsernameAlreadyTaken":
        return AppLocalizations.of(context)!.errorUsernameAlreadyTaken;
      case "SignatureNotValid":
        return AppLocalizations.of(context)!.errorSignatureNotValid;
      case "UsernameNotFound":
        return AppLocalizations.of(context)!.errorUsernameNotFound;
      case "UsernameNotValid":
        return AppLocalizations.of(context)!.errorUsernameNotValid;
      case "InvalidPublicKey":
        return AppLocalizations.of(context)!.errorInvalidPublicKey;
      case "SessionAlreadyAuthenticated":
        return AppLocalizations.of(context)!.errorSessionAlreadyAuthenticated;
      case "SessionNotAuthenticated":
        return AppLocalizations.of(context)!.errorSessionNotAuthenticated;
      case "OnlyOneSessionAllowed":
        return AppLocalizations.of(context)!.errorOnlyOneSessionAllowed;
      default:
        return code.toString(); // Fallback for unrecognized keys
    }
  }
}
