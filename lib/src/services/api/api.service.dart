import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:twonly/core/bridge/api.dart' as rust_api;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/api/mediafiles/download.api.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/group.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/signal/identity.signal.dart';
import 'package:twonly/src/services/signal/protocol_state.signal.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/log.dart';

/// The ApiProvider is responsible for communicating with the server.
/// It handles errors and does automatically tries to reconnect on
/// errors or network changes.
class ApiService {
  ApiService();
  final String apiHost = kReleaseMode ? 'api.twonly.eu' : 'dev-api.twonly.eu';
  // final String apiHost = kReleaseMode ? 'api.twonly.eu' : 'dev.twonly.eu';
  final String apiSecure = kReleaseMode ? 's' : 's';

  String get apiEndpoint => 'http$apiSecure://$apiHost/api/';

  final _planUpdateController = StreamController<SubscriptionPlan>.broadcast();
  Stream<SubscriptionPlan> get onPlanUpdated => _planUpdateController.stream;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectionStateUpdated =>
      _connectionStateController.stream;

  final _appOutdatedController = StreamController<void>.broadcast();
  Stream<void> get onAppOutdated => _appOutdatedController.stream;

  final _newDeviceRegisteredController = StreamController<void>.broadcast();
  Stream<void> get onNewDeviceRegistered =>
      _newDeviceRegisteredController.stream;

  bool appIsOutdated = false;
  bool isAuthenticated = false;
  bool isConnected = false;

  // ignore: cancel_subscriptions
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Function is called after the user is authenticated at the server
  Future<void> onAuthenticated() async {
    await FcmNotificationService.initFCMAfterAuthenticated();
    _connectionStateController.add(true);

    if (AppState.isInBackgroundTask) {
      await RustApi.retransmitAllMessages();
      await reuploadMediaFiles();
      await tryDownloadAllMediaFiles();
    } else if (!AppState.isAppInBackground) {
      unawaited(RustApi.retransmitAllMessages());
      unawaited(tryDownloadAllMediaFiles());
      unawaited(reuploadMediaFiles());

      twonlyDB.markUpdated();
      unawaited(syncFlameCounters());
      unawaited(SignalIdentityService.onAuthenticated());
      resetResyncedUsers();
      // resetUserDiscoveryRequestUpdates();
      unawaited(fetchGroupStatesForUnjoinedGroups());
      unawaited(fetchMissingGroupPublicKey());
      unawaited(rust_api.RustApi.checkForDeletedUsernames());
      unawaited(RustApi.performPasswordlessRecoveryHeartbeat());

      unawaited(UserDiscoveryService.checkForNewAnnouncedUsers());
      memoriesCloudService.init();
    }
  }

  Future<bool> connect() async {
    try {
      await rust_api.RustApi.connect();
      for (var attempt = 0; attempt < 100; attempt++) {
        final state = await rust_api.RustApi.connectionState();
        isConnected =
            state == ApiConnectionState.connected ||
            state == ApiConnectionState.authenticated;
        isAuthenticated = state == ApiConnectionState.authenticated;
        if (isAuthenticated ||
            (!userService.isUserCreated &&
                state == ApiConnectionState.connected)) {
          return true;
        }
        if (state == ApiConnectionState.permanentlyRejected ||
            state == ApiConnectionState.suspended) {
          return false;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      return false;
    } catch (error) {
      isConnected = false;
      isAuthenticated = false;
      Log.error('Rust API connection failed', error: error);
      return false;
    }
  }

  Future<void> close(VoidCallback? callback) async {
    await rust_api.RustApi.close();
    isConnected = false;
    isAuthenticated = false;
    _connectionStateController.add(false);
    callback?.call();
  }

  Future<void> authenticate() async {
    await rust_api.RustApi.reloadConfiguration();
    await connect();
  }

  Future<void> listenToNetworkChanges() async {
    if (_connectivitySubscription != null) {
      return;
    }
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      if (!result.contains(ConnectivityResult.none)) {
        await connect();
      }
      // Received changes in available connectivity types!
    });
  }
}
