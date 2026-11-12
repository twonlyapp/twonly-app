import 'package:flutter/material.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/animate_icon.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages.view.dart';

class BubbleInfo {
  late String text;
  late Color textColor;
  late bool displayTime;
  late String displayUserName;
  late Color color;
  late EdgeInsets padding;
  late double minWidth;
}

BubbleInfo getBubbleInfo(
  BuildContext context,
  StoredMessage message,
  StoredMessage? nextMessage,
  StoredMessage? prevMessage,
  Map<int, Contact>? userIdToContact,
  double minWidth,
) {
  final info = BubbleInfo()
    ..text = message.content ?? ''
    ..textColor = message.senderId != null
        ? context.appColor(AppColor.onChatBubbleReceived)
        : context.appColor(AppColor.onChatBubbleSent)
    ..color = getMessageColor(context, message.senderId != null)
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

  info.color = message.quotesMessageId != null
      ? Colors.transparent
      : getMessageColor(context, message.senderId != null);
  if (message.isDeletedFromSender) {
    info
      ..color = context.color.surfaceBright
      ..displayTime = false;
  }

  if (message.isDeletedFromSender) {
    info
      ..text = context.lang.messageWasDeleted
      ..color = context.appColor(AppColor.chatBubbleDeleted)
      ..textColor = context.appColor(AppColor.onChatBubbleDeleted);
  }
  return info;
}

/// The languages the reader prefers, most preferred first, for the parts of a
/// message that arrive translated -- a webxdc app's name, say. What the reader
/// asked for is decided from the resolved locale and never sent anywhere: every
/// translation is already on the device.
List<String> readerLanguages(BuildContext context) => [
  Localizations.localeOf(context).toLanguageTag(),
];

bool combineTextMessageWithNext(
  StoredMessage message,
  StoredMessage? nextMessage,
) {
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
