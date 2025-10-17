// ignore_for_file: avoid_dynamic_calls, strict_raw_type

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
// ignore: implementation_imports
import 'package:libsignal_protocol_dart/src/ecc/ed25519.dart';
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
import 'package:twonly/src/services/api/media_download.dart';
import 'package:twonly/src/services/api/media_upload.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/server_messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/fcm.service.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/prekeys.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final lockConnecting = Mutex();
final lockRetransStore = Mutex();

/// The ApiProvider is responsible for communicating with the server.
/// It handles errors and does automatically tries to reconnect on
/// errors or network changes.
class ApiService {
  ApiService();
  final String apiHost = kDebugMode ? '10.99.0.140:3030' : 'api.twonly.eu';
  final String apiSecure = kDebugMode ? '' : 's';

  bool appIsOutdated = false;
  bool isAuthenticated = false;

  // reconnection params
  Timer? reconnectionTimer;
  int _reconnectionDelay = 5;

  final HashMap<Int64, server.ServerToClient?> messagesV0 = HashMap();
  IOWebSocketChannel? _channel;
  // ignore: cancel_subscriptions
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  Future<bool> _connectTo(String apiUrl) async {
    if (appIsOutdated) return false;
    try {
      final channel = IOWebSocketChannel.connect(
        Uri.parse(apiUrl),
      );
      _channel = channel;
      _channel!.stream.listen(_onData, onDone: _onDone, onError: _onError);
      await _channel!.ready;
      Log.info('websocket connected to $apiUrl');
      return true;
    } on WebSocketChannelException catch (e) {
      if (!e.message
          .toString()
          .contains('No address associated with hostname')) {
        Log.error('could not connect to api got: $e');
      }
      return false;
    }
  }

  // Function is called after the user is authenticated at the server
  Future<void> onAuthenticated() async {
    isAuthenticated = true;
    await initFCMAfterAuthenticated();
    globalCallbackConnectionState(isConnected: true);

    if (!globalIsAppInBackground) {
      unawaited(retransmitRawBytes());
      unawaited(tryTransmitMessages());
      unawaited(retryMediaUpload(false));
      unawaited(tryDownloadAllMediaFiles());
      unawaited(notifyContactsAboutProfileChange());
      twonlyDB.markUpdated();
      unawaited(syncFlameCounters());
      unawaited(setupNotificationWithUsers());
      unawaited(signalHandleNewServerConnection());
    }
  }

  Future<void> onConnected() async {
    await authenticate();
    _reconnectionDelay = 5;
    globalCallbackConnectionState(isConnected: true);
  }

  Future<void> onClosed() async {
    _channel = null;
    isAuthenticated = false;
    globalCallbackConnectionState(isConnected: false);
    await twonlyDB.messagesDao.resetPendingDownloadState();
  }

  Future<void> startReconnectionTimer() async {
    reconnectionTimer?.cancel();
    reconnectionTimer ??=
        Timer(Duration(seconds: _reconnectionDelay), () async {
      reconnectionTimer = null;
      await connect(force: true);
    });
    _reconnectionDelay += 5;
  }

  Future<void> close(Function callback) async {
    Log.info('closing websocket connection');
    if (_channel != null) {
      await _channel!.sink.close();
      await onClosed();
      callback();
      return;
    }
    callback();
  }

