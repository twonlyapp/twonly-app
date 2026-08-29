import 'dart:async';

import 'package:mutex/mutex.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/secure_storage.dart';

class UserService {
  late UserConfig currentUser;
  bool isUserCreated = false;
  static final Mutex _updateProtection = Mutex();

  final _userDataUpdateController = StreamController<void>.broadcast();
  Stream<void> get onUserUpdated => _userDataUpdateController.stream;

  Future<bool> tryInit() async {
    final config = await UserConfigApi.load();
    if (config == null) return false;
    _applyRustUserConfig(config, notify: false);
    return isUserCreated;
  }

  static Future<UserConfig?> getUser() async {
    try {
      final config = await UserConfigApi.load();
      if (config != null) return config;

      // One-time migration from the pre-user.json secure-storage format.
      final userDataJson = await SecureStorage.instance.read(
        key: 'userData',
      );

      if (userDataJson != null) {
        final migrated = await UserConfigApi.importJson(json: userDataJson);
        await _removeLegacySecureStorageUser();
        return migrated;
      }

      return null;
    } catch (e) {
      Log.error('could not load user: $e');
      rethrow;
    }
  }

  static Future<void> _removeLegacySecureStorageUser() async {
    try {
      await SecureStorage.instance.delete(key: 'userData');
    } catch (e) {
      Log.error('Could not delete user data from SecureStorage: $e');
    }

    Log.info('Migrated user data from SecureStorage to KeyValueStore');
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
        userService._applyRustUserConfig(normalized);
      } catch (e) {
        Log.error('Could not update the user: $e');
      }
    });
  }

  static Future<void> save(UserConfig user) async {
    final normalized = await UserConfigApi.save(config: user);
    userService._applyRustUserConfig(normalized);
  }

  static Future<void> handleRustUserConfigChanged(UserConfig config) async {
    try {
      userService._applyRustUserConfig(config);
    } catch (e) {
      Log.warn(e);
    }
  }

  void _applyRustUserConfig(UserConfig config, {bool notify = true}) {
    currentUser = config;
    isUserCreated = true;
    if (notify) triggerUserUpdate();
  }

  void triggerUserUpdate() {
    _userDataUpdateController.add(null);
  }
}
