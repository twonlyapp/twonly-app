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

Future<String?> saveImageToGallery(path) async {
  final hasAccess = await Gal.hasAccess();
  if (!hasAccess) {
    await Gal.requestAccess();
  }
  try {
    await Gal.putImage(path);
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
      return AppLocalizations.of(context)!.errorUnknown;
    case "BadRequest":
      return AppLocalizations.of(context)!.errorBadRequest;
    case "TooManyRequests":
      return AppLocalizations.of(context)!.errorTooManyRequests;
    case "InternalError":
      return AppLocalizations.of(context)!.errorInternalError;
    case "InvalidInvitationCode":
      return AppLocalizations.of(context)!.errorInvalidInvitationCode;
    case "UsernameAlreadyTaken":
      return AppLocalizations.of(context)!.errorUsernameAlreadyTaken;
    case "SignatureNotValid":
      return AppLocalizations.of(context)!.errorSignatureNotValid;
    case "UsernameNotFound":
      return AppLocalizations.of(context)!.errorUsernameNotFound;
    case "UsernameNotValid":
      return AppLocalizations.of(context)!.errorUsernameNotValid;
    case "InvalidPublicKey":
      return AppLocalizations.of(context)!.errorInvalidPublicKey;
    case "SessionAlreadyAuthenticated":
      return AppLocalizations.of(context)!.errorSessionAlreadyAuthenticated;
    case "SessionNotAuthenticated":
      return AppLocalizations.of(context)!.errorSessionNotAuthenticated;
    case "OnlyOneSessionAllowed":
      return AppLocalizations.of(context)!.errorOnlyOneSessionAllowed;
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

Future<Uint8List?> getCompressedImage(File file) async {
  var result = await FlutterImageCompress.compressWithFile(
    file.absolute.path,
    quality: 90,
  );
  return result;
}
