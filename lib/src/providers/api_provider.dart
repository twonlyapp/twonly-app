import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/app.dart';
import 'package:twonly/src/proto/api/client_to_server.pbserver.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:twonly/src/proto/api/server_to_client.pb.dart' as server;
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/api_utils.dart';
import 'package:twonly/src/providers/api/media.dart';
import 'package:twonly/src/providers/api/server_messages.dart';
import 'package:twonly/src/services/fcm_service.dart';
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
  final String apiUrl = (kDebugMode)
      ? "ws://10.99.0.140:3030/api/client"
      : "wss://api.twonly.eu/api/client";
  // ws://api.twonly.eu/api/client
  final String? backupApiUrl = (kDebugMode)
      ? "ws://10.99.0.140:3030/api/client"
      : "wss://api2.twonly.eu/api/client";
  bool isAuthenticated = false;
  ApiProvider();

  final log = Logger("ApiProvider");

  // reconnection params
  Timer? reconnectionTimer;
  // int _reconnectionDelay = 5;

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

  // Function is called after the user is authenticated at the server
  Future onAuthenticated() async {
    isAuthenticated = true;
    initFCMAfterAuthenticated();
  }

  Future onConnected() async {
    await authenticate();
    globalCallbackConnectionState(true);

    if (!globalIsAppInBackground) {
      tryTransmitMessages();
      retransmitMediaFiles();
      tryDownloadAllMediaFiles();
      notifyContactsAboutProfileChange();
      twonlyDatabase.markUpdated();
    }
  }

  Future close(Function callback) async {
    log.info("Closing the websocket connection!");
    if (_channel != null) {
      await _channel!.sink.close();
      callback();
      return;
    }
    callback();
  }

  Future<bool> connect() async {
    if (_channel != null) {
      return true;
    }
    // ensure that the connect function is not called again by the timer.
    if (reconnectionTimer != null) {
      reconnectionTimer!.cancel();
    }

    isAuthenticated = false;

    log.fine("Trying to connect to the backend $apiUrl!");
    if (await _connectTo(apiUrl)) {
      await onConnected();
      return true;
    }
    if (backupApiUrl != null) {
      log.fine("Trying to connect to the backup backend $backupApiUrl!");
      if (await _connectTo(backupApiUrl!)) {
        await onConnected();
        return true;
      }
    }
    return false;
  }

  bool get isConnected => _channel != null && _channel!.closeCode != null;

  void _onDone() {
    log.info("WebSocket Closed");
    globalCallbackConnectionState(false);
    _channel = null;
    isAuthenticated = false;
  }

  void _onError(dynamic e) {
    log.info("WebSocket Error: $e");
    globalCallbackConnectionState(false);
    _channel = null;
    isAuthenticated = false;
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
    if (_channel != null) {
      _channel!.sink.add(response.writeToBuffer());
    }
  }

  Future<Result> sendRequestSync(ClientToServer request,
      {bool authenticated = true}) async {
    if (_channel == null) {
      log.shout("sending request, but api is not connected.");
      if (!await connect()) {
        return Result.error(ErrorCode.InternalError);
      }
    }
    if (_channel == null) {
      return Result.error(ErrorCode.InternalError);
    }

    var seq = Int64(Random().nextInt(4294967296));
    while (messagesV0.containsKey(seq)) {
      seq = Int64(Random().nextInt(4294967296));
    }

    request.v0.seq = seq;
    final requestBytes = request.writeToBuffer();
    _channel!.sink.add(requestBytes);

    Result res = asResult(await _waitForResponse(seq));
    if (res.isError) {
      if (res.error == ErrorCode.SessionNotAuthenticated) {
        isAuthenticated = false;
        if (authenticated) {
          await authenticate();
          if (isAuthenticated) {
            // this will send the request one more time.
            return sendRequestSync(request, authenticated: false);
          } else {
            log.shout("Session is not authenticated.");
            return Result.error(ErrorCode.InternalError);
          }
        }
      }
    }
    return res;
  }

  Future<bool> tryAuthenticateWithToken(int userId) async {
    final storage = getSecureStorage();
    String? apiAuthToken = await storage.read(key: "api_auth_token");

    if (apiAuthToken != null) {
      final authenticate = Handshake_Authenticate()
        ..userId = Int64(userId)
        ..authToken = base64Decode(apiAuthToken);

      final handshake = Handshake()..authenticate = authenticate;
      final req = createClientToServerFromHandshake(handshake);

      final result = await sendRequestSync(req, authenticated: false);

      if (result.isSuccess) {
        log.info("Authenticated using api_auth_token");
        onAuthenticated();
        return true;
      }
      if (result.isError) {
        if (result.error != ErrorCode.AuthTokenNotValid) {
          log.shout("Error while authenticating using token", result);
          return false;
        }
      }
    }
    return false;
  }

  Future authenticate() async {
    if (isAuthenticated) return;
    if (await SignalHelper.getSignalIdentity() == null) {
      return;
    }

    final userData = await getUser();
    if (userData == null) return;

    if (await tryAuthenticateWithToken(userData.userId)) {
      return;
    }

    var handshake = Handshake()
      ..getauthchallenge = Handshake_GetAuthChallenge();
    var req = createClientToServerFromHandshake(handshake);

    final result = await sendRequestSync(req, authenticated: false);
    if (result.isError) {
      log.shout("Error requesting auth challenge", result);
      return;
    }

    final challenge = result.value.authchallenge;

    final privKey = await SignalHelper.getPrivateKey();
    if (privKey == null) return;
    final random = getRandomUint8List(32);
    final signature = sign(privKey.serialize(), challenge, random);

    final getAuthToken = Handshake_GetAuthToken()
      ..response = signature
      ..userId = Int64(userData.userId);

    final getauthtoken = Handshake()..getauthtoken = getAuthToken;

    var req2 = createClientToServerFromHandshake(getauthtoken);

    final result2 = await sendRequestSync(req2, authenticated: false);
    if (result2.isError) {
      log.shout("Error while sending auth challenge: ${result2.error}");
      return;
    }

    Uint8List apiAuthToken = result2.value.authtoken;
    String apiAuthTokenB64 = base64Encode(apiAuthToken);

    final storage = getSecureStorage();
    await storage.write(key: "api_auth_token", value: apiAuthTokenB64);

    await tryAuthenticateWithToken(userData.userId);
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
      ..registrationId = Int64(signalIdentity.registrationId)
      ..signedPrekey = signedPreKey.getKeyPair().publicKey.serialize()
      ..signedPrekeySignature = signedPreKey.signature
      ..signedPrekeyId = Int64(signedPreKey.id);

    if (inviteCode != null && inviteCode != "") {
      register.inviteCode = inviteCode;
    }
    // Create the Handshake message
    var handshake = Handshake()..register = register;
    var req = createClientToServerFromHandshake(handshake);

    return await sendRequestSync(req);
  }

  Future<Result> getUsername(int userId) async {
    var get = ApplicationData_GetUserById()..userId = Int64(userId);
    var appData = ApplicationData()..getuserbyid = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> getUploadToken(int recipientsCount) async {
    var get = ApplicationData_GetUploadToken()
      ..recipientsCount = recipientsCount;
    var appData = ApplicationData()..getuploadtoken = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> getCurrentLocation() async {
    var get = ApplicationData_GetLocation();
    var appData = ApplicationData()..getlocation = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> triggerDownload(List<int> token, int offset) async {
    var get = ApplicationData_DownloadData()
      ..downloadToken = token
      ..offset = offset;
    var appData = ApplicationData()..downloaddata = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> uploadData(List<int> uploadToken, Uint8List data, int offset,
      List<int>? checksum) async {
    var get = ApplicationData_UploadData()
      ..uploadToken = uploadToken
      ..data = data
      ..offset = offset;
    if (checksum != null) {
      get.checksum = checksum;
    }
    var appData = ApplicationData()..uploaddata = get;
    var req = createClientToServerFromApplicationData(appData);
    final result = await sendRequestSync(req);
    return result;
  }

  Future<Result> getUserData(String username) async {
    var get = ApplicationData_GetUserByUsername()..username = username;
    var appData = ApplicationData()..getuserbyusername = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> updateFCMToken(String googleFcm) async {
    var get = ApplicationData_UpdateGoogleFcmToken()..googleFcm = googleFcm;
    var appData = ApplicationData()..updategooglefcmtoken = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> sendTextMessage(
      int target, Uint8List msg, List<int>? pushData) async {
    var testMessage = ApplicationData_TextMessage()
      ..userId = Int64(target)
      ..body = msg;

    if (pushData != null) {
      testMessage.pushData = pushData;
    }

    var appData = ApplicationData()..textmessage = testMessage;
    var req = createClientToServerFromApplicationData(appData);

    return await sendRequestSync(req);
  }
}
