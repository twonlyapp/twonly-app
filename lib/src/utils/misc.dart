import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/localization/generated/app_localizations.dart';
import 'package:twonly/src/providers/settings.provider.dart';

extension ShortCutsExtension on BuildContext {
  AppLocalizations get lang => AppLocalizations.of(this)!;
  TwonlyDatabase get db => Provider.of<TwonlyDatabase>(this);
  ColorScheme get color => Theme.of(this).colorScheme;
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
  final Random random = Random.secure();
  final Uint8List randomBytes = Uint8List(length);

  for (int i = 0; i < length; i++) {
    randomBytes[i] = random.nextInt(256); // Generate a random byte (0-255)
  }

  return randomBytes;
}

String errorCodeToText(BuildContext context, ErrorCode code) {
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

InputDecoration getInputDecoration(BuildContext context, String hintText) {
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

bool isToday(DateTime lastImageSend) {
  final now = DateTime.now();
  return lastImageSend.year == now.year &&
      lastImageSend.month == now.month &&
      lastImageSend.day == now.day;
}

InputDecoration inputTextMessageDeco(BuildContext context) {
  return InputDecoration(
    hintText: context.lang.chatListDetailInput,
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20.0),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20.0),
      borderSide: BorderSide(color: Colors.grey, width: 2.0),
    ),
  );
}

String truncateString(String input, {int maxLength = 20}) {
  if (input.length > maxLength) {
    return '${input.substring(0, maxLength)}...';
  }
  return input;
}

Future insertDemoContacts() async {
  List<String> commonUsernames = [
    'James',
    'Mary',
    'John',
    'Patricia',
    'Robert',
    'Jennifer',
    'Michael',
    'Linda',
    'William',
    'Elizabeth',
    'David',
    'Barbara',
    'Richard',
    'Susan',
    'Joseph',
    'Jessica',
    'Charles',
    'Sarah',
    'Thomas',
    'Karen',
  ];
  final List<Map<String, dynamic>> contactConfigs = [
    {'count': 3, 'requested': true},
    {'count': 4, 'requested': false, 'accepted': true},
    {'count': 1, 'accepted': true, 'blocked': true},
    {'count': 1, 'accepted': true, 'archived': true},
    {'count': 2, 'accepted': true, 'pinned': true},
    {'count': 1, 'requested': false},
  ];

  int counter = 0;

  for (var config in contactConfigs) {
    for (int i = 0; i < config['count']; i++) {
      if (counter >= commonUsernames.length) {
        break;
      }
      String username = commonUsernames[counter];
      int userId = Random().nextInt(1000000);
      await twonlyDB.contactsDao.insertContact(
        ContactsCompanion(
          username: Value(username),
          userId: Value(userId),
          requested: Value(config['requested'] ?? false),
          accepted: Value(config['accepted'] ?? false),
          blocked: Value(config['blocked'] ?? false),
          archived: Value(config['archived'] ?? false),
          pinned: Value(config['pinned'] ?? false),
        ),
      );
      if (config['accepted'] ?? false) {
        for (var i = 0; i < 20; i++) {
          int chatId = Random().nextInt(chatMessages.length);
          await twonlyDB.messagesDao.insertMessage(
            MessagesCompanion(
              contactId: Value(userId),
              kind: Value(MessageKind.textMessage),
              sendAt: Value(chatMessages[chatId][1]),
              acknowledgeByServer: Value(true),
              acknowledgeByUser: Value(true),
              messageOtherId:
                  Value(Random().nextBool() ? Random().nextInt(10000) : null),
              // responseToOtherMessageId: Value(content.responseToMessageId),
              // responseToMessageId: Value(content.responseToOtherMessageId),
              downloadState: Value(DownloadState.downloaded),
              contentJson: Value(
                jsonEncode(TextMessageContent(text: chatMessages[chatId][0])),
              ),
            ),
          );
        }
      }
      counter++;
    }
  }
}

Future createFakeDemoData() async {
  await insertDemoContacts();
}

List<List<dynamic>> chatMessages = [
  [
    "Lorem ipsum dolor sit amet.",
    DateTime.now().subtract(Duration(minutes: 20))
  ],
  [
    "Consectetur adipiscing elit.",
    DateTime.now().subtract(Duration(minutes: 19))
  ],
  [
    "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
    DateTime.now().subtract(Duration(minutes: 18))
  ],
  ["Ut enim ad minim veniam.", DateTime.now().subtract(Duration(minutes: 17))],
  [
    "Quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.",
    DateTime.now().subtract(Duration(minutes: 16))
  ],
  [
    "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.",
    DateTime.now().subtract(Duration(minutes: 15))
  ],
  [
    "Excepteur sint occaecat cupidatat non proident.",
    DateTime.now().subtract(Duration(minutes: 14))
  ],
  [
    "Sunt in culpa qui officia deserunt mollit anim id est laborum.",
    DateTime.now().subtract(Duration(minutes: 13))
  ],
  [
    "Curabitur pretium tincidunt lacus.",
    DateTime.now().subtract(Duration(minutes: 12))
  ],
  ["Nulla facilisi.", DateTime.now().subtract(Duration(minutes: 11))],
  [
    "Aenean lacinia bibendum nulla sed consectetur.",
    DateTime.now().subtract(Duration(minutes: 10))
  ],
  [
    "Sed posuere consectetur est at lobortis.",
    DateTime.now().subtract(Duration(minutes: 9))
  ],
  [
    "Vestibulum id ligula porta felis euismod semper.",
    DateTime.now().subtract(Duration(minutes: 8))
  ],
  [
    "Cras justo odio, dapibus ac facilisis in, egestas eget quam.",
    DateTime.now().subtract(Duration(minutes: 7))
  ],
  [
    "Morbi leo risus, porta ac consectetur ac, vestibulum at eros.",
    DateTime.now().subtract(Duration(minutes: 6))
  ],
  [
    "Praesent commodo cursus magna, vel scelerisque nisl consectetur et.",
    DateTime.now().subtract(Duration(minutes: 5))
  ],
  [
    "Donec ullamcorper nulla non metus auctor fringilla.",
    DateTime.now().subtract(Duration(minutes: 4))
  ],
  [
    "Etiam porta sem malesuada magna mollis euismod.",
    DateTime.now().subtract(Duration(minutes: 3))
  ],
  [
    "Aenean lacinia bibendum nulla sed consectetur.",
    DateTime.now().subtract(Duration(minutes: 2))
  ],
  [
    "Nullam quis risus eget urna mollis ornare vel eu leo.",
    DateTime.now().subtract(Duration(minutes: 1))
  ],
  ["Curabitur blandit tempus porttitor.", DateTime.now()],
];

String formatDateTime(BuildContext context, DateTime? dateTime) {
  if (dateTime == null) {
    return "Never";
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
    return "$time $date";
  }
}

String formatBytes(int bytes, {int decimalPlaces = 2}) {
  if (bytes <= 0) return "0 Bytes";
  const List<String> units = ["Bytes", "KB", "MB", "GB", "TB"];
  final int unitIndex = (log(bytes) / log(1000)).floor();
  final double formattedSize = bytes / pow(1000, unitIndex);
  return "${formattedSize.toStringAsFixed(decimalPlaces)} ${units[unitIndex]}";
}
