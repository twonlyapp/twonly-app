import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/json/user_data.dart';
import 'package:twonly/src/utils/misc.dart';

Future<bool> isUserCreated() async {
  UserData? user = await getUser();
  if (user == null) {
    return false;
  }
  return true;
}

Future<UserData?> getUser() async {
  final storage = getSecureStorage();
  String? userJson = await storage.read(key: "user_data");
  if (userJson == null) {
    return null;
  }
  try {
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    final user = UserData.fromJson(userMap);
    return user;
  } catch (e) {
    Logger("get_user").shout("Error getting user: $e");
    return null;
  }
}

Future<bool> deleteLocalUserData() async {
  final storage = getSecureStorage();
  var password = await storage.read(key: "sqflite_database_password");
  await dbProvider.remove();
  await storage.write(key: "sqflite_database_password", value: password);
  await storage.deleteAll();
  return true;
}
