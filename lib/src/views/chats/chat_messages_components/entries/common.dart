import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/animate_icon.dart';

class BubbleInfo {
  late String text;
  late Color textColor;
  late bool displayTime;
  late String displayUserName;
  late Color color;
  late bool expanded;
  late double spacerWidth;
}

BubbleInfo getBubbleInfo(
  BuildContext context,
  Message message,
  Message? nextMessage,
  Message? prevMessage,
  Map<int, Contact>? userIdToContact,
  double minWidth,
) {
  final info = BubbleInfo()
    ..text = message.content ?? ''
    ..textColor = Colors.white
    ..color = getMessageColor(message)
    ..displayTime = !combineTextMessageWithNext(message, nextMessage)
    ..displayUserName = '';

  if (message.senderId != null &&
      userIdToContact != null &&
      userIdToContact[message.senderId] != null) {
    if (prevMessage == null) {
      info.displayUserName =
          getContactDisplayName(userIdToContact[message.senderId]!);
    } else {
      if (!combineTextMessageWithNext(prevMessage, message)) {
        info.displayUserName =
            getContactDisplayName(userIdToContact[message.senderId]!);
      }
    }
  }

  info.spacerWidth = minWidth - measureTextWidth(info.text) - 53;
  if (info.spacerWidth < 0) info.spacerWidth = 0;

  info.expanded = false;
  if (message.quotesMessageId == null) {
    info.color = getMessageColor(message);
  }
  if (message.isDeletedFromSender) {
    info
      ..color = context.color.surfaceBright
      ..displayTime = false;
  } else if (measureTextWidth(info.text) > 270) {
    info.expanded = true;
  }

  if (message.isDeletedFromSender) {
    info
      ..text = context.lang.messageWasDeleted
      ..color = isDarkMode(context) ? Colors.black : Colors.grey;
    if (isDarkMode(context)) {
      info.textColor = const Color.fromARGB(255, 99, 99, 99);
    }
  }
  return info;
}

double measureTextWidth(
  String text,
) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: const TextStyle(fontSize: 17)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  return tp.size.width;
}

bool combineTextMessageWithNext(Message message, Message? nextMessage) {
  if (nextMessage != null && nextMessage.content != null) {
    if (nextMessage.senderId == message.senderId) {
      if (nextMessage.type == MessageType.text &&
          message.type == MessageType.text) {
        if (!EmojiAnimation.supported(nextMessage.content!)) {
          final diff =
              nextMessage.createdAt.difference(message.createdAt).inMinutes;
          if (diff <= 1) {
            return true;
          }
        }
      }
    }
  }
  return false;
}
