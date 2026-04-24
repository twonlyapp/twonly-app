import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mutex/mutex.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/secure_storage.keys.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/secure_storage.dart';

class UserService {
  late UserData currentUser;

  final _userDataUpdateController = StreamController<void>.broadcast();
  Stream<void> get onUserUpdated => _userDataUpdateController.stream;

  Future<bool> tryInit() async {
    final user = await getUser();
    if (user == null) return false;
    userService.currentUser = user;
    return true;
  }

  void triggerUserUpdate() {
    _userDataUpdateController.add(null);
  }

  void dispose() {
    _userDataUpdateController.close();
  }
}

Future<bool> isUserCreated() async {
  final user = await getUser();
  if (user == null) {
    return false;
  }
  userService.currentUser = user;
  return true;
}

Future<UserData?> getUser() async {
  try {
    final userDataJson = await SecureStorage.instance.read(
      key: SecureStorageKeys.userData,
    );
    if (userDataJson == null) {
      return null;
    }
    return UserData.fromJson(jsonDecode(userDataJson) as Map<String, dynamic>);
  } catch (e) {
    Log.error('could not load user: $e');
    rethrow; // Rethrow instead of returning null to distinguish error from missing user
  }
}

Future<void> updateUsersPlan(
  BuildContext context,
  SubscriptionPlan plan,
) async {
  context.read<PurchasesProvider>().plan = plan;

  await updateUser((user) {
    user.subscriptionPlan = plan.name;
  });

  if (!context.mounted) return;
  context.read<PurchasesProvider>().updatePlan(plan);
}

Mutex updateProtection = Mutex();

Future<void> updateUser(
  void Function(UserData userData) updateUser,
) async {
  await updateProtection.protect(() async {
    final user = await getUser();
    if (user == null) return;
    if (user.defaultShowTime == 999999) {
      // This was the old version for infinity -> change it to null
      user.defaultShowTime = null;
    }
    updateUser(user);
    await const FlutterSecureStorage().write(
      key: SecureStorageKeys.userData,
      value: jsonEncode(user),
    );
    userService.currentUser = user;
  });

  userService.triggerUserUpdate();
}
