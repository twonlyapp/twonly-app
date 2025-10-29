import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/better_text.dart';

class ChatTextEntry extends StatelessWidget {
  const ChatTextEntry({
    required this.message,
    required this.nextMessage,
    required this.borderRadius,
    required this.minWidth,
    super.key,
  });

  final Message message;
  final Message? nextMessage;
  final BorderRadius borderRadius;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    var text = message.content ?? '';
    var textColor = Colors.white;

    if (EmojiAnimation.supported(text)) {
      return Container(
        constraints: const BoxConstraints(
          maxWidth: 100,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 10,
        ),
        child: EmojiAnimation(emoji: text),
      );
    }

    var displayTime = !combineTextMessageWithNext(message, nextMessage);

    var spacerWidth = minWidth - measureTextWidth(text) - 53;
    if (spacerWidth < 0) spacerWidth = 0;

    Color? color;
    var expanded = false;
    if (message.quotesMessageId == null) {
      color = getMessageColor(message);
    }
    if (message.isDeletedFromSender) {
      color = context.color.surfaceBright;
      displayTime = false;
    } else if (measureTextWidth(text) > 270) {
      expanded = true;
    }

    if (message.isDeletedFromSender) {
      text = context.lang.messageWasDeleted;
      color = isDarkMode(context) ? Colors.black : Colors.grey;
      if (isDarkMode(context)) {
        textColor = const Color.fromARGB(255, 99, 99, 99);
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
        minWidth: minWidth,
      ),
      padding: const EdgeInsets.only(left: 10, top: 6, bottom: 6, right: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (expanded)
            Expanded(
              child: BetterText(text: text, textColor: textColor),
            )
          else ...[
            BetterText(text: text, textColor: textColor),
            SizedBox(
              width: spacerWidth,
            ),
          ],
          if (displayTime)
            Align(
              alignment: AlignmentGeometry.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Row(
                  children: [
                    if (message.modifiedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: SizedBox(
                          height: 10,
                          child: FaIcon(
                            FontAwesomeIcons.pencil,
                            color: Colors.white.withAlpha(150),
                            size: 10,
                          ),
                        ),
                      ),
                    Text(
                      friendlyTime(context, message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withAlpha(150),
                        decoration: TextDecoration.none,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
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

String friendlyTime(BuildContext context, DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes >= 0 && diff.inMinutes < 60) {
    final minutes = diff.inMinutes == 0 ? 1 : diff.inMinutes;
    if (minutes <= 1) {
      return context.lang.now;
    }
    return '$minutes ${context.lang.minutesShort}';
  }

  // Determine 24h vs 12h from system/local settings
  final use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;

  if (!use24Hour) {
    // 12-hour format with locale-aware AM/PM
    final format = DateFormat.jm(Localizations.localeOf(context).toString());
    return format.format(dt);
  } else {
    // 24-hour HH:mm, locale-aware
    final format = DateFormat.Hm(Localizations.localeOf(context).toString());
    return format.format(dt);
  }
}
