import 'package:flutter/material.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';

class DefaultColors {
  static const messageSelf = Color.fromARGB(255, 58, 136, 102);
  static const messageOther = Color.fromARGB(233, 68, 137, 255);
}

Color getMessageColorFromType(
  Message message,
  MediaFile? mediaFile,
  BuildContext context,
) {
  Color color;

  if (message.type == MessageType.restoreFlameCounter.name) {
    color = Colors.orange;
  } else if (message.type == MessageType.text.name) {
    color = Colors.blueAccent;
  } else if (mediaFile != null) {
    if (mediaFile.requiresAuthentication) {
      color = context.color.primary;
    } else {
      if (mediaFile.type == MediaType.video) {
        color = const Color.fromARGB(255, 243, 33, 208);
      } else if (mediaFile.type == MediaType.audio) {
        color = const Color.fromARGB(255, 252, 149, 85);
      } else {
        color = Colors.redAccent;
      }
    }
  } else {
    return (isDarkMode(context)) ? Colors.white : Colors.black;
  }
  return color;
}
