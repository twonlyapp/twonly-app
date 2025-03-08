import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/database.dart';
import 'package:twonly/src/database/messages_db.dart';
import 'package:twonly/src/model/json/message.dart';
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
    state = MessageSendState.sending;
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
  bool containsVideo = false;
  bool containsText = false;
  bool containsImage = false;

  @override
  void initState() {
    super.initState();

    for (Message msg in widget.messages) {
      if (msg.kind == MessageKind.textMessage) {
        containsText = true;
      }
      if (msg.kind == MessageKind.media) {
        MessageJson message =
            MessageJson.fromJson(jsonDecode(msg.contentJson!));
        final content = message.content;
        if (content is MediaMessageContent) {
          if (content.isVideo) {
            containsVideo = true;
          } else {
            containsImage = true;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget icon = Placeholder();
    String text = "";

    Widget loaderIcon = Row(
      children: [
        SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(strokeWidth: 1, color: color),
        ),
        SizedBox(width: 2),
      ],
    );

    MessageSendState state = messageSendStateFromMessage(message);

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
        break;
      case MessageSendState.send:
        icon = FaIcon(FontAwesomeIcons.solidPaperPlane, size: 12, color: color);
        text = context.lang.messageSendState_Send;
        break;
      case MessageSendState.sending:
      case MessageSendState.receiving:
        icon = loaderIcon;
        text = context.lang.messageSendState_Sending;
        break;
    }

    if (message.downloadState == DownloadState.pending) {
      text = context.lang.messageSendState_TapToLoad;
    }
    if (message.downloadState == DownloadState.downloaded) {
      text = context.lang.messageSendState_Loading;
      icon = loaderIcon;
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
