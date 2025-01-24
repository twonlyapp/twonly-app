import 'dart:collection';
import 'dart:math';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/proto/api/client_to_server.pb.dart' as client;
import 'package:twonly/src/proto/api/client_to_server.pbserver.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;
import 'package:web_socket_channel/io.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/ecc/ed25519.dart';
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
  int _reconnectionDelay = 5;
  bool _tryingToConnect = false;
  final log = Logger("api_provider");
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
      return true;
    } on WebSocketChannelException catch (e) {
      log.shout("Error: $e");
      return false;
    }
  }

  Future<bool> connect() async {
    if (_channel != null && _channel!.closeCode != null) {
      return true;
    }

    log.info("Trying to connect to the backend $apiUrl!");
    if (await _connectTo(apiUrl)) {
      await authenticate();
      if (_connectionStateCallback != null) _connectionStateCallback!(true);
      _reconnectionDelay = 5;
      return true;
    }
    if (backupApiUrl != null) {
      log.info("Trying to connect to the backup backend $backupApiUrl!");
      if (await _connectTo(backupApiUrl!)) {
        await authenticate();
        if (_connectionStateCallback != null) _connectionStateCallback!(true);
        _reconnectionDelay = 5;
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
    tryToReconnect();
  }

  void _onError(dynamic e) {
    if (_connectionStateCallback != null) {
      _connectionStateCallback!(false);
    }
    _channel = null;
    tryToReconnect();
  }

  void setConnectionStateCallback(Function(bool) callBack) {
    _connectionStateCallback = callBack;
  }

  void tryToReconnect() {
    if (_tryingToConnect) return;
    _tryingToConnect = true;
    Future.delayed(Duration(seconds: _reconnectionDelay)).then(
      (value) async {
        _tryingToConnect = false;
        _reconnectionDelay = _reconnectionDelay + 2;
        if (_reconnectionDelay > 20) {
          _reconnectionDelay = 20;
        }
        await connect();
      },
    );
  }

  void _onData(dynamic msgBuffer) {
    try {
      final msg = server.ServerToClient.fromBuffer(msgBuffer);
      if (msg.v0.hasResponse()) {
        messagesV0[msg.v0.seq] = msg;
      } else {
        _handleServerMessage(msg);
        log.shout("Got a new message from the server: $msg");
      }
    } catch (e) {
      log.shout("Error parsing the servers message: $e");
    }
  }

  Future _handleServerMessage(server.ServerToClient msg) async {
    client.Response? response;

    if (msg.v0.requestNewPreKeys) {
      List<PreKeyRecord> localPreKeys = await SignalHelper.getPreKeys();

      List<client.Response_PreKey> prekeysList = [];
      for (int i = 0; i < localPreKeys.length; i++) {
        prekeysList.add(client.Response_PreKey()
          ..id = Int64(localPreKeys[i].id)
          ..prekey = localPreKeys[i].getKeyPair().publicKey.serialize());
      }
      var prekeys = client.Response_Prekeys(prekeys: prekeysList);
      var ok = client.Response_Ok()..prekeys = prekeys;
      response = client.Response()..ok = ok;
    }

    if (response == null) return;

    var v0 = client.V0()
      ..seq = msg.v0.seq
      ..response = response;
    var res = ClientToServer()..v0 = v0;

    final resBytes = res.writeToBuffer();
    _channel!.sink.add(resBytes);
  }

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
    if (_channel == null) {
      return null;
    }
    var seq = Int64(Random().nextInt(4294967296));
    while (messagesV0.containsKey(seq)) {
      seq = Int64(Random().nextInt(4294967296));
    }
    request.v0.seq = seq;

    final requestBytes = request.writeToBuffer();

    _channel!.sink.add(requestBytes);

    return await _waitForResponse(seq);
  }

  ClientToServer createClientToServerFromHandshake(Handshake handshake) {
    var v0 = client.V0()
      ..seq = Int64(0)
      ..handshake = handshake;
    return ClientToServer()..v0 = v0;
  }

  ClientToServer createClientToServerFromApplicationData(
      ApplicationData applicationData) {
    var v0 = client.V0()
      ..seq = Int64(0)
      ..applicationdata = applicationData;
    return ClientToServer()..v0 = v0;
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

  Future authenticate() async {
    if (await SignalHelper.getSignalIdentity() == null) {
      return;
    }

    var handshake = Handshake()..getchallenge = Handshake_GetChallenge();
    var req = createClientToServerFromHandshake(handshake);

    final resp = await _sendRequestV0(req);
    if (resp == null) {
      log.shout("Server is not reachable!");
      return;
    }
    final result = _asResult(resp);
    if (result.isError) {
      log.shout(result);
      return;
    }

    final challenge = result.value.challenge;

    final privKey = await SignalHelper.getPrivateKey();
    if (privKey == null) return;
    final random = getRandomUint8List(32);
    final signature = sign(privKey.serialize(), challenge, random);

    final userData = await getUser();
    if (userData == null) return;

    var open = Handshake_OpenSession()
      ..response = signature
      ..userId = userData.userId;

    var opensession = Handshake()..opensession = open;

    var req2 = createClientToServerFromHandshake(opensession);

    final resp2 = await _sendRequestV0(req2);
    if (resp2 == null) {
      log.shout("Server is not reachable!");
      return;
    }
    final result2 = _asResult(resp2);
    if (result2.isError) {
      log.shout(result2);
      return;
    }

    log.info("Authenticated!");
  }

  Future<Result> register(String username, String? inviteCode) async {
    final signalIdentity = await SignalHelper.getSignalIdentity();
    if (signalIdentity == null) {
      return Result.error(
          "There was an fatal error. Try reinstalling the app.");
    }

    final signalStore =
        await SignalHelper.getSignalStoreFromIdentity(signalIdentity);

    final signedPreKey = (await signalStore.loadSignedPreKeys())[0];
    log.shout("handle registrationId", signalIdentity.registrationId);

    var register = Handshake_Register()
      ..username = username
      ..publicIdentityKey =
          (await signalStore.getIdentityKeyPair()).getPublicKey().serialize()
      ..registrationId = signalIdentity.registrationId
      ..signedPrekey = signedPreKey.getKeyPair().publicKey.serialize()
      ..signedPrekeySignature = signedPreKey.signature
      ..signedPrekeyId = Int64(signedPreKey.id);

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

  Future<Result> getUserData(String username) async {
    var get = ApplicationData_GetUserByUsername()..username = username;
    var appData = ApplicationData()..getuserbyusername = get;
    var req = createClientToServerFromApplicationData(appData);

    final resp = await _sendRequestV0(req);
    if (resp == null) {
      return Result.error("Server is not reachable!");
    }
    return _asResult(resp);
  }
}
