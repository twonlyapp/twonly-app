import 'dart:collection';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';

import 'package:logging/logging.dart';
import 'package:twonly/src/proto/api/client_to_server.pb.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:twonly/src/signal/signal_helper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class Result<T, E> {
  final T? value;
  final E? error;

  bool get isSuccess => value != null;
  bool get isError => error != null;

  Result.success(this.value) : error = null;
  Result.error(this.error) : value = null;
}

class ApiProvider {
  ApiProvider({required this.apiUrl, required this.backupApiUrl});

  final String apiUrl;
  final String? backupApiUrl;
  final log = Logger("connect::ApiProvider");
  Function(bool)? _connectionStateCallback;

  final HashMap<Int64, server.ServerToClient?> messagesV0 = HashMap();

  IOWebSocketChannel? _channel;

  Future<bool> _connectTo(String apiUrl) async {
    try {
      var channel = IOWebSocketChannel.connect(
        Uri.parse(apiUrl),
      );
      _channel = channel;
      _channel!.stream.listen(_onData, onDone: _onDone, onError: _onError);
      await _channel!.ready;
      log.info("Websocket is connected!");
      print("Websocket is connected!");
      return true;
    } on WebSocketChannelException catch (e) {
      log.shout("Error: $e");
      return false;
    }
  }

  Future<bool> connect(Function(bool)? callBack) async {
    print("Trying to connect to the backend $apiUrl!");
    if (callBack != null) {
      _connectionStateCallback = callBack;
    }
    if (_channel != null && _channel!.closeCode != null) {
      print("is connected");
      return true;
    }

    log.info("Trying to connect to the backend $apiUrl!");
    if (await _connectTo(apiUrl)) {
      if (callBack != null) callBack(true);
      return true;
    }
    if (backupApiUrl != null) {
      log.info("Trying to connect to the backup backend $backupApiUrl!");
      if (await _connectTo(backupApiUrl!)) {
        if (callBack != null) callBack(true);
        return true;
      }
    }
    return false;
  }

  bool get isConnected => _channel != null && _channel!.closeCode != null;

  void _onDone() {
    if (_connectionStateCallback != null) {
      _connectionStateCallback!(false);
    }
    _channel = null;
    tryToReconnect(5);
  }

  void _onError(dynamic e) {
    if (_connectionStateCallback != null) {
      _connectionStateCallback!(false);
    }
    _channel = null;
    tryToReconnect(5);
  }

  void tryToReconnect(int delay) {
    Future.delayed(Duration(seconds: delay)).then(
      (value) async {
        if (!await connect(_connectionStateCallback)) {
          if (delay > 60 * 5) {
            delay = 60 * 5;
          } else {
            delay = delay * 2;
          }
          tryToReconnect(delay);
        }
      },
    );
  }

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

  Future<server.ServerToClient?> _sendRequestV0(ClientToServer request) async {
    var seq = Int64(Random().nextInt(4294967296));
    while (messagesV0.containsKey(seq)) {
      seq = Int64(Random().nextInt(4294967296));
    }
    request.v0.seq = seq;

    final requestBytes = request.writeToBuffer();

    log.info("Check if is connected?");
    // check if it is connected to the backend. if not try to reconnect.
    if (!await connect(null)) {
      return null;
    }

    _channel!.sink.add(requestBytes);

    return await _waitForResponse(seq);
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

  Result _asResult(server.ServerToClient msg) {
    if (msg.v0.response.hasOk()) {
      return Result.success(msg.v0.response.ok);
    } else {
      return Result.error(msg.v0.response.error);
    }
  }

  Future<Result> register(String username, String? inviteCode) async {
    final reqSignal = await SignalHelper.getRegisterData();

    if (reqSignal == null) {
      return Result.error(
          "There was an fatal error. Try reinstalling the app.");
    }

    var register = Handshake_Register()
      ..username = username
      ..publicIdentityKey = reqSignal["identityKey"]
      ..signedPrekey = reqSignal["signedPreKey"]?["key"]
      ..signedPrekeySignature = reqSignal["signedPreKey"]?["signature"]
      ..signedPrekeyId = Int64(reqSignal["signedPreKey"]?["id"]);

    if (inviteCode != null && inviteCode != "") {
      register.inviteCode = inviteCode;
    }
    // Create the Handshake message
    var handshake = Handshake()..register = register;
    var req = createClientToServerFromHandshake(handshake);

    final resp = await _sendRequestV0(req);
    if (resp == null) {
      return Result.error("Server is not reachable!");
    }
    return _asResult(resp);
  }
}
