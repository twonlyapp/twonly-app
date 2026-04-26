import 'dart:async';
import 'dart:convert';

import 'package:mutex/mutex.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
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
      final userDataJson = await SecureStorage.instance.read(
        key: SecureStorageKeys.userData,
      );
      if (userDataJson == null) {
        return null;
      }
      return UserData.fromJson(
        jsonDecode(userDataJson) as Map<String, dynamic>,
      );
    } catch (e) {
      Log.error('could not load user: $e');
      rethrow; // Rethrow instead of returning null to distinguish error from missing user
    }
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
        await SecureStorage.instance.write(
          key: SecureStorageKeys.userData,
          value: jsonEncode(user),
        );
        userService.currentUser = user;
      } catch (e) {
        Log.error('Could not update the user: $e');
      }
    });

    userService.triggerUserUpdate();
  }

  void triggerUserUpdate() {
    _userDataUpdateController.add(null);
  }
}
