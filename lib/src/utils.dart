import 'dart:convert';
import 'package:connect/main.dart';
import 'package:connect/src/signal/signal_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'model/user.dart';

// Just a helper function to get the secure storage
FlutterSecureStorage getSecureStorage() {
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  return FlutterSecureStorage(aOptions: _getAndroidOptions());
}

Future<bool> isUserCreated() async {
  User? user = await getUser();
  if (user == null) {
    return false;
  }
  return true;
}

Future<User?> getUser() async {
  final storage = getSecureStorage();
  String? userJson = await storage.read(key: "user");
  if (userJson == null) {
    return null;
  }
  try {
// Decode the JSON string
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    final user = User.fromJson(userMap);
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

  // TODO: API call to server to check username and inviteCode
  final check = await apiProvider.handshakeCheckRegister(username, inviteCode);
  if (check != null) {
    return check;
  }

  final signalModel = await SignalHelper.createNewSignalIdentity(username);

  final identityKeyPair = await signalModel.signalStore.getIdentityKeyPair();

  final user = User(
      username: username,
      identityKeyPairU8List: identityKeyPair.serialize(),
      registrationId: await signalModel.signalStore.getLocalRegistrationId());

  // TODO: API call to register user

  await storage.write(key: "user", value: jsonEncode(user));

  return null;
}
