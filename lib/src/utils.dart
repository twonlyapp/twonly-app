import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:twonly/main.dart';
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
  await storage.delete(key: "user_data");
  await storage.delete(key: "signal_identity");
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

Future<Result> addNewUser(String username) async {
  final res = await apiProvider.getUserData(username);

  // if (res.isSuccess) {
  //   print("Got user_id ${res.value}");
  //   final userData = UserData(
  //       userId: res.value.userid, username: username, displayName: username);
  // }

  return res;
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

Widget createInitialsAvatar(String username, bool isDarkMode) {
  // Extract initials from the username
  List<String> nameParts = username.split(' ');
  String initials = nameParts.map((part) => part[0]).join().toUpperCase();
  if (initials.length > 2) {
    initials = initials[0] + initials[1];
  } else if (initials.length == 1) {
    initials = username[0] + username[1];
  }

  initials = initials.toUpperCase();

  // Generate a color based on the initials (you can customize this logic)
  Color avatarColor = _getColorFromUsername(username, isDarkMode);

  return CircleAvatar(
    backgroundColor: avatarColor,
    child: Text(
      initials,
      style: TextStyle(
          color: _getTextColor(avatarColor),
          fontWeight: FontWeight.normal,
          fontSize: 20),
    ),
  );
}

Color _getTextColor(Color color) {
  double value = 100.0;
  // Ensure the value does not exceed the RGB limits
  int newRed = ((color.r * 255) - value).clamp(0, 255).round();
  int newGreen = (color.g * 255 - value).clamp(0, 255).round();
  int newBlue = (color.b * 255 - value).clamp(0, 255).round();

  return Color.fromARGB((color.a * 255).round(), newRed, newGreen, newBlue);
}

Color _getColorFromUsername(String username, bool isDarkMode) {
  // Define color lists for light and dark themes
  List<Color> lightColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
    Colors.lime,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  List<Color> darkColors = [
    const Color.fromARGB(255, 246, 227, 254), // Light Lavender
    const Color.fromARGB(255, 246, 216, 215), // Light Pink
    const Color.fromARGB(255, 226, 236, 235), // Light Teal
    const Color.fromARGB(255, 255, 224, 178), // Light Yellow
    const Color.fromARGB(255, 255, 182, 193), // Light Pink (Hot Pink)
    const Color.fromARGB(255, 173, 216, 230), // Light Blue
    const Color.fromARGB(255, 221, 160, 221), // Plum
    const Color.fromARGB(255, 255, 228, 196), // Bisque
    const Color.fromARGB(255, 240, 230, 140), // Khaki
    const Color.fromARGB(255, 255, 192, 203), // Pink
    const Color.fromARGB(255, 255, 218, 185), // Peach Puff
    const Color.fromARGB(255, 255, 160, 122), // Light Salmon
    const Color.fromARGB(255, 135, 206, 250), // Light Sky Blue
    const Color.fromARGB(255, 255, 228, 225), // Misty Rose
    const Color.fromARGB(255, 240, 248, 255), // Alice Blue
    const Color.fromARGB(255, 255, 250, 205), // Lemon Chiffon
    const Color.fromARGB(255, 255, 218, 185), // Peach Puff
  ];

  // Simple logic to generate a hash from initials
  int hash = username.codeUnits.fold(0, (prev, element) => prev + element);

  // Select the appropriate color list based on the current theme brightness
  List<Color> colors = isDarkMode ? darkColors : lightColors;

  // Use the hash to select a color from the list
  return colors[hash % colors.length];
}
