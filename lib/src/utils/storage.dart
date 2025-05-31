import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/model/json/userdata.dart';
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

Future updateUser(UserData userData) async {
  final storage = FlutterSecureStorage();
  storage.write(key: "userData", value: jsonEncode(userData));
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
