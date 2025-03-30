import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/json_models/message.dart';
import 'package:twonly/src/utils/misc.dart';

enum MessageSendState {
  received,
  receivedOpened,
  receiving,
  send,
  sendOpened,
  sending,
}

MessageSendState messageSendStateFromMessage(Message msg) {
  MessageSendState state;

  if (!msg.acknowledgeByServer) {
    if (msg.messageOtherId == null) {
      state = MessageSendState.sending;
    } else {
      state = MessageSendState.receiving;
    }
  } else {
    if (msg.messageOtherId == null) {
      // message send
      if (msg.openedAt == null) {
        state = MessageSendState.send;
      } else {
        state = MessageSendState.sendOpened;
      }
    } else {
      // message received
      if (msg.openedAt == null) {
        state = MessageSendState.received;
      } else {
        state = MessageSendState.receivedOpened;
      }
    }
  }
  return state;
}

class MessageSendStateIcon extends StatefulWidget {
  final List<Message> messages;
  final MainAxisAlignment mainAxisAlignment;

  const MessageSendStateIcon(this.messages,
      {super.key, this.mainAxisAlignment = MainAxisAlignment.end});

  @override
  State<MessageSendStateIcon> createState() => _MessageSendStateIconState();
}

class _MessageSendStateIconState extends State<MessageSendStateIcon> {
  @override
  void initState() {
    super.initState();
  }

  Widget getLoaderIcon(color) {
    return Row(
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1, color: color),
        ),
        SizedBox(width: 2),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> icons = [];
    String text = "";

    Color twonlyColor = Theme.of(context).colorScheme.primary;
    HashSet<MessageKind> kindsAlreadyShown = HashSet();

    for (final message in widget.messages) {
      if (icons.length == 2) break;
      if (kindsAlreadyShown.contains(message.kind)) continue;
      kindsAlreadyShown.add(message.kind);

      MessageSendState state = messageSendStateFromMessage(message);
      late Color color;

      if (message.contentJson == null) {
        color =
            getMessageColorFromType(TextMessageContent(text: ""), twonlyColor);
      } else {
        MessageContent? content = MessageContent.fromJson(
          message.kind,
          jsonDecode(message.contentJson!),
        );
        if (content == null) continue;
        color = getMessageColorFromType(content, twonlyColor);
      }

      Widget icon = Placeholder();

      switch (state) {
        case MessageSendState.receivedOpened:
          icon = Icon(Icons.crop_square, size: 14, color: color);
          text = context.lang.messageSendState_Received;
          break;
        case MessageSendState.sendOpened:
          icon = FaIcon(FontAwesomeIcons.paperPlane, size: 12, color: color);
          text = context.lang.messageSendState_Opened;
          break;
        case MessageSendState.received:
          icon = Icon(Icons.square_rounded, size: 14, color: color);
          text = context.lang.messageSendState_Received;
          if (message.kind == MessageKind.media) {
            if (message.downloadState == DownloadState.pending) {
              text = context.lang.messageSendState_TapToLoad;
            }
            if (message.downloadState == DownloadState.downloading) {
              text = context.lang.messageSendState_Loading;
              icon = getLoaderIcon(color);
            }
          }
          break;
        case MessageSendState.send:
          icon =
              FaIcon(FontAwesomeIcons.solidPaperPlane, size: 12, color: color);
          text = context.lang.messageSendState_Send;
          break;
        case MessageSendState.sending:
          icon = getLoaderIcon(color);
          text = context.lang.messageSendState_Sending;
        case MessageSendState.receiving:
          icon = getLoaderIcon(color);
          text = context.lang.messageSendState_Received;
          break;
      }

      if (message.kind == MessageKind.storedMediaFile) {
        icon = FaIcon(FontAwesomeIcons.floppyDisk, size: 12, color: color);
        text = context.lang.messageStoredInGalery;
      }

      if (message.errorWhileSending) {
        icon =
            FaIcon(FontAwesomeIcons.circleExclamation, size: 12, color: color);
        text = "Error while sending";
      }

      icons.add(icon);
    }

    if (icons.isEmpty) return Container();

    Widget icon = icons[0];

    if (icons.length == 2) {
      icon = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // First icon (bottom icon)
          icons[0],
          Positioned(
            top: 5.0,
            left: 5.0,
            child: icons[1],
          ),
          // Second icon (top icon, slightly offset)
        ],
      );
    }

    return Row(
      mainAxisAlignment: widget.mainAxisAlignment,
      children: [
        icon,
        const SizedBox(width: 3),
        Text(
          text,
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 5),
      ],
    );
  }
}
