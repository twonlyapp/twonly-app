import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';

class FriendlyMessageTime extends StatelessWidget {
  const FriendlyMessageTime({
    required this.message,
    this.color,
    super.key,
  });

  final Message message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final statusIcon = _buildStatusIcon(Colors.grey.shade400);

    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.modifiedAt != null && !message.isDeletedFromSender)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: SizedBox(
                height: 10,
                child: FaIcon(
                  FontAwesomeIcons.pencil,
                  color: color ?? Colors.white.withAlpha(150),
                  size: 10,
                ),
              ),
            ),
          Text(
            friendlyTime(
              context,
              (message.modifiedAt != null)
                  ? message.modifiedAt!
                  : message.createdAt,
            ),
            style: TextStyle(
              fontSize: 10,
              color: color ?? Colors.white.withAlpha(150),
              decoration: TextDecoration.none,
              fontWeight: FontWeight.normal,
            ),
          ),
          ?statusIcon,
        ],
      ),
    );
  }

  Widget? _buildStatusIcon(Color iconColor) {
    if (message.type != MessageType.text.name || message.senderId != null) {
      return null;
    }

    if (message.ackByServer == null) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: ThreeRotatingDots(size: 8, color: iconColor),
      );
    }

    if (message.openedByAll != null || message.openedAt != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: FaIcon(
          FontAwesomeIcons.solidEye,
          size: 8,
          color: iconColor,
        ),
      );
    }

    // Now check message actions for ackByUserAt
    return StreamBuilder<List<(MessageAction, Contact)>>(
      stream: twonlyDB.messagesDao.watchMessageActions(message.messageId),
      builder: (context, snapshot) {
        final actions = snapshot.data ?? [];
        final hasAckByUser = actions.any(
          (t) => t.$1.type == MessageActionType.ackByUserAt,
        );

        if (hasAckByUser) {
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: FaIcon(
              FontAwesomeIcons.checkDouble,
              size: 8,
              color: iconColor,
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: FaIcon(
            FontAwesomeIcons.check,
            size: 8,
            color: iconColor,
          ),
        );
      },
    );
  }
}

String friendlyTime(BuildContext context, DateTime dt) {
  final now = clock.now();
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
