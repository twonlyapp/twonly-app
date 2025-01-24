import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
