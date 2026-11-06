import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/log.dart';

class LocationMetadataService with WidgetsBindingObserver {
  static const _channel = MethodChannel('eu.twonly/location_metadata');
  static final _instance = LocationMetadataService();
  static StreamSubscription<void>? _userUpdates;

  /// Foreground startup never opens a permission sheet. Memories share
  /// Rust's one-shot acquisition and short-lived coordinate cache.
  static void initialize() {
    if (_userUpdates != null) return;
    WidgetsBinding.instance.addObserver(_instance);
    _userUpdates = userService.onUserUpdated.listen((_) => _warmUp());
    unawaited(_warmUp());
  }

  static void dispose() {
    unawaited(_userUpdates?.cancel());
    _userUpdates = null;
    WidgetsBinding.instance.removeObserver(_instance);
  }

  static bool get _isForeground {
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  static Future<void> _warmUp() async {
    try {
      if (!_isForeground || !userService.isUserCreated) return;
      if (!userService.currentUser.storeLocationInMemories) return;
      if (!await _hasPermission()) return;
      if (!_isForeground) return;
      await RustApi.prewarmMemoryLocation();
    } on Object catch (error) {
      if (isBackgroundCancellation(error)) return;
      Log.warn('Could not warm up location: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_warmUp());
  }

  static Future<bool> _hasPermission() async =>
      await _channel.invokeMethod<bool>('hasPrecisePermission') ?? false;

  /// Opens the native permission sheet only after the user enables the switch.
  /// Approximate/reduced access is rejected because this feature promises a
  /// precise capture location.
  static Future<bool> requestPrecisePermission() async {
    return await _channel.invokeMethod<bool>('requestPrecisePermission') ??
        false;
  }
}
