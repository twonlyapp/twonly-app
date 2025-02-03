import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:twonly/src/proto/api/error.pb.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get lang => AppLocalizations.of(this)!;
}

Future<void> writeLogToFile(LogRecord record) async {
  final directory = await getApplicationDocumentsDirectory();
  final logFile = File('${directory.path}/app.log');

  // Prepare the log message
  final logMessage =
      '${record.level.name}: ${record.loggerName}: ${record.message}\n';

  // Append the log message to the file
  await logFile.writeAsString(logMessage, mode: FileMode.append);
}

// Just a helper function to get the secure storage
FlutterSecureStorage getSecureStorage() {
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
        encryptedSharedPreferences: true,
      );
  return FlutterSecureStorage(aOptions: _getAndroidOptions());
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
