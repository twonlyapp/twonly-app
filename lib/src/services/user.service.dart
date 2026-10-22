import 'dart:async';

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
      try {
        final config = await UserConfigApi.load();

        if (config == null) {
          throw Exception('User Config is missing');
        }

        final user = UserConfigApi.clone(config: config);
        if (user.defaultShowTime == 999999) {
          // This was the old version for infinity -> change it to null
          user.defaultShowTime = null;
        }
        updateUser(user);

        if (config == user) {
          return;
        }

        final normalized = await UserConfigApi.update(
          base: config,
          config: user,
        );
        await userService._applyRustUserConfig(normalized);
      } catch (e) {
        Log.error('Could not update the user: $e');
      }
    });
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
    if (notify) triggerUserUpdate();
  }

  void triggerUserUpdate() {
    _userDataUpdateController.add(null);
  }
}
