import 'dart:async';
import 'dart:collection';

import 'package:mutex/mutex.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/error_reporting.service.dart';
import 'package:twonly/src/utils/log.dart';

class UserService {
  late UserConfig currentUser;
  bool isUserCreated = false;
  static final Mutex _updateProtection = Mutex();
  final _pendingUpdates = Queue<_UserUpdate>();

  final _userDataUpdateController = StreamController<void>.broadcast();
  Stream<void> get onUserUpdated => _userDataUpdateController.stream;

  Future<bool> tryInit() async {
    final config = await UserConfigApi.load();
    if (config == null) return false;
    await _applyRustUserConfig(config, notify: false);
    return isUserCreated;
  }

  static Future<void> update(
    void Function(UserConfig userData) updateUser,
  ) async {
    await _updateProtection.protect(() async {
      userService._pendingUpdates.add(_UserUpdate(updateUser));
      await userService._flushPendingUpdates();
    });
  }

  /// Replay changes after native resume has reopened the foreground session.
  static Future<void> retryPendingUpdates() => _updateProtection.protect(
    () => userService._flushPendingUpdates(),
  );

  Future<void> _flushPendingUpdates() async {
    while (_pendingUpdates.isNotEmpty) {
      final pending = _pendingUpdates.first;
      try {
        if (pending.prepared == null) {
          final config = await UserConfigApi.load();

          if (config == null) {
            throw Exception('User Config is missing');
          }

          final user = UserConfigApi.clone(config: config);
          if (user.defaultShowTime == 999999) {
            // This was the old version for infinity -> change it to null
            user.defaultShowTime = null;
          }
          pending.mutate(user);
          // Retain the patch, rather than calling a toggle/increment twice if
          // Rust persisted it just before the foreground call was cancelled.
          pending.prepared = (base: config, updated: user);
        }

        final (base: config, updated: user) = pending.prepared!;

        if (config == user) {
          // Another runtime may already have saved the requested value. Keep
          // this isolate and its listeners in sync even when no write is needed.
          await _applyRustUserConfig(config);
        } else {
          final normalized = await UserConfigApi.update(
            base: config,
            config: user,
          );
          await _applyRustUserConfig(normalized);
        }
      } catch (e) {
        if (isBackgroundCancellation(e)) {
          Log.info('User update deferred until the app resumes');
          return;
        }
        Log.error('Could not update the user: $e');
      }
      _pendingUpdates.removeFirst();
    }
  }

  static Future<void> save(UserConfig user) async {
    final normalized = await UserConfigApi.save(config: user);
    await userService._applyRustUserConfig(normalized);
  }

  static Future<void> handleRustUserConfigChanged(UserConfig config) async {
    try {
      await userService._applyRustUserConfig(config);
    } catch (e) {
      Log.warn(e);
    }
  }

  Future<void> _applyRustUserConfig(
    UserConfig config, {
    bool notify = true,
  }) async {
    final changed =
        !isUserCreated ||
        !UserConfigApi.sameConfig(left: currentUser, right: config);
    currentUser = config;
    isUserCreated = true;
    try {
      await ErrorReportingService.setEnabled(
        config.allowErrorTrackingViaSentry,
      );
    } catch (e) {
      // Reporting must not prevent login or updating the user's settings.
      Log.warn('Could not configure error reporting', e);
    }
    if (notify && changed) triggerUserUpdate();
  }

  void triggerUserUpdate() {
    _userDataUpdateController.add(null);
  }
}

class _UserUpdate {
  _UserUpdate(this.mutate);

  final void Function(UserConfig) mutate;
  ({UserConfig base, UserConfig updated})? prepared;
}
