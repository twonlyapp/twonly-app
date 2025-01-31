import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/proto/api/client_to_server.pbserver.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/api/server_messages.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;
import 'package:web_socket_channel/io.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/ecc/ed25519.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// The ApiProvider is responsible for communicating with the server.
/// It handles errors and does automatically tries to reconnect on
/// errors or network changes.
class ApiProvider {
  final String apiUrl;
  final String? backupApiUrl;
  ApiProvider({required this.apiUrl, required this.backupApiUrl});

  final log = Logger("ApiProvider");

  // reconnection params
  Timer? reconnectionTimer;
  int _reconnectionDelay = 5;

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

  Future onConnected() async {
    await authenticate();
    globalCallbackConnectionState(true);
    _reconnectionDelay = 5;

    tryTransmitMessages();
  }

  Future<bool> connect() async {
    if (_channel != null && _channel!.closeCode != null) {
      return true;
    }
    // ensure that the connect function is not called again by the timer.
    if (reconnectionTimer != null) {
      reconnectionTimer!.cancel();
    }

    log.info("Trying to connect to the backend $apiUrl!");
    if (await _connectTo(apiUrl)) {
      onConnected();
      return true;
    }
    if (backupApiUrl != null) {
      log.info("Trying to connect to the backup backend $backupApiUrl!");
      if (await _connectTo(backupApiUrl!)) {
        onConnected();
        return true;
      }
    }
    return false;
  }

  bool get isConnected => _channel != null && _channel!.closeCode != null;

  void _onDone() {
    globalCallbackConnectionState(false);
    _channel = null;
    tryToReconnect();
  }

  void _onError(dynamic e) {
    globalCallbackConnectionState(false);
    _channel = null;
    tryToReconnect();
  }

  void tryToReconnect() {
    if (reconnectionTimer != null) {
      reconnectionTimer!.cancel();
    }

    final int randomDelay = Random().nextInt(20);
    final int delay = _reconnectionDelay + randomDelay;

    debugPrint("Delay reconnection $delay");

    reconnectionTimer = Timer(Duration(seconds: delay), () async {
      // increase delay but set a maximum of 60 seconds (including the random delay)
      _reconnectionDelay = _reconnectionDelay * 2;
      if (_reconnectionDelay > 40) {
        _reconnectionDelay = 40;
      }
      await connect();
    });
  }

  void _onData(dynamic msgBuffer) {
    try {
      final msg = server.ServerToClient.fromBuffer(msgBuffer);
      if (msg.v0.hasResponse()) {
        messagesV0[msg.v0.seq] = msg;
      } else {
        handleServerMessage(msg);
      }
    } catch (e) {
      log.shout("Error parsing the servers message: $e");
    }
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

  Future sendResponse(ClientToServer response) async {
    _channel!.sink.add(response.writeToBuffer());
  }

  Future<Result> _sendRequestV0(ClientToServer request) async {
    if (_channel == null) {
      if (!await connect()) {
        return Result.error(ErrorCode.InternalError);
      }
    }
    var seq = Int64(Random().nextInt(4294967296));
    while (messagesV0.containsKey(seq)) {
      seq = Int64(Random().nextInt(4294967296));
    }
    request.v0.seq = seq;

    final requestBytes = request.writeToBuffer();

    _channel!.sink.add(requestBytes);

    return asResult(await _waitForResponse(seq));
  }

  Future authenticate() async {
    if (await SignalHelper.getSignalIdentity() == null) {
      return;
    }

    var handshake = Handshake()..getchallenge = Handshake_GetChallenge();
    var req = createClientToServerFromHandshake(handshake);

    final result = await _sendRequestV0(req);
    if (result.isError) {
      log.shout("Error auth", result);
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

    final result2 = await _sendRequestV0(req2);
    if (result2.isError) {
      log.shout("send request failed: ${result2.error}");
      return;
    }

    log.info("Authenticated!");
  }

  Future<Result> register(String username, String? inviteCode) async {
    final signalIdentity = await SignalHelper.getSignalIdentity();
    if (signalIdentity == null) {
      return Result.error(ErrorCode.InternalError);
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

    return await _sendRequestV0(req);
  }

  Future<Result> getUsername(Int64 userId) async {
    var get = ApplicationData_GetUserById()..userId = userId;
    var appData = ApplicationData()..getuserbyid = get;
    var req = createClientToServerFromApplicationData(appData);
    return await _sendRequestV0(req);
  }

  Future<Result> getUploadToken() async {
    var get = ApplicationData_GetUploadToken();
    var appData = ApplicationData()..getuploadtoken = get;
    var req = createClientToServerFromApplicationData(appData);
    return await _sendRequestV0(req);
  }

  Future<Result> triggerDownload(List<int> token, int offset) async {
    var get = ApplicationData_DownloadData()
      ..uploadToken = token
      ..offset = offset;
    var appData = ApplicationData()..downloaddata = get;
    var req = createClientToServerFromApplicationData(appData);
    return await _sendRequestV0(req);
  }

  Future<bool> uploadData(
      List<int> uploadToken, Uint8List data, int offset) async {
    var get = ApplicationData_UploadData()
      ..uploadToken = uploadToken
      ..data = data
      ..offset = offset;
    var appData = ApplicationData()..uploaddata = get;
    var req = createClientToServerFromApplicationData(appData);
    final result = await _sendRequestV0(req);
    return result.isSuccess;
  }

  Future<Result> getUserData(String username) async {
    var get = ApplicationData_GetUserByUsername()..username = username;
    var appData = ApplicationData()..getuserbyusername = get;
    var req = createClientToServerFromApplicationData(appData);
    return await _sendRequestV0(req);
  }

  Future<Result> sendTextMessage(Int64 target, Uint8List msg) async {
    var testMessage = ApplicationData_TextMessage()
      ..userId = target
      ..body = msg;

    var appData = ApplicationData()..textmessage = testMessage;
    var req = createClientToServerFromApplicationData(appData);

    return await _sendRequestV0(req);
  }
}