  Future<void> listenToNetworkChanges() async {
    if (connectivitySubscription != null) {
      return;
    }
    connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) async {
      if (!result.contains(ConnectivityResult.none)) {
        await connect(force: true);
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
      globalCallbackConnectionState(isConnected: true);
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

      final apiUrl = 'ws$apiSecure://$apiHost/api/client';

      Log.info('connecting to $apiUrl');

      if (await _connectTo(apiUrl)) {
        await onConnected();
        return true;
      }
      return false;
    });
  }

  bool get isConnected => _channel != null && _channel!.closeCode != null;

  Future<void> _onDone() async {
    Log.info('websocket closed without error');
    await onClosed();
  }

  Future<void> _onError(dynamic e) async {
    Log.error('websocket error: $e');
    await onClosed();
  }

  Future<void> _onData(dynamic msgBuffer) async {
    try {
      final msg = server.ServerToClient.fromBuffer(msgBuffer as Uint8List);
      if (msg.v0.hasResponse()) {
        await removeFromRetransmissionBuffer(msg.v0.seq);
        messagesV0[msg.v0.seq] = msg;
      } else {
        await handleServerMessage(msg);
      }
    } catch (e) {
      Log.error('Error parsing the servers message: $e');
    }
  }

  Future<server.ServerToClient?> _waitForResponse(Int64 seq) async {
    final startTime = DateTime.now();

    const timeout = Duration(seconds: 20);

    while (true) {
      if (messagesV0[seq] != null) {
        final tmp = messagesV0[seq];
        messagesV0.remove(seq);
        return tmp;
      }
      if (DateTime.now().difference(startTime) > timeout) {
        Log.error('Timeout for message $seq');
        return null;
      }
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  Future<void> sendResponse(ClientToServer response) async {
    if (_channel != null) {
      _channel!.sink.add(response.writeToBuffer());
    }
  }

  Future<Map<String, dynamic>> getRetransmission() async {
    return (await KeyValueStore.get('rawbytes-to-retransmit')) ?? {};
  }

  Future<void> retransmitRawBytes() async {
    await lockRetransStore.protect(() async {
      final retransmit = await getRetransmission();
      if (retransmit.keys.isEmpty) return;
      Log.info('retransmitting ${retransmit.keys.length} raw bytes messages');
      var gotError = false;
      for (final seq in retransmit.keys) {
        try {
          _channel!.sink.add(base64Decode(retransmit[seq] as String));
        } catch (e) {
          gotError = true;
          Log.error('$e');
        }
      }
      if (!gotError) {
        await KeyValueStore.put('rawbytes-to-retransmit', {});
      }
    });
  }

  Future<void> addToRetransmissionBuffer(Int64 seq, Uint8List bytes) async {
    await lockRetransStore.protect(() async {
      final retransmit = await getRetransmission();
      retransmit[seq.toString()] = base64Encode(bytes);
      await KeyValueStore.put('rawbytes-to-retransmit', retransmit);
    });
  }

  Future<void> removeFromRetransmissionBuffer(Int64 seq) async {
    await lockRetransStore.protect(() async {
      final retransmit = await getRetransmission();
      if (retransmit.isEmpty) return;
      retransmit.remove(seq.toString());
      await KeyValueStore.put('rawbytes-to-retransmit', retransmit);
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
      await addToRetransmissionBuffer(seq, requestBytes);
    }

    if (_channel == null) {
      Log.warn('sending request while api is not connected');
      if (!await connect()) {
        return Result.error(ErrorCode.InternalError);
      }
      if (_channel == null) {
        return Result.error(ErrorCode.InternalError);
      }
    }

    _channel!.sink.add(requestBytes);

    final res = asResult(await _waitForResponse(seq));
    if (res.isError) {
      Log.error('got error from server: ${res.error}');
      if (res.error == ErrorCode.AppVersionOutdated) {
        globalCallbackAppIsOutdated();
        Log.error('App Version is OUTDATED.');
        appIsOutdated = true;
        await close(() {});
        return Result.error(ErrorCode.InternalError);
      }
      if (res.error == ErrorCode.NewDeviceRegistered) {
        globalCallbackNewDeviceRegistered();
        Log.error('Device is disabled, as a newer device restore twonly Safe.');
        appIsOutdated = true;
        await close(() {});
        return Result.error(ErrorCode.InternalError);
      }
      if (res.error == ErrorCode.SessionNotAuthenticated) {
        isAuthenticated = false;
        if (authenticated) {
          await authenticate();
          if (isAuthenticated) {
            // this will send the request one more time.
            return sendRequestSync(request, authenticated: false);
          } else {
            Log.error('session is not authenticated');
            return Result.error(ErrorCode.InternalError);
          }
        }
      }
      if (res.error == ErrorCode.UserIdNotFound && contactId != null) {
        Log.error('Contact deleted their account $contactId.');
        final contact = await twonlyDB.contactsDao
            .getContactByUserId(contactId)
            .getSingleOrNull();
        if (contact != null) {
          await twonlyDB.contactsDao.updateContact(
            contactId,
            ContactsCompanion(
              deleted: const Value(true),
              username: Value('${contact.username} (${contact.userId})'),
            ),
          );
        }
      }
    }
    return res;
  }

  Future<bool> tryAuthenticateWithToken(int userId) async {
    const storage = FlutterSecureStorage();
    final apiAuthToken =
        await storage.read(key: SecureStorageKeys.apiAuthToken);
    final user = await getUser();

    if (apiAuthToken != null && user != null) {
      final authenticate = Handshake_Authenticate()
        ..userId = Int64(userId)
        ..appVersion = (await PackageInfo.fromPlatform()).version
        ..deviceId = Int64(user.deviceId)
        ..authToken = base64Decode(apiAuthToken);

      final handshake = Handshake()..authenticate = authenticate;
      final req = createClientToServerFromHandshake(handshake);

      final result = await sendRequestSync(req, authenticated: false);

      if (result.isSuccess) {
        final ok = result.value as server.Response_Ok;
        if (ok.hasAuthenticated()) {
          final authenticated = ok.authenticated;
          await updateUserdata((user) {
            user.subscriptionPlan = authenticated.plan;
            return user;
          });
          globalCallbackUpdatePlan(authenticated.plan);
        }
        Log.info('websocket is authenticated');
        unawaited(onAuthenticated());
        return true;
      }
      if (result.isError) {
        if (result.error != ErrorCode.AuthTokenNotValid) {
          Log.error('got error while authenticating to the server', result);
          return false;
        }
      }
    }
    return false;
  }

  Future<void> authenticate() async {
    if (isAuthenticated) return;
    if (await getSignalIdentity() == null) {
      return;
    }

    final userData = await getUser();
    if (userData == null) return;

    if (await tryAuthenticateWithToken(userData.userId)) {
      return;
    }

    final handshake = Handshake()
      ..getauthchallenge = Handshake_GetAuthChallenge();
    final req = createClientToServerFromHandshake(handshake);

    final result = await sendRequestSync(req, authenticated: false);
    if (result.isError) {
      Log.error('could not request auth challenge', result);
      return;
    }

    final challenge = result.value.authchallenge;

    var privKey = (await getSignalIdentityKeyPair())?.getPrivateKey();
    if (privKey == null) return;
    final random = getRandomUint8List(32);
    final signature = sign(privKey.serialize(), challenge as Uint8List, random);
    privKey = null;

    final getAuthToken = Handshake_GetAuthToken()
      ..response = signature
      ..userId = Int64(userData.userId);

    final getauthtoken = Handshake()..getauthtoken = getAuthToken;

    final req2 = createClientToServerFromHandshake(getauthtoken);

    final result2 = await sendRequestSync(req2, authenticated: false);
    if (result2.isError) {
      Log.error('could not send auth response: ${result2.error}');
      return;
    }

    final apiAuthToken = result2.value.authtoken as Uint8List;
    final apiAuthTokenB64 = base64Encode(apiAuthToken);

    const storage = FlutterSecureStorage();
    await storage.write(
      key: SecureStorageKeys.apiAuthToken,
      value: apiAuthTokenB64,
    );

    await tryAuthenticateWithToken(userData.userId);
  }

  Future<Result> register(String username, String? inviteCode) async {
    final signalIdentity = await getSignalIdentity();
    if (signalIdentity == null) {
      return Result.error(ErrorCode.InternalError);
    }

    final signalStore = await getSignalStoreFromIdentity(signalIdentity);

    final signedPreKey = (await signalStore.loadSignedPreKeys())[0];

    final register = Handshake_Register()
      ..username = username
      ..publicIdentityKey =
          (await signalStore.getIdentityKeyPair()).getPublicKey().serialize()
      ..registrationId = Int64(signalIdentity.registrationId)
      ..signedPrekey = signedPreKey.getKeyPair().publicKey.serialize()
      ..signedPrekeySignature = signedPreKey.signature
      ..signedPrekeyId = Int64(signedPreKey.id)
      ..isIos = Platform.isIOS;

    if (inviteCode != null && inviteCode != '') {
      register.inviteCode = inviteCode;
    }

    final handshake = Handshake()..register = register;
    final req = createClientToServerFromHandshake(handshake);

    return sendRequestSync(req);
  }

  Future<Result> getUsername(int userId) async {
    final get = ApplicationData_GetUserById()..userId = Int64(userId);
    final appData = ApplicationData()..getuserbyid = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req, contactId: userId);
  }

  Future<Result> downloadDone(List<int> token) async {
    final get = ApplicationData_DownloadDone()..downloadToken = token;
    final appData = ApplicationData()..downloaddone = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req, ensureRetransmission: true);
  }

  Future<Result> getCurrentLocation() async {
    final get = ApplicationData_GetLocation();
    final appData = ApplicationData()..getlocation = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Response_UserData?> getUserData(String username) async {
    final get = ApplicationData_GetUserByUsername()..username = username;
    final appData = ApplicationData()..getuserbyusername = get;
    final req = createClientToServerFromApplicationData(appData);
    final res = await sendRequestSync(req);
    if (res.isSuccess) {
      final ok = res.value as server.Response_Ok;
      if (ok.hasUserdata()) {
        return ok.userdata;
      }
    }
    return null;
  }

  Future<Response_PlanBallance?> getPlanBallance() async {
    final get = ApplicationData_GetCurrentPlanInfos();
    final appData = ApplicationData()..getcurrentplaninfos = get;
    final req = createClientToServerFromApplicationData(appData);
    final res = await sendRequestSync(req);
    if (res.isSuccess) {
      final ok = res.value as server.Response_Ok;
      if (ok.hasPlanballance()) {
        return ok.planballance;
      }
    }
    return null;
  }

  Future<Response_Vouchers?> getVoucherList() async {
    final get = ApplicationData_GetVouchers();
    final appData = ApplicationData()..getvouchers = get;
    final req = createClientToServerFromApplicationData(appData);
    final res = await sendRequestSync(req);
    if (res.isSuccess) {
      final ok = res.value as server.Response_Ok;
      if (ok.hasVouchers()) {
        return ok.vouchers;
      }
    }
    return null;
  }

  Future<List<Response_AddAccountsInvite>?> getAdditionalUserInvites() async {
    final get = ApplicationData_GetAddAccountsInvites();
    final appData = ApplicationData()..getaddaccountsinvites = get;
    final req = createClientToServerFromApplicationData(appData);
    final res = await sendRequestSync(req);
    if (res.isSuccess) {
      final ok = res.value as server.Response_Ok;
      if (ok.hasAddaccountsinvites()) {
        return ok.addaccountsinvites.invites;
      }
    }
    return null;
  }

  Future<Result> updatePlanOptions(bool autoRenewal) async {
    final get = ApplicationData_UpdatePlanOptions()..autoRenewal = autoRenewal;
    final appData = ApplicationData()..updateplanoptions = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> removeAdditionalUser(Int64 userId) async {
    final get = ApplicationData_RemoveAdditionalUser()..userId = userId;
    final appData = ApplicationData()..removeadditionaluser = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req, contactId: userId.toInt());
  }

  Future<Result> buyVoucher(int valueInCents) async {
    final get = ApplicationData_CreateVoucher()..valueCents = valueInCents;
    final appData = ApplicationData()..createvoucher = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> switchToPayedPlan(
    String planId,
    bool payMonthly,
    bool autoRenewal,
  ) async {
    final get = ApplicationData_SwitchToPayedPlan()
      ..planId = planId
      ..payMonthly = payMonthly
      ..autoRenewal = autoRenewal;
    final appData = ApplicationData()..switchtopayedplan = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> redeemVoucher(String voucher) async {
    final get = ApplicationData_RedeemVoucher()..voucher = voucher;
    final appData = ApplicationData()..redeemvoucher = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> reportUser(int userId, String reason) async {
    final get = ApplicationData_ReportUser()
      ..reportedUserId = Int64(userId)
      ..reason = reason;
    final appData = ApplicationData()..reportuser = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> deleteAccount() async {
    final get = ApplicationData_DeleteAccount();
    final appData = ApplicationData()..deleteaccount = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> redeemUserInviteCode(String inviteCode) async {
    final get = ApplicationData_RedeemAdditionalCode()..inviteCode = inviteCode;
    final appData = ApplicationData()..redeemadditionalcode = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> updateFCMToken(String googleFcm) async {
    final get = ApplicationData_UpdateGoogleFcmToken()..googleFcm = googleFcm;
    final appData = ApplicationData()..updategooglefcmtoken = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> updateSignedPreKey(
    int signedPreKeyId,
    Uint8List signedPreKey,
    Uint8List signedPreKeySignature,
  ) async {
    final get = ApplicationData_UpdateSignedPreKey()
      ..signedPrekeyId = Int64(signedPreKeyId)
      ..signedPrekey = signedPreKey
      ..signedPrekeySignature = signedPreKeySignature;
    final appData = ApplicationData()..updatesignedprekey = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Response_SignedPreKey?> getSignedKeyByUserId(int userId) async {
    final get = ApplicationData_GetSignedPreKeyByUserId()
      ..userId = Int64(userId);
    final appData = ApplicationData()..getsignedprekeybyuserid = get;
    final req = createClientToServerFromApplicationData(appData);
    final res = await sendRequestSync(req, contactId: userId);
    if (res.isSuccess) {
      final ok = res.value as server.Response_Ok;
      if (ok.hasSignedprekey()) {
        return ok.signedprekey;
      }
    }
    return null;
  }

  Future<OtherPreKeys?> getPreKeysByUserId(int userId) async {
    final get = ApplicationData_GetPrekeysByUserId()..userId = Int64(userId);
    final appData = ApplicationData()..getprekeysbyuserid = get;
    final req = createClientToServerFromApplicationData(appData);
    final res = await sendRequestSync(req, contactId: userId);
    if (res.isSuccess) {
      final ok = res.value as server.Response_Ok;
      if (ok.hasUserdata()) {
        final data = ok.userdata;
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
    int target,
    Uint8List msg,
    List<int>? pushData,
  ) async {
    final testMessage = ApplicationData_TextMessage()
      ..userId = Int64(target)
      ..body = msg;

    if (pushData != null) {
      testMessage.pushData = pushData;
    }

    final appData = ApplicationData()..textmessage = testMessage;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req, contactId: target);
  }
}
