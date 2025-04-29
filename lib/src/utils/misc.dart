import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/protobuf/api/error.pb.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/settings_change_provider.dart';

extension ShortCutsExtension on BuildContext {
  AppLocalizations get lang => AppLocalizations.of(this)!;
  TwonlyDatabase get db => Provider.of<TwonlyDatabase>(this);
  ColorScheme get color => Theme.of(this).colorScheme;
}

Future<void> writeLogToFile(LogRecord record) async {
  final directory = await getApplicationSupportDirectory();
  final logFile = File('${directory.path}/app.log');

  // Prepare the log message
  final logMessage =
      '${DateTime.now()}: ${record.level.name}: ${record.loggerName}: ${record.message}\n';

  // Append the log message to the file
  await logFile.writeAsString(logMessage, mode: FileMode.append);
}

Future<bool> deleteLogFile() async {
  final directory = await getApplicationSupportDirectory();
  final logFile = File('${directory.path}/app.log');

  if (await logFile.exists()) {
    await logFile.delete();
    return true;
  }
  return false;
}

Future<String?> saveImageToGallery(Uint8List imageBytes) async {
  final hasAccess = await Gal.hasAccess();
  if (!hasAccess) {
    await Gal.requestAccess();
  }
  try {
    await Gal.putImageBytes(imageBytes);
    return null;
  } on GalException catch (e) {
    return e.type.message;
  }
}

Uint8List getRandomUint8List(int length) {
  final Random random = Random.secure();
  final Uint8List randomBytes = Uint8List(length);

  for (int i = 0; i < length; i++) {
    randomBytes[i] = random.nextInt(256); // Generate a random byte (0-255)
  }

  return randomBytes;
}

String errorCodeToText(BuildContext context, ErrorCode code) {
  switch (code.toString()) {
    case "Unknown":
      return context.lang.errorUnknown;
    case "BadRequest":
      return context.lang.errorBadRequest;
    case "TooManyRequests":
      return context.lang.errorTooManyRequests;
    case "InternalError":
      return context.lang.errorInternalError;
    case "InvalidInvitationCode":
      return context.lang.errorInvalidInvitationCode;
    case "UsernameAlreadyTaken":
      return context.lang.errorUsernameAlreadyTaken;
    case "SignatureNotValid":
      return context.lang.errorSignatureNotValid;
    case "UsernameNotFound":
      return context.lang.errorUsernameNotFound;
    case "UsernameNotValid":
      return context.lang.errorUsernameNotValid;
    case "InvalidPublicKey":
      return context.lang.errorInvalidPublicKey;
    case "SessionAlreadyAuthenticated":
      return context.lang.errorSessionAlreadyAuthenticated;
    case "SessionNotAuthenticated":
      return context.lang.errorSessionNotAuthenticated;
    case "OnlyOneSessionAllowed":
      return context.lang.errorOnlyOneSessionAllowed;
    default:
      return code.toString(); // Fallback for unrecognized keys
  }
}

String formatDuration(int seconds) {
  if (seconds < 60) {
    return '$seconds Sec.';
  } else if (seconds < 3600) {
    int minutes = seconds ~/ 60;
    return '$minutes Min.';
  } else if (seconds < 86400) {
    int hours = seconds ~/ 3600;
    return '$hours Hrs.'; // Assuming "Stu." is for hours
  } else {
    int days = seconds ~/ 86400;
    return '$days Days';
  }
}

InputDecoration getInputDecoration(context, hintText) {
  final primaryColor =
      Theme.of(context).colorScheme.primary; // Get the primary color
  return InputDecoration(
    hintText: hintText,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9.0),
      borderSide: BorderSide(color: primaryColor, width: 1.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.outline, width: 1.0),
    ),
    contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
  );
}

Future<Uint8List?> getCompressedImage(Uint8List imageBytes) async {
  var result = await FlutterImageCompress.compressWithList(
    imageBytes,
    quality: 90,
  );
  return result;
}

Future<bool> authenticateUser(String localizedReason,
    {bool force = true}) async {
  try {
    final LocalAuthentication auth = LocalAuthentication();
    bool didAuthenticate = await auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(useErrorDialogs: false));
    if (didAuthenticate) {
      return true;
    }
  } on PlatformException catch (e) {
    debugPrint(e.toString());
    if (!force) {
      return true;
    }
  }
  return false;
}

void setupLogger() {
  Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.onRecord.listen((record) async {
    await writeLogToFile(record);
    if (kDebugMode) {
      print(
          '${record.level.name}: twonly:${record.loggerName}: ${record.message}');
    }
  });
}

Uint8List intToBytes(int value) {
  final byteData = ByteData(4);
  byteData.setInt32(0, value, Endian.big);
  return byteData.buffer.asUint8List();
}

int bytesToInt(Uint8List bytes) {
  final byteData = ByteData.sublistView(bytes);
  return byteData.getInt32(0, Endian.big);
}

List<Uint8List>? removeLastXBytes(Uint8List original, int count) {
  if (original.length < count) {
    return null;
  }
  final newList = Uint8List(original.length - count);
  newList.setAll(0, original.sublist(0, original.length - count));

  final lastXBytes = original.sublist(original.length - count);
  return [newList, lastXBytes];
}

bool isDarkMode(BuildContext context) {
  ThemeMode? selectedTheme = context.read<SettingsChangeProvider>().themeMode;

  bool isDarkMode =
      MediaQuery.of(context).platformBrightness == Brightness.dark;

  return selectedTheme == ThemeMode.dark ||
      (selectedTheme == ThemeMode.system && isDarkMode);
}
