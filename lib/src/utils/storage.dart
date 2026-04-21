import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';

Future<bool> isUserCreated() async {
  final user = await getUser();
  if (user == null) {
    return false;
  }
  AppSession.currentUser = user;
  return true;
}

Future<UserData?> getUser() async {
  try {
    final userJson = await const FlutterSecureStorage().read(
      key: SecureStorageKeys.userData,
    );
    if (userJson == null) {
      return null;
    }
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    final user = UserData.fromJson(userMap);
    return user;
  } catch (e) {
    Log.error('Error getting user: $e');
    return null;
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
    AppSession.currentUser = user;
  });

  AppSession.triggerUserUpdate();
}

Future<bool> deleteLocalUserData() async {
  final appDir = await getApplicationSupportDirectory();
  if (appDir.existsSync()) {
    appDir.deleteSync(recursive: true);
  }
  await const FlutterSecureStorage().deleteAll();
  return true;
}
