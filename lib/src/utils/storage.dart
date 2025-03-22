import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twonly/src/json_models/userdata.dart';
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
  String? userJson = await storage.read(key: "userData");
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

Future updateUser(UserData userData) async {
  final storage = getSecureStorage();
  storage.write(key: "userData", value: jsonEncode(userData));
}

Future<bool> deleteLocalUserData() async {
  final appDir = await getApplicationSupportDirectory();
  if (appDir.existsSync()) {
    appDir.deleteSync(recursive: true);
  }
  final storage = getSecureStorage();
  await storage.deleteAll();
  return true;
}
