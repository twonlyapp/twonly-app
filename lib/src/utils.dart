import 'dart:convert';
import 'package:twonly/main.dart';
import 'package:twonly/src/signal/signal_helper.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'model/user_data_json.dart';
import 'package:logging/logging.dart';

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
  await storage.delete(key: "user_data");
  await storage.delete(key: "signal_identity");
  return true;
}

Future<Result> createNewUser(String username, String inviteCode) async {
  final storage = getSecureStorage();

  await SignalHelper.createIfNotExistsSignalIdentity();

  // TODO: API call to server to check username and inviteCode
  final res = await apiProvider.register(username, inviteCode);

  if (res.isSuccess) {
    print("Got user_id ${res.value}");
    final userData = UserData(
        userId: res.value.userid, username: username, displayName: username);
    storage.write(key: "user_data", value: jsonEncode(userData));
  }

  return res;
}
