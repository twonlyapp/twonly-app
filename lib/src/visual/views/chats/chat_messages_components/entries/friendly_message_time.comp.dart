import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';

class FriendlyMessageTime extends StatelessWidget {
  const FriendlyMessageTime({
    required this.message,
    this.color,
    super.key,
  });

  final StoredMessage message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final statusIcon = _buildStatusIcon(
      context,
      color ?? context.appColor(AppColor.chatMessageMeta),
    );

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
                  color: color ?? context.appColor(AppColor.chatMessageMeta),
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
              color: color ?? context.appColor(AppColor.chatMessageMeta),
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
    if (message.senderId == null &&
        (ChatMessageActionScope.maybeOf(context)?.failedMessageIds.contains(
              message.messageId,
            ) ??
            false)) {
      // Media fails for several reasons. Text only fails when the contact
      // has no keys on the server, meaning they have not opened a current
      // app version, so say so next to the icon.
      if (message.type == MessageType.text.name ||
          message.type == MessageType.webxdcApp.name) {
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 12, color: context.color.error),
              const SizedBox(width: 2),
              Text(
                context.lang.messageSendFailedUserInactive,
                style: TextStyle(
                  fontSize: 10,
                  color: context.color.error,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Tooltip(
          message: context.lang.mediaSendFailed,
          child: Icon(
            Icons.error_outline,
            size: 12,
            color: context.color.error,
          ),
        ),
      );
    }
    if (message.senderId == null &&
        message.ackByServer == null &&
        (ChatMessageActionScope.maybeOf(context)?.deferredMessageIds.contains(
              message.messageId,
            ) ??
            false)) {
      // The server holds new messages back until the contact fetches the
      // ones already waiting for them. Nothing failed: the app retries.
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Tooltip(
          message: context.lang.messageSendDeferredExplanation,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule, size: 12, color: iconColor),
              const SizedBox(width: 2),
              Text(
                context.lang.messageSendDeferred,
                style: TextStyle(
                  fontSize: 10,
                  color: iconColor,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if ((message.type != MessageType.text.name &&
            message.type != MessageType.webxdcApp.name) ||
        message.senderId != null) {
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
      stream: watchRustDatabase(
        (control) => rust_messages
            .watchMessageActions(id: message.messageId, control: control)
            .map(messageActionsWithContacts),
      ),
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
    this.failedMessageIds = const {},
    this.deferredMessageIds = const {},
    super.key,
  });

  final Set<String> ackedMessageIds;
  final Set<String> failedMessageIds;

  /// Messages the server refused for now because a sending limit was
  /// reached. They stay queued and are retried with a growing delay.
  final Set<String> deferredMessageIds;

  static ChatMessageActionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatMessageActionScope>();

  @override
  bool updateShouldNotify(ChatMessageActionScope oldWidget) =>
      ackedMessageIds != oldWidget.ackedMessageIds ||
      failedMessageIds != oldWidget.failedMessageIds ||
      deferredMessageIds != oldWidget.deferredMessageIds;
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
