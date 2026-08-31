import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';

class BubbleInfo {
  late String text;
  late Color textColor;
  late bool displayTime;
  late String displayUserName;
  late Color color;
  late bool expanded;
  late double spacerWidth;
  late EdgeInsets padding;
  late double minWidth;
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
    ..color = getMessageColor(message.senderId != null)
    ..displayTime = !combineTextMessageWithNext(message, nextMessage)
    ..displayUserName = ''
    ..minWidth = minWidth
    ..padding = message.type == MessageType.media.name
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 2)
        : const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 10);

  if (message.senderId != null &&
      userIdToContact != null &&
      userIdToContact[message.senderId] != null) {
    if (prevMessage == null) {
      info.displayUserName = getContactDisplayName(
        userIdToContact[message.senderId]!,
      );
    } else {
      if (!combineTextMessageWithNext(prevMessage, message)) {
        info.displayUserName = getContactDisplayName(
          userIdToContact[message.senderId]!,
        );
      }
    }
  }

  final textWidth = measureTextWidth(info.text);
  info.spacerWidth = minWidth - textWidth - 53;
  if (info.spacerWidth < 0) info.spacerWidth = 0;

  info
    ..expanded = false
    ..color = message.quotesMessageId != null
        ? Colors.transparent
        : getMessageColor(message.senderId != null);
  if (message.isDeletedFromSender) {
    info
      ..color = context.color.surfaceBright
      ..displayTime = false;
  } else if (textWidth > 270) {
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

/// Laying text out is expensive and `getBubbleInfo` runs for every visible
/// bubble on every rebuild, while the same message content is measured over and
/// over. Keep the last few hundred results around, in insertion order, so the
/// cache stays bounded as the user scrolls through a long conversation.
const _measuredTextCacheLimit = 500;
final Map<String, double> _measuredTextCache = <String, double>{};

double measureTextWidth(
  String text,
) {
  final cached = _measuredTextCache[text];
  if (cached != null) return cached;

  final tp = TextPainter(
    text: TextSpan(text: text, style: const TextStyle(fontSize: 17)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final width = tp.size.width;
  tp.dispose();

  if (_measuredTextCache.length >= _measuredTextCacheLimit) {
    _measuredTextCache.remove(_measuredTextCache.keys.first);
  }
  _measuredTextCache[text] = width;
  return width;
}

bool combineTextMessageWithNext(Message message, Message? nextMessage) {
  if (nextMessage != null) {
    if (nextMessage.senderId == message.senderId) {
      if (nextMessage.content == null ||
          !EmojiAnimationComp.supported(nextMessage.content!)) {
        final diff = nextMessage.createdAt
            .difference(message.createdAt)
            .inMinutes;
        if (diff <= 1) {
          return true;
        }
      }
    }
  }
  return false;
}
