import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:twonly/main.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/signal/signal_helper.dart';
import 'package:twonly/src/providers/api_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    Logger("get_user").info("Found user: $userMap");
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

Uint8List getRandomUint8List(int length) {
  final Random random = Random.secure();
  final Uint8List randomBytes = Uint8List(length);

  for (int i = 0; i < length; i++) {
    randomBytes[i] = random.nextInt(256); // Generate a random byte (0-255)
  }

  return randomBytes;
}

int userIdToRegistrationId(Uint8List userId) {
  int result = 0;
  for (int i = 8; i < 16; i++) {
    result = (result << 8) | userId[i];
  }
  return result;
}

String uint8ListToHex(Uint8List list) {
  final StringBuffer hexBuffer = StringBuffer();
  for (int byte in list) {
    hexBuffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return hexBuffer.toString().toUpperCase();
}

Future<bool> addNewUser(String username) async {
  final res = await apiProvider.getUserData(username);

  if (res.isSuccess) {
    print(res.value);
    print(res.value.userdata.userId);

    if (await SignalHelper.addNewContact(res.value.userdata)) {
      await dbProvider.db!.insert(DbContacts.tableName, {
        DbContacts.columnDisplayName: username,
        DbContacts.columnUserId: res.value.userdata.userId
      });
    }
    print("Add new user: ${res}");
  }

  return res.isSuccess;
}

Future<Result> createNewUser(String username, String inviteCode) async {
  final storage = getSecureStorage();

  await SignalHelper.createIfNotExistsSignalIdentity();

  final res = await apiProvider.register(username, inviteCode);

  if (res.isSuccess) {
    Logger("create_new_user").info("Got user_id ${res.value} from server");
    final userData = UserData(
        userId: res.value.userid, username: username, displayName: username);
    storage.write(key: "user_data", value: jsonEncode(userData));
  }

  return res;
}
