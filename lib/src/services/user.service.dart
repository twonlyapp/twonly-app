import 'dart:async';
import 'dart:convert';

import 'package:mutex/mutex.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/secure_storage.dart';

class UserService {
  late UserData currentUser;
  bool isUserCreated = false;
  static final Mutex _updateProtection = Mutex();

  final _userDataUpdateController = StreamController<void>.broadcast();
  Stream<void> get onUserUpdated => _userDataUpdateController.stream;

  Future<bool> tryInit() async {
    final user = await getUser();
    if (user == null) return false;
    userService.currentUser = user;
    userService.isUserCreated = true;
    return true;
  }

  static Future<UserData?> getUser() async {
    try {
      // 1. Try to load from KeyValueStore (user.json)
      final userDataMap = await KeyValueStore.get('user');
      if (userDataMap != null) {
        final userData = UserData.fromJson(userDataMap);
        await RustKeyManager.setUserId(userId: userData.userId);
        return userData;
      }

      // 2. If not found, try to load from SecureStorage (Migration path)
      final userDataJson = await SecureStorage.instance.read(
        key: SecureStorageKeys.userData,
      );

      if (userDataJson != null) {
        final userData = UserData.fromJson(
          jsonDecode(userDataJson) as Map<String, dynamic>,
        );

        // 3. Run migration
        await _migrateFromSecureStorage(userData);
        return userData;
      }

      return null;
    } catch (e) {
      Log.error('could not load user: $e');
      rethrow;
    }
  }

  static Future<void> _migrateFromSecureStorage(UserData userData) async {
    // Currently empty migration logic as requested, but we MUST store the data
    await KeyValueStore.put('user', userData.toJson());
    try {
      await RustKeyManager.setUserId(userId: userData.userId);
    } catch (e) {
      Log.error('Could not set userId in RustKeyManager during migration: $e');
    }

    // Optional: Log migration
    Log.info('Migrated user data from SecureStorage to KeyValueStore');
  }

  static Future<void> update(
    void Function(UserData userData) updateUser,
  ) async {
    await _updateProtection.protect(() async {
      try {
        final user = await getUser();
        if (user == null) return;
        if (user.defaultShowTime == 999999) {
          // This was the old version for infinity -> change it to null
          user.defaultShowTime = null;
        }
        updateUser(user);
        await KeyValueStore.put('user', user.toJson());
        userService.currentUser = user;
      } catch (e) {
        Log.error('Could not update the user: $e');
      }
    });

    userService.triggerUserUpdate();
  }

  static Future<void> save(UserData user) async {
    await KeyValueStore.put('user', user.toJson());
    try {
      await RustKeyManager.setUserId(userId: user.userId);
    } catch (e) {
      Log.error('Could not set userId in RustKeyManager during save: $e');
    }
    await userService.tryInit();
  }

  void triggerUserUpdate() {
    _userDataUpdateController.add(null);
  }
}
