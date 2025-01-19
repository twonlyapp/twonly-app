import 'dart:convert';
import 'package:twonly/main.dart';
import 'package:twonly/src/signal/signal_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'model/signal_identity_json.dart';
import 'model/user_data_json.dart';

// Just a helper function to get the secure storage
FlutterSecureStorage getSecureStorage() {
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  return FlutterSecureStorage(aOptions: _getAndroidOptions());
}

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
  } catch (_) {
    return null;
  }
}

Future<bool> deleteLocalUserData() async {
  final storage = getSecureStorage();
  await storage.delete(key: "user");
  return true;
}

Future<String?> createNewUser(String username, String inviteCode) async {
  final storage = getSecureStorage();

  await SignalHelper.createIfNotExistsSignalIdentity();

  // TODO: API call to server to check username and inviteCode
  final check = await apiProvider.register(username, inviteCode);
  if (check != null) {
    return check;
  }

  print(check);

  // await storage.write(key: "user_data", value: jsonEncode(userData));

  return null;
}
