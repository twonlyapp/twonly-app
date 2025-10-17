import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/utils/log.dart';

extension ShortCutsExtension on BuildContext {
  AppLocalizations get lang => AppLocalizations.of(this)!;
  TwonlyDatabase get db => Provider.of<TwonlyDatabase>(this);
  ColorScheme get color => Theme.of(this).colorScheme;
}

Future<String?> saveImageToGallery(Uint8List imageBytes) async {
  final jpgImages = await FlutterImageCompress.compressWithList(
    // ignore: avoid_redundant_argument_values
    format: CompressFormat.jpeg,
    imageBytes,
    quality: 100,
  );
  final hasAccess = await Gal.hasAccess();
  if (!hasAccess) {
    await Gal.requestAccess();
  }
  try {
    await Gal.putImageBytes(jpgImages);
    return null;
  } on GalException catch (e) {
    return e.type.message;
  }
}

Future<String?> saveVideoToGallery(String videoPath) async {
  final hasAccess = await Gal.hasAccess();
  if (!hasAccess) {
    await Gal.requestAccess();
  }
  try {
    await Gal.putVideo(videoPath);
    return null;
  } on GalException catch (e) {
    return e.type.message;
  }
}

Uint8List getRandomUint8List(int length) {
  final random = Random.secure();
  final randomBytes = Uint8List(length);

  for (var i = 0; i < length; i++) {
    randomBytes[i] = random.nextInt(256); // Generate a random byte (0-255)
  }

  return randomBytes;
}

String errorCodeToText(BuildContext context, ErrorCode code) {
  // ignore: exhaustive_cases
  switch (code) {
    case ErrorCode.InternalError:
      return context.lang.errorInternalError;
    case ErrorCode.InvalidInvitationCode:
      return context.lang.errorInvalidInvitationCode;
    case ErrorCode.UsernameAlreadyTaken:
      return context.lang.errorUsernameAlreadyTaken;
    case ErrorCode.UsernameNotValid:
      return context.lang.errorUsernameNotValid;
    case ErrorCode.NotEnoughCredit:
      return context.lang.errorNotEnoughCredit;
    case ErrorCode.PlanLimitReached:
      return context.lang.errorPlanLimitReached;
    case ErrorCode.PlanNotAllowed:
      return context.lang.errorPlanNotAllowed;
    case ErrorCode.VoucherInValid:
      return context.lang.errorVoucherInvalid;
    case ErrorCode.PlanUpgradeNotYearly:
      return context.lang.errorPlanUpgradeNotYearly;
  }
  return code.toString(); // Fallback for unrecognized keys
}

String formatDuration(int seconds) {
  if (seconds < 60) {
    return '$seconds Sec.';
  } else if (seconds < 3600) {
    final minutes = seconds ~/ 60;
    return '$minutes Min.';
  } else if (seconds < 86400) {
    final hours = seconds ~/ 3600;
    return '$hours Hrs.'; // Assuming "Stu." is for hours
  } else {
    final days = seconds ~/ 86400;
    return '$days Days';
  }
}

InputDecoration getInputDecoration(BuildContext context, String hintText) {
  final primaryColor =
      Theme.of(context).colorScheme.primary; // Get the primary color
  return InputDecoration(
    hintText: hintText,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: primaryColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
    ),
    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
  );
}

Future<Uint8List?> getCompressedImage(Uint8List imageBytes) async {
  final result = await FlutterImageCompress.compressWithList(
    imageBytes,
    quality: 90,
  );
  return result;
}

Future<bool> authenticateUser(
  String localizedReason, {
  bool force = true,
}) async {
  try {
    final auth = LocalAuthentication();
    final didAuthenticate = await auth.authenticate(
      localizedReason: localizedReason,
    );
    if (didAuthenticate) {
      return true;
    }
  } on LocalAuthException catch (e) {
    Log.error(e.toString());
    if (!force) {
      return true;
    }
  }
  return false;
}

Uint8List intToBytes(int value) {
  final byteData = ByteData(4)..setInt32(0, value);
  return byteData.buffer.asUint8List();
}

int bytesToInt(Uint8List bytes) {
  final byteData = ByteData.sublistView(bytes);
  return byteData.getInt32(0);
}

List<Uint8List>? removeLastXBytes(Uint8List original, int count) {
  if (original.length < count) {
    return null;
  }
  final newList = Uint8List(original.length - count)
    ..setAll(0, original.sublist(0, original.length - count));

  final lastXBytes = original.sublist(original.length - count);
  return [newList, lastXBytes];
}

bool isDarkMode(BuildContext context) {
  final selectedTheme = context.read<SettingsChangeProvider>().themeMode;

  final isDarkMode =
      MediaQuery.of(context).platformBrightness == Brightness.dark;

  return selectedTheme == ThemeMode.dark ||
      (selectedTheme == ThemeMode.system && isDarkMode);
}

bool isToday(DateTime lastImageSend) {
  final now = DateTime.now();
  return lastImageSend.year == now.year &&
      lastImageSend.month == now.month &&
      lastImageSend.day == now.day;
}

InputDecoration inputTextMessageDeco(BuildContext context) {
  return InputDecoration(
    hintText: context.lang.chatListDetailInput,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Colors.grey, width: 2),
    ),
  );
}

String truncateString(String input, {int maxLength = 20}) {
  if (input.length > maxLength) {
    return '${input.substring(0, maxLength)}...';
  }
  return input;
}

String formatDateTime(BuildContext context, DateTime? dateTime) {
  if (dateTime == null) {
    return 'Never';
  }
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  final date = DateFormat.yMd(Localizations.localeOf(context).toLanguageTag())
      .format(dateTime);

  final time = DateFormat.Hm(Localizations.localeOf(context).toLanguageTag())
      .format(dateTime);

  if (difference.inDays == 0) {
    return time;
  } else {
    return '$time $date';
  }
}

String formatBytes(int bytes, {int decimalPlaces = 2}) {
  if (bytes <= 0) return '0 Bytes';
  const units = <String>['Bytes', 'KB', 'MB', 'GB', 'TB'];
  final unitIndex = (log(bytes) / log(1000)).floor();
  final formattedSize = bytes / pow(1000, unitIndex);
  return '${formattedSize.toStringAsFixed(decimalPlaces)} ${units[unitIndex]}';
}

String getMessageText(Message message) {
  try {
    if (message.contentJson == null) return '';
    return TextMessageContent.fromJson(jsonDecode(message.contentJson!) as Map)
        .text;
  } catch (e) {
    Log.error(e);
    return '';
  }
}

MediaMessageContent? getMediaContent(Message message) {
  try {
    if (message.contentJson == null) return null;
    return MediaMessageContent.fromJson(
      jsonDecode(message.contentJson!) as Map,
    );
  } catch (e) {
    Log.error(e);
    return null;
  }
}
