import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/utils/log.dart';

Future<bool> isUserCreated() async {
  UserData? user = await getUser();
  if (user == null) {
    return false;
  }
  return true;
}

Future<UserData?> getUser() async {
  final storage = FlutterSecureStorage();
  String? userJson = await storage.read(key: "userData");
  if (userJson == null) {
    return null;
  }
  try {
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    final user = UserData.fromJson(userMap);
    return user;
  } catch (e) {
    Log.error("Error getting user: $e");
    return null;
  }
}

Future updateUsersPlan(BuildContext context, String planId) async {
  context.read<CustomChangeProvider>().plan = planId;

  await updateUserdata((user) {
    user.subscriptionPlan = planId;
    return user;
  });

  if (!context.mounted) return;
  context.read<CustomChangeProvider>().updatePlan(planId);
}

Mutex updateProtection = Mutex();

Future<UserData?> updateUserdata(Function(UserData userData) updateUser) async {
  return await updateProtection.protect<UserData?>(() async {
    final user = await getUser();
    if (user == null) return null;
    UserData updated = updateUser(user);
    final storage = FlutterSecureStorage();
    storage.write(key: "userData", value: jsonEncode(updated));
    return user;
  });
}

Future<bool> deleteLocalUserData() async {
  final appDir = await getApplicationSupportDirectory();
  if (appDir.existsSync()) {
    appDir.deleteSync(recursive: true);
  }
  final storage = FlutterSecureStorage();
  await storage.deleteAll();
  return true;
}
