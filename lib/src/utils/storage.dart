import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/secure_storage_keys.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/utils/log.dart';

Future<bool> isUserCreated() async {
  final user = await getUser();
  if (user == null) {
    return false;
  }
  gUser = user;
  return true;
}

Future<UserData?> getUser() async {
  final userJson =
      await const FlutterSecureStorage().read(key: SecureStorageKeys.userData);
  if (userJson == null) {
    return null;
  }
  try {
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    final user = UserData.fromJson(userMap);
    return user;
  } catch (e) {
    Log.error('Error getting user: $e');
    return null;
  }
}

Future<void> updateUsersPlan(BuildContext context, String planId) async {
  context.read<CustomChangeProvider>().plan = planId;

  await updateUserdata((user) {
    user.subscriptionPlan = planId;
    return user;
  });

  if (!context.mounted) return;
  await context.read<CustomChangeProvider>().updatePlan(planId);
}

Mutex updateProtection = Mutex();

Future<UserData?> updateUserdata(
  UserData Function(UserData userData) updateUser,
) async {
  return updateProtection.protect<UserData?>(() async {
    final user = await getUser();
    if (user == null) return null;
    final updated = updateUser(user);
    await const FlutterSecureStorage()
        .write(key: SecureStorageKeys.userData, value: jsonEncode(updated));
    gUser = updated;
    return updated;
  });
}

Future<bool> deleteLocalUserData() async {
  final appDir = await getApplicationSupportDirectory();
  if (appDir.existsSync()) {
    appDir.deleteSync(recursive: true);
  }
  await const FlutterSecureStorage().deleteAll();
  return true;
}
