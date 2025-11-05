import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/providers/settings.provider.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

extension ShortCutsExtension on BuildContext {
  AppLocalizations get lang => AppLocalizations.of(this)!;
  TwonlyDB get db => Provider.of<TwonlyDB>(this);
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

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();

String getRandomString(int length) => String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length)),
      ),
    );

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
  return code.toString();
}

String formatDuration(BuildContext context, int seconds) {
  if (seconds < 60) {
    return '$seconds ${context.lang.durationShortSecond}';
  } else if (seconds < 3600) {
    final minutes = seconds ~/ 60;
    return '$minutes ${context.lang.durationShortMinute}';
  } else if (seconds < 86400) {
    final hours = seconds ~/ 3600;
    return '$hours ${context.lang.durationShortHour}';
  } else {
    final days = seconds ~/ 86400;
    return context.lang.durationShortDays(days);
  }
}

InputDecoration getInputDecoration(BuildContext context, String hintText) {
  final primaryColor = Theme.of(context).colorScheme.primary;
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

bool isUUIDNewer(String uuid1, String uuid2) {
  try {
    final timestamp1 = int.parse(uuid1.substring(0, 8), radix: 16);
    final timestamp2 = int.parse(uuid2.substring(0, 8), radix: 16);
    return timestamp1 > timestamp2;
  } catch (e) {
    Log.error(e);
    return true;
  }
}

String uint8ListToHex(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

Uint8List hexToUint8List(String hex) => Uint8List.fromList(
      List<int>.generate(
        hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );

Color getMessageColorFromType(
  Message message,
  MediaFile? mediaFile,
  BuildContext context,
) {
  Color color;

  if (message.type == MessageType.text) {
    color = Colors.blueAccent;
  } else if (mediaFile != null) {
    if (mediaFile.requiresAuthentication) {
      color = context.color.primary;
    } else {
      if (mediaFile.type == MediaType.video) {
        color = const Color.fromARGB(255, 243, 33, 208);
      } else {
        color = Colors.redAccent;
      }
    }
  } else {
    return (isDarkMode(context)) ? Colors.white : Colors.black;
  }
  return color;
}

String getUUIDforDirectChat(int a, int b) {
  if (a < 0 || b < 0) {
    throw ArgumentError('Inputs must be non-negative integers.');
  }
  if (a > integerMax || b > integerMax) {
    throw ArgumentError('Inputs must be <= 0x7fffffff.');
  }

  // Mask to 64 bits in case inputs exceed 64 bits
  final mask64 = (BigInt.one << 64) - BigInt.one;
  final ai = BigInt.from(a) & mask64;
  final bi = BigInt.from(b) & mask64;

  // Ensure the bigger integer is in front (high 64 bits)
  final hi = ai >= bi ? ai : bi;
  final lo = ai >= bi ? bi : ai;

  final combined = (hi << 64) | lo;

  final hex = combined.toRadixString(16).padLeft(32, '0');

  final parts = [
    hex.substring(0, 8),
    hex.substring(8, 12),
    hex.substring(12, 16),
    hex.substring(16, 20),
    hex.substring(20, 32),
  ];
  return parts.join('-');
}

String friendlyDateTime(
  BuildContext context,
  DateTime dt, {
  bool includeSeconds = false,
  Locale? locale,
}) {
  // Build date part
  final datePart =
      DateFormat.yMd(Localizations.localeOf(context).toString()).format(dt);

  final use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;

  var timePart = '';
  if (use24Hour) {
    timePart =
        DateFormat.jm(Localizations.localeOf(context).toString()).format(dt);
  } else {
    timePart =
        DateFormat.Hm(Localizations.localeOf(context).toString()).format(dt);
  }

  return '$timePart $datePart';
}

String getAvatarSvg(Uint8List avatarSvgCompressed) {
  final raw = gzip.decode(avatarSvgCompressed);
  return utf8.decode(raw);
}
