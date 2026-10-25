import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:twonly/core/bridge/api.dart' as rust_api;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/api/connection_lifecycle.dart';
import 'package:twonly/src/services/home_widget.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
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
  late final _connectionLifecycle = ConnectionLifecycle(
    hasActiveConnection: () async =>
        switch (await rust_api.RustApi.connectionState()) {
          ApiConnectionState.authenticated ||
          ApiConnectionState.authenticating ||
          ApiConnectionState.connected ||
          ApiConnectionState.connecting ||
          ApiConnectionState.reconnecting => true,
          _ => false,
        },
    readNetworkAvailable: () async =>
        !(await Connectivity().checkConnectivity()).contains(
          ConnectivityResult.none,
        ),
    applyNetworkAvailable: (available) =>
        rust_api.RustApi.setNetworkAvailable(available: available),
    applyBackground: (background) =>
        rust_api.RustApi.setBackground(inBackground: background),
    onError: (error, stackTrace) => Log.error(
      'API lifecycle update failed',
      error: error,
      stackTrace: stackTrace,
    ),
  );

  Future<void> setBackground(bool inBackground) =>
      _connectionLifecycle.setBackground(inBackground);

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
    if (event.kind == ApiEventKind.widgetMediaReceived) {
      // Rust has already rewritten the manifest; the home screen still shows
      // what the widgets drew before it arrived.
      unawaited(HomeWidgetService.refresh());
    }
  }

  // Function is called after the user is authenticated at the server
  Future<void> onAuthenticated() async {
    // A passwordless recovery restores the identity into the key manager
    // before a user config exists, so the socket can authenticate while
    // `currentUser` is still unset. Everything below reads that config.
    if (!userService.isUserCreated) {
      Log.info('Skipping onAuthenticated: the user config is not loaded yet');
      return;
    }

    unawaited(FcmNotificationService.initFCMAfterAuthenticated());

    if (!AppState.isAppInBackground) {
      refreshDatabaseSubscriptions();
      // resetUserDiscoveryRequestUpdates();
      memoriesCloudService.init();
    }
  }

  Future<void> listenToNetworkChanges() async {
    if (_connectivitySubscription != null) {
      return;
    }
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      unawaited(_networkChanged(results));
    });
    await _networkChanged(await Connectivity().checkConnectivity());
  }

  Future<void> _networkChanged(List<ConnectivityResult> results) {
    // The initial query and stream often report the same route. Preserve real
    // Wi-Fi/mobile changes while coalescing identical startup notifications.
    final types = results.map((result) => result.index).toSet().toList()
      ..sort();
    return _connectionLifecycle.networkChanged(identity: types.join(','));
  }

  Future<void> dispose() async {
    await _connectivitySubscription?.cancel();
    await _apiEventSubscription.cancel();
  }
}
