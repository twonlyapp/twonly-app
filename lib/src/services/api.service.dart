// ignore_for_file: avoid_dynamic_calls, strict_raw_type

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

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
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/client_to_server.pbserver.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pbserver.dart';
import 'package:twonly/src/services/api/mediafiles/download.service.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/api/server_messages.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/services/fcm.service.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/group.services.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/prekeys.signal.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:web_socket_channel/io.dart';

final lockConnecting = Mutex();
final lockRetransStore = Mutex();

/// The ApiProvider is responsible for communicating with the server.
/// It handles errors and does automatically tries to reconnect on
/// errors or network changes.
class ApiService {
  ApiService();
  final String apiHost = kReleaseMode ? 'api.twonly.eu' : '10.99.0.140:3030';
  // final String apiHost = kReleaseMode ? 'api.twonly.eu' : 'dev.twonly.eu';
  final String apiSecure = kReleaseMode ? 's' : '';

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
    } catch (_) {
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
      unawaited(tryDownloadAllMediaFiles());
      twonlyDB.markUpdated();
      unawaited(syncFlameCounters());
      unawaited(setupNotificationWithUsers());
      unawaited(signalHandleNewServerConnection());
      unawaited(fetchGroupStatesForUnjoinedGroups());
      unawaited(fetchMissingGroupPublicKey());
      unawaited(checkForDeletedUsernames());
    }
  }

  Future<void> onConnected() async {
    await authenticate();
    _reconnectionDelay = 1;
    globalCallbackConnectionState(isConnected: true);
  }

  Future<void> onClosed() async {
    _channel = null;
    isAuthenticated = false;
    globalCallbackConnectionState(isConnected: false);
    await twonlyDB.mediaFilesDao.resetPendingDownloadState();
    await startReconnectionTimer();
  }

  Future<void> startReconnectionTimer() async {
    if (reconnectionTimer?.isActive ?? false) {
      return;
    }
    reconnectionTimer?.cancel();
    Log.info('Starting reconnection timer with $_reconnectionDelay s delay');
    reconnectionTimer = Timer(Duration(seconds: _reconnectionDelay), () async {
      Log.info('Reconnection timer triggered');
      reconnectionTimer = null;
      await connect();
    });
    _reconnectionDelay = 3;
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
        await connect();
      }
      // Received changes in available connectivity types!
    });
  }

  Future<bool> connect() async {
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
    Log.warn('websocket error: $e');
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

    const timeout = Duration(seconds: 60);

    while (true) {
      if (messagesV0[seq] != null) {
        final tmp = messagesV0[seq];
        messagesV0.remove(seq);
        return tmp;
      }
      if (DateTime.now().difference(startTime) > timeout) {
        Log.warn('Timeout for message $seq');
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
        Log.warn('could not connected again');
        return Result.error(ErrorCode.InternalError);
      }
      if (_channel == null) {
        return Result.error(ErrorCode.InternalError);
      }
    }

    _channel!.sink.add(requestBytes);

    final res = asResult(await _waitForResponse(seq));
    if (res.isSuccess) {
      final ok = res.value as server.Response_Ok;
      if (ok.hasAuthenticated()) {
        final authenticated = ok.authenticated;
        await updateUserdata((user) {
          user.subscriptionPlan = authenticated.plan;
          return user;
        });
        globalCallbackUpdatePlan(planFromString(authenticated.plan));
      }
    }
    if (res.isError) {
      Log.warn('Got error from server: ${res.error}');
      if (res.error == ErrorCode.AppVersionOutdated) {
        globalCallbackAppIsOutdated();
        Log.warn('App Version is OUTDATED.');
        appIsOutdated = true;
        await close(() {});
        return Result.error(ErrorCode.InternalError);
      }
      if (res.error == ErrorCode.NewDeviceRegistered) {
        globalCallbackNewDeviceRegistered();
        Log.warn(
          'Device is disabled, as a newer device restore twonly Backup.',
        );
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
            Log.warn('Session is not authenticated');
            return Result.error(ErrorCode.InternalError);
          }
        }
      }
      if (res.error == ErrorCode.UserIdNotFound && contactId != null) {
        Log.warn('Contact deleted their account $contactId.');
        final contact = await twonlyDB.contactsDao
            .getContactByUserId(contactId)
            .getSingleOrNull();
        if (contact != null) {
          await twonlyDB.contactsDao.updateContact(
            contactId,
            const ContactsCompanion(
              accountDeleted: Value(true),
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
      if (user.appVersion < 62) {
        Log.error(
          'DID NOT authenticate the user, as he still has the old version!',
        );
        return false;
      }
      final authenticate = Handshake_Authenticate()
        ..userId = Int64(userId)
        ..appVersion = (await PackageInfo.fromPlatform()).version
        ..deviceId = Int64(user.deviceId)
        ..authToken = base64Decode(apiAuthToken);

      final handshake = Handshake()..authenticate = authenticate;
      final req = createClientToServerFromHandshake(handshake);

      final result = await sendRequestSync(req, authenticated: false);

      if (result.isSuccess) {
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
      ..getAuthChallenge = Handshake_GetAuthChallenge();
    final req = createClientToServerFromHandshake(handshake);

    final result = await sendRequestSync(req, authenticated: false);
    if (result.isError) {
      Log.warn('could not request auth challenge', result);
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

    final getauthtoken = Handshake()..getAuthToken = getAuthToken;

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

  Future<Result> register(
    String username,
    String? inviteCode,
    int proofOfWorkResult,
  ) async {
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
      ..langCode = ui.PlatformDispatcher.instance.locale.languageCode
      ..proofOfWork = Int64(proofOfWorkResult)
      ..isIos = Platform.isIOS;

    if (inviteCode != null && inviteCode != '') {
      register.inviteCode = inviteCode;
    }

    final handshake = Handshake()..register = register;
    final req = createClientToServerFromHandshake(handshake);

    return sendRequestSync(req);
  }

  Future<void> checkForDeletedUsernames() async {
    final users = await twonlyDB.contactsDao
        .getContactsByUsername('[deleted]', username2: '[Unknown]');
    for (final user in users) {
      final userData = await getUserById(user.userId);
      if (userData != null) {
        await twonlyDB.contactsDao.updateContact(
          user.userId,
          ContactsCompanion(username: Value(utf8.decode(userData.username))),
        );
      }
    }
  }

  Future<Response_UserData?> getUserById(int userId) async {
    final get = ApplicationData_GetUserById()..userId = Int64(userId);
    final appData = ApplicationData()..getUserById = get;
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

  Future<(Response_ProofOfWork?, bool)> getProofOfWork() async {
    final handshake = Handshake()..requestPOW = Handshake_RequestPOW();
    final req = createClientToServerFromHandshake(handshake);
    final result = await sendRequestSync(req, authenticated: false);
    if (result.isError) {
      Log.error('could not request proof of work params', result);
      if (result.error == ErrorCode.RegistrationDisabled) {
        return (null, true);
      }
      Log.error('could not request proof of work params', result);
      return (null, false);
    }
    return (result.value.proofOfWork as Response_ProofOfWork, false);
  }

  Future<Result> downloadDone(List<int> token) async {
    final get = ApplicationData_DownloadDone()..downloadToken = token;
    final appData = ApplicationData()..downloadDone = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req, ensureRetransmission: true);
  }

  Future<Result> getCurrentLocation() async {
    final get = ApplicationData_GetLocation();
    final appData = ApplicationData()..getLocation = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Response_UserData?> getUserData(String username) async {
    final get = ApplicationData_GetUserByUsername()..username = username;
    final appData = ApplicationData()..getUserByUsername = get;
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
    final appData = ApplicationData()..getCurrentPlanInfos = get;
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
    final appData = ApplicationData()..getVouchers = get;
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
    final appData = ApplicationData()..getAddaccountsInvites = get;
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
    final appData = ApplicationData()..updatePlanOptions = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> removeAdditionalUser(Int64 userId) async {
    final get = ApplicationData_RemoveAdditionalUser()..userId = userId;
    final appData = ApplicationData()..removeAdditionalUser = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req, contactId: userId.toInt());
  }

  Future<Result> buyVoucher(int valueInCents) async {
    final get = ApplicationData_CreateVoucher()..valueCents = valueInCents;
    final appData = ApplicationData()..createVoucher = get;
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
    final appData = ApplicationData()..switchtoPayedPlan = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> redeemVoucher(String voucher) async {
    final get = ApplicationData_RedeemVoucher()..voucher = voucher;
    final appData = ApplicationData()..redeemVoucher = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> reportUser(int userId, String reason) async {
    final get = ApplicationData_ReportUser()
      ..reportedUserId = Int64(userId)
      ..reason = reason;
    final appData = ApplicationData()..reportUser = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> deleteAccount() async {
    final get = ApplicationData_DeleteAccount();
    final appData = ApplicationData()..deleteAccount = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> redeemUserInviteCode(String inviteCode) async {
    final get = ApplicationData_RedeemAdditionalCode()..inviteCode = inviteCode;
    final appData = ApplicationData()..redeemAdditionalCode = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> updateFCMToken(String googleFcm) async {
    final get = ApplicationData_UpdateGoogleFcmToken()..googleFcm = googleFcm;
    final appData = ApplicationData()..updateGoogleFcmToken = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> ipaPurchase(
    String productId,
    String source,
    String verificationData,
  ) async {
    final appData = ApplicationData(
      ipaPurchase: ApplicationData_IPAPurchase(
        productId: productId,
        source: source,
        verificationData: verificationData,
      ),
    );
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> changeUsername(String username) async {
    final get = ApplicationData_ChangeUsername()..username = username;
    final appData = ApplicationData()..changeUsername = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Result> forceIpaCheck() async {
    final req = createClientToServerFromApplicationData(
      ApplicationData(
        ipaForceCheck: ApplicationData_IPAForceCheck(),
      ),
    );
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
    final appData = ApplicationData()..updateSignedPrekey = get;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req);
  }

  Future<Response_SignedPreKey?> getSignedKeyByUserId(int userId) async {
    final get = ApplicationData_GetSignedPreKeyByUserId()
      ..userId = Int64(userId);
    final appData = ApplicationData()..getSignedPrekeyByUserid = get;
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
    final appData = ApplicationData()..getPrekeysByUserId = get;
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

  Future<Response_PlanBallance?> loadPlanBalance({bool useCache = true}) async {
    final ballance = await getPlanBallance();
    if (ballance != null) {
      await updateUserdata((u) {
        u.lastPlanBallance = ballance.writeToJson();
        return u;
      });
      return ballance;
    }
    final user = await getUser();
    if (user != null && user.lastPlanBallance != null && useCache) {
      try {
        return Response_PlanBallance.fromJson(
          user.lastPlanBallance!,
        );
      } catch (e) {
        Log.error('from json: $e');
      }
    }
    return ballance;
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
    final appData = ApplicationData()..textMessage = testMessage;
    final req = createClientToServerFromApplicationData(appData);
    return sendRequestSync(req, contactId: target);
  }
}
