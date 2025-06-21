import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mutex/mutex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pbserver.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/api/media_download.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/api/server_messages.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/prekeys.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/services/fcm.service.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:web_socket_channel/io.dart';
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/ecc/ed25519.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final lockConnecting = Mutex();
final lockRetransStore = Mutex();

/// The ApiProvider is responsible for communicating with the server.
/// It handles errors and does automatically tries to reconnect on
/// errors or network changes.
class ApiService {
  final String apiHost = (kDebugMode) ? "10.99.0.140:3030" : "api.twonly.eu";
  final String apiSecure = (kDebugMode) ? "" : "s";

  bool isAuthenticated = false;
  ApiService();

  // reconnection params
  Timer? reconnectionTimer;
  int _reconnectionDelay = 5;

  final HashMap<Int64, server.ServerToClient?> messagesV0 = HashMap();
  IOWebSocketChannel? _channel;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  Future<bool> _connectTo(String apiUrl) async {
    try {
      var channel = IOWebSocketChannel.connect(
        Uri.parse(apiUrl),
      );
      _channel = channel;
      _channel!.stream.listen(_onData, onDone: _onDone, onError: _onError);
      await _channel!.ready;
      Log.info("websocket connected to $apiUrl");
      return true;
    } on WebSocketChannelException catch (e) {
      if (!e.message
          .toString()
          .contains("No address associated with hostname")) {
        Log.error("could not connect to api got: $e");
      }
      return false;
    }
  }

  // Function is called after the user is authenticated at the server
  Future onAuthenticated() async {
    isAuthenticated = true;
    initFCMAfterAuthenticated();
    globalCallbackConnectionState(true);

    if (!globalIsAppInBackground) {
      retransmitRawBytes();
      tryTransmitMessages();
      retryMediaUpload(false);
      tryDownloadAllMediaFiles();
      notifyContactsAboutProfileChange();
      twonlyDB.markUpdated();
      syncFlameCounters();
      setupNotificationWithUsers();
      signalHandleNewServerConnection();
    }
  }

  Future onConnected() async {
    await authenticate();
    _reconnectionDelay = 5;
    globalCallbackConnectionState(true);
  }

  Future onClosed() async {
    _channel = null;
    isAuthenticated = false;
    globalCallbackConnectionState(false);
    await twonlyDB.messagesDao.resetPendingDownloadState();
  }

  Future startReconnectionTimer() async {
    reconnectionTimer?.cancel();
    reconnectionTimer ??= Timer(Duration(seconds: _reconnectionDelay), () {
      reconnectionTimer = null;
      connect(force: true);
    });
    _reconnectionDelay += 5;
  }

  Future close(Function callback) async {
    Log.info("closing websocket connection");
    if (_channel != null) {
      await _channel!.sink.close();
      onClosed();
      callback();
      return;
    }
    callback();
  }

