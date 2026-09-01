import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:twonly/core/bridge/api.dart' as rust_api;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/utils/log.dart';

/// The ApiProvider is responsible for communicating with the server.
/// It handles errors and does automatically tries to reconnect on
/// errors or network changes.
class ApiService {
  ApiService() {
    events = rust_api.RustApi.events().asBroadcastStream();
    _apiEventSubscription = events.listen(
      _handleApiEvent,
      onError: (Object error, StackTrace stackTrace) {
        Log.error(
          'Rust API event stream failed',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
  }
  late final Stream<ApiEvent> events;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  late final StreamSubscription<ApiEvent> _apiEventSubscription;

  /// The server rejects an outdated app or a superseded device during the
  /// handshake, which usually happens before the widget showing that banner is
  /// mounted. [events] is a broadcast stream, so late listeners would miss it —
  /// they read the last rejection from here instead.
  ApiEventKind? permanentRejection;

  Future<void> _handleApiEvent(ApiEvent event) async {
    if (event.kind == ApiEventKind.authenticated) {
      await onAuthenticated();
    }
    if (event.kind == ApiEventKind.appOutdated ||
        event.kind == ApiEventKind.newDeviceRegistered) {
      permanentRejection = event.kind;
    }
  }

  // Function is called after the user is authenticated at the server
  Future<void> onAuthenticated() async {
    await FcmNotificationService.initFCMAfterAuthenticated();

    if (!AppState.isAppInBackground) {
      unawaitedRustCall(
        rust_api.RustApi.reuploadPendingMedia(),
        'reuploadPendingMedia',
      );

      twonlyDB.markUpdated();
      // resetUserDiscoveryRequestUpdates();
      memoriesCloudService.init();
    }
  }

  Future<void> listenToNetworkChanges() async {
    if (_connectivitySubscription != null) {
      return;
    }
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      await rust_api.RustApi.setNetworkAvailable(
        available: !result.contains(ConnectivityResult.none),
      );
    });
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _apiEventSubscription.cancel();
  }
}
