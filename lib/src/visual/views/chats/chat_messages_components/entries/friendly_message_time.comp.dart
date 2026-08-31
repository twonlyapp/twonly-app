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
    final statusIcon = _buildStatusIcon(context, Colors.grey.shade400);

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

  Widget? _buildStatusIcon(BuildContext context, Color iconColor) {
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

    final sharedAckState = ChatMessageActionScope.maybeOf(context);
    if (sharedAckState != null) {
      return _ackIcon(
        iconColor,
        sharedAckState.ackedMessageIds.contains(message.messageId),
      );
    }

    return StreamBuilder<List<(MessageAction, Contact)>>(
      stream: twonlyDB.messagesDao.watchMessageActions(message.messageId),
      builder: (context, snapshot) {
        final actions = snapshot.data ?? [];
        final hasAckByUser = actions.any(
          (t) => t.$1.type == MessageActionType.ackByUserAt,
        );

        return _ackIcon(iconColor, hasAckByUser);
      },
    );
  }

  Widget _ackIcon(Color iconColor, bool acknowledged) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: FaIcon(
      acknowledged ? FontAwesomeIcons.checkDouble : FontAwesomeIcons.check,
      size: 8,
      color: iconColor,
    ),
  );
}

class ChatMessageActionScope extends InheritedWidget {
  const ChatMessageActionScope({
    required this.ackedMessageIds,
    required super.child,
    super.key,
  });

  final Set<String> ackedMessageIds;

  static ChatMessageActionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatMessageActionScope>();

  @override
  bool updateShouldNotify(ChatMessageActionScope oldWidget) =>
      ackedMessageIds != oldWidget.ackedMessageIds;
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
  final use24Hour = MediaQuery.alwaysUse24HourFormatOf(context);

  final locale = Localizations.localeOf(context).toString();
  // Building a DateFormat parses a pattern and looks up locale data, which is
  // wasted work when every visible message asks for the same two formats.
  final format = _timeFormats.putIfAbsent(
    '$locale|$use24Hour',
    () => use24Hour ? DateFormat.Hm(locale) : DateFormat.jm(locale),
  );
  return format.format(dt);
}

final Map<String, DateFormat> _timeFormats = {};