  Future listenToNetworkChanges() async {
    if (connectivitySubscription != null) {
      return;
    }
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (!result.contains(ConnectivityResult.none)) {
        connect(force: true);
      }
      // Received changes in available connectivity types!
    });
  }

  Future<bool> connect({bool force = false}) async {
    if (reconnectionTimer != null && !force) {
      return false;
    }
    reconnectionTimer?.cancel();
    reconnectionTimer = null;
    final user = await getUser();
    if (user != null && user.isDemoUser) {
      globalCallbackConnectionState(true);
      return false;
    }
    return lockConnecting.protect<bool>(() async {
      if (_channel != null) {
        return true;
      }
      // ensure that the connect function is not called again by the timer.
      reconnectionTimer?.cancel();
      reconnectionTimer = null;

      isAuthenticated = false;

      String apiUrl = "ws$apiSecure://$apiHost/api/client";

      Log.info("connecting to $apiUrl");

      if (await _connectTo(apiUrl)) {
        await onConnected();
        return true;
      }
      return false;
    });
  }

  bool get isConnected => _channel != null && _channel!.closeCode != null;

  void _onDone() {
    Log.info("websocket closed without error");
    onClosed();
  }

  void _onError(dynamic e) {
    Log.error("websocket error: $e");
    onClosed();
  }

  void _onData(dynamic msgBuffer) async {
    try {
      final msg = server.ServerToClient.fromBuffer(msgBuffer);
      if (msg.v0.hasResponse()) {
        removeFromRetransmissionBuffer(msg.v0.seq);
        messagesV0[msg.v0.seq] = msg;
      } else {
        await handleServerMessage(msg);
      }
    } catch (e) {
      Log.error("Error parsing the servers message: $e");
    }
  }

  Future<server.ServerToClient?> _waitForResponse(Int64 seq) async {
    final startTime = DateTime.now();

    final timeout = Duration(seconds: 20);

    while (true) {
      if (messagesV0[seq] != null) {
        final tmp = messagesV0[seq];
        messagesV0.remove(seq);
        return tmp;
      }
      if (DateTime.now().difference(startTime) > timeout) {
        Log.error("Timeout for message $seq");
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

  Future<Map<String, dynamic>> getRetransmission() async {
    return await KeyValueStore.get("rawbytes-to-retransmit") ?? {};
  }

  Future retransmitRawBytes() async {
    await lockRetransStore.protect(() async {
      var retransmit = await getRetransmission();
      if (retransmit.keys.isEmpty) return;
      Log.info("retransmitting ${retransmit.keys.length} raw bytes messages");
      bool gotError = false;
      for (final seq in retransmit.keys) {
        try {
          _channel!.sink.add(base64Decode(retransmit[seq]));
        } catch (e) {
          gotError = true;
          Log.error("$e");
        }
      }
      if (!gotError) {
        KeyValueStore.put("rawbytes-to-retransmit", {});
      }
    });
  }

  Future addToRetransmissionBuffer(Int64 seq, Uint8List bytes) async {
    await lockRetransStore.protect(() async {
      var retransmit = await getRetransmission();
      retransmit[seq.toString()] = base64Encode(bytes);
      KeyValueStore.put("rawbytes-to-retransmit", retransmit);
    });
  }

  Future removeFromRetransmissionBuffer(Int64 seq) async {
    await lockRetransStore.protect(() async {
      var retransmit = await getRetransmission();
      if (retransmit.isEmpty) return;
      retransmit.remove(seq.toString());
      KeyValueStore.put("rawbytes-to-retransmit", retransmit);
    });
  }

  Future<Result> sendRequestSync(
    ClientToServer request, {
    bool authenticated = true,
    bool ensureRetransmission = false,
    int? contactId,
  }) async {
    var seq = Int64(Random().nextInt(4294967296));
    while (messagesV0.containsKey(seq)) {
      seq = Int64(Random().nextInt(4294967296));
    }

    request.v0.seq = seq;
    final requestBytes = request.writeToBuffer();

    if (ensureRetransmission) {
      addToRetransmissionBuffer(seq, requestBytes);
    }

    if (_channel == null) {
      Log.warn("sending request while api is not connected");
      if (!await connect()) {
        return Result.error(ErrorCode.InternalError);
      }
      if (_channel == null) {
        return Result.error(ErrorCode.InternalError);
      }
    }

    _channel!.sink.add(requestBytes);

    Result res = asResult(await _waitForResponse(seq));
    if (res.isError) {
      Log.error("got error from server: ${res.error}");
      if (res.error == ErrorCode.SessionNotAuthenticated) {
        isAuthenticated = false;
        if (authenticated) {
          await authenticate();
          if (isAuthenticated) {
            // this will send the request one more time.
            return sendRequestSync(request, authenticated: false);
          } else {
            Log.error("session is not authenticated");
            return Result.error(ErrorCode.InternalError);
          }
        }
      }
      if (res.error == ErrorCode.UserIdNotFound && contactId != null) {
        Log.error("Contact deleted their account $contactId.");
        await twonlyDB.contactsDao.updateContact(
          contactId,
          ContactsCompanion(
            deleted: Value(true),
          ),
        );
      }
    }
    return res;
  }

  Future<bool> tryAuthenticateWithToken(int userId) async {
    final storage = FlutterSecureStorage();
    String? apiAuthToken =
        await storage.read(key: SecureStorageKeys.apiAuthToken);

    if (apiAuthToken != null) {
      final authenticate = Handshake_Authenticate()
        ..userId = Int64(userId)
        ..appVersion = (await PackageInfo.fromPlatform()).version
        ..authToken = base64Decode(apiAuthToken);

      final handshake = Handshake()..authenticate = authenticate;
      final req = createClientToServerFromHandshake(handshake);

      final result = await sendRequestSync(req, authenticated: false);

      if (result.isSuccess) {
        server.Response_Ok ok = result.value;
        if (ok.hasAuthenticated()) {
          server.Response_Authenticated authenticated = ok.authenticated;
          updateUserdata((user) {
            user.subscriptionPlan = authenticated.plan;
            return user;
          });
        }
        Log.info("websocket is authenticated");
        onAuthenticated();
        return true;
      }
      if (result.isError) {
        if (result.error != ErrorCode.AuthTokenNotValid) {
          Log.error("got error while authenticating to the server", result);
          return false;
        }
      }
    }
    return false;
  }

  Future authenticate() async {
    if (isAuthenticated) return;
    if (await getSignalIdentity() == null) {
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
      Log.error("could not request auth challenge", result);
      return;
    }

    final challenge = result.value.authchallenge;

    var privKey = (await getSignalIdentityKeyPair())?.getPrivateKey();
    if (privKey == null) return;
    final random = getRandomUint8List(32);
    final signature = sign(privKey.serialize(), challenge, random);
    privKey = null;

    final getAuthToken = Handshake_GetAuthToken()
      ..response = signature
      ..userId = Int64(userData.userId);

    final getauthtoken = Handshake()..getauthtoken = getAuthToken;

    var req2 = createClientToServerFromHandshake(getauthtoken);

    final result2 = await sendRequestSync(req2, authenticated: false);
    if (result2.isError) {
      Log.error("could not send auth response: ${result2.error}");
      return;
    }

    Uint8List apiAuthToken = result2.value.authtoken;
    String apiAuthTokenB64 = base64Encode(apiAuthToken);

    final storage = FlutterSecureStorage();
    await storage.write(
        key: SecureStorageKeys.apiAuthToken, value: apiAuthTokenB64);

    await tryAuthenticateWithToken(userData.userId);
  }

  Future<Result> register(String username, String? inviteCode) async {
    final signalIdentity = await getSignalIdentity();
    if (signalIdentity == null) {
      return Result.error(ErrorCode.InternalError);
    }

    final signalStore = await getSignalStoreFromIdentity(signalIdentity);

    final signedPreKey = (await signalStore.loadSignedPreKeys())[0];

    var register = Handshake_Register()
      ..username = username
      ..publicIdentityKey =
          (await signalStore.getIdentityKeyPair()).getPublicKey().serialize()
      ..registrationId = Int64(signalIdentity.registrationId)
      ..signedPrekey = signedPreKey.getKeyPair().publicKey.serialize()
      ..signedPrekeySignature = signedPreKey.signature
      ..signedPrekeyId = Int64(signedPreKey.id)
      ..isIos = Platform.isIOS;

    if (inviteCode != null && inviteCode != "") {
      register.inviteCode = inviteCode;
    }

    var handshake = Handshake()..register = register;
    var req = createClientToServerFromHandshake(handshake);

    return await sendRequestSync(req);
  }

  Future<Result> getUsername(int userId) async {
    var get = ApplicationData_GetUserById()..userId = Int64(userId);
    var appData = ApplicationData()..getuserbyid = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req, contactId: userId);
  }

  Future<Result> downloadDone(List<int> token) async {
    var get = ApplicationData_DownloadDone()..downloadToken = token;
    var appData = ApplicationData()..downloaddone = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req, ensureRetransmission: true);
  }

  Future<Result> getCurrentLocation() async {
    var get = ApplicationData_GetLocation();
    var appData = ApplicationData()..getlocation = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> getUserData(String username) async {
    var get = ApplicationData_GetUserByUsername()..username = username;
    var appData = ApplicationData()..getuserbyusername = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Response_PlanBallance?> getPlanBallance() async {
    var get = ApplicationData_GetCurrentPlanInfos();
    var appData = ApplicationData()..getcurrentplaninfos = get;
    var req = createClientToServerFromApplicationData(appData);
    Result res = await sendRequestSync(req);
    if (res.isSuccess) {
      server.Response_Ok ok = res.value;
      if (ok.hasPlanballance()) {
        return ok.planballance;
      }
    }
    return null;
  }

  Future<Response_Vouchers?> getVoucherList() async {
    var get = ApplicationData_GetVouchers();
    var appData = ApplicationData()..getvouchers = get;
    var req = createClientToServerFromApplicationData(appData);
    Result res = await sendRequestSync(req);
    if (res.isSuccess) {
      server.Response_Ok ok = res.value;
      if (ok.hasVouchers()) {
        return ok.vouchers;
      }
    }
    return null;
  }

  Future<List<Response_AddAccountsInvite>?> getAdditionalUserInvites() async {
    var get = ApplicationData_GetAddAccountsInvites();
    var appData = ApplicationData()..getaddaccountsinvites = get;
    var req = createClientToServerFromApplicationData(appData);
    Result res = await sendRequestSync(req);
    if (res.isSuccess) {
      server.Response_Ok ok = res.value;
      if (ok.hasAddaccountsinvites()) {
        return ok.addaccountsinvites.invites;
      }
    }
    return null;
  }

  Future<Result> updatePlanOptions(bool autoRenewal) async {
    var get = ApplicationData_UpdatePlanOptions()..autoRenewal = autoRenewal;
    var appData = ApplicationData()..updateplanoptions = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> removeAdditionalUser(Int64 userId) async {
    var get = ApplicationData_RemoveAdditionalUser()..userId = userId;
    var appData = ApplicationData()..removeadditionaluser = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req, contactId: userId.toInt());
  }

  Future<Result> buyVoucher(int valueInCents) async {
    var get = ApplicationData_CreateVoucher()..valueCents = valueInCents;
    var appData = ApplicationData()..createvoucher = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> switchToPayedPlan(
      String planId, bool payMonthly, bool autoRenewal) async {
    var get = ApplicationData_SwitchToPayedPlan()
      ..planId = planId
      ..payMonthly = payMonthly
      ..autoRenewal = autoRenewal;
    var appData = ApplicationData()..switchtopayedplan = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> redeemVoucher(String voucher) async {
    var get = ApplicationData_RedeemVoucher()..voucher = voucher;
    var appData = ApplicationData()..redeemvoucher = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> deleteAccount() async {
    var get = ApplicationData_DeleteAccount();
    var appData = ApplicationData()..deleteaccount = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> redeemUserInviteCode(String inviteCode) async {
    var get = ApplicationData_RedeemAdditionalCode()..inviteCode = inviteCode;
    var appData = ApplicationData()..redeemadditionalcode = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> updateFCMToken(String googleFcm) async {
    var get = ApplicationData_UpdateGoogleFcmToken()..googleFcm = googleFcm;
    var appData = ApplicationData()..updategooglefcmtoken = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Result> updateSignedPreKey(
    int signedPreKeyId,
    Uint8List signedPreKey,
    Uint8List signedPreKeySignature,
  ) async {
    var get = ApplicationData_UpdateSignedPreKey()
      ..signedPrekeyId = Int64(signedPreKeyId)
      ..signedPrekey = signedPreKey
      ..signedPrekeySignature = signedPreKeySignature;
    var appData = ApplicationData()..updatesignedprekey = get;
    var req = createClientToServerFromApplicationData(appData);
    return await sendRequestSync(req);
  }

  Future<Response_SignedPreKey?> getSignedKeyByUserId(int userId) async {
    var get = ApplicationData_GetSignedPreKeyByUserId()..userId = Int64(userId);
    var appData = ApplicationData()..getsignedprekeybyuserid = get;
    var req = createClientToServerFromApplicationData(appData);
    Result res = await sendRequestSync(req, contactId: userId);
    if (res.isSuccess) {
      server.Response_Ok ok = res.value;
      if (ok.hasSignedprekey()) {
        return ok.signedprekey;
      }
    }
    return null;
  }

  Future<OtherPreKeys?> getPreKeysByUserId(int userId) async {
    var get = ApplicationData_GetPrekeysByUserId()..userId = Int64(userId);
    var appData = ApplicationData()..getprekeysbyuserid = get;
    var req = createClientToServerFromApplicationData(appData);
    Result res = await sendRequestSync(req, contactId: userId);
    if (res.isSuccess) {
      server.Response_Ok ok = res.value;
      if (ok.hasUserdata()) {
        server.Response_UserData data = ok.userdata;
        if (data.hasSignedPrekey() &&
            data.hasSignedPrekeyId() &&
            data.hasSignedPrekeySignature()) {
          return OtherPreKeys(
            preKeys: ok.userdata.prekeys,
            signedPreKey: data.signedPrekey,
            signedPreKeyId: data.signedPrekeyId.toInt(),
            signedPreKeySignature: data.signedPrekeySignature,
          );
        }
      }
    }
    return null;
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
    return await sendRequestSync(req, contactId: target);
  }
}
