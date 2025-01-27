import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/model/json/message.dart';

enum MessageSendState {
  received,
  receivedOpened,
  receiving,
  send,
  sendOpened,
  sending,
}

class MessageSendStateIcon extends StatelessWidget {
  final MessageSendState state;
  final MessageKind kind;
  final bool isDownloaded;

  const MessageSendStateIcon(this.state, this.isDownloaded, this.kind,
      {super.key});

  @override
  Widget build(BuildContext context) {
    Widget icon = Placeholder();
    String text = "";

    Color color = Theme.of(context).colorScheme.primary;
    if (kind == MessageKind.textMessage) {
      color = Colors.lightBlue;
    } else if (kind == MessageKind.video) {
      color = Colors.deepPurple;
    }

    switch (state) {
      case MessageSendState.receivedOpened:
        icon = Icon(Icons.crop_square, size: 14, color: color);
        text = "Received";
        break;
      case MessageSendState.sendOpened:
        icon = FaIcon(FontAwesomeIcons.paperPlane, size: 12, color: color);
        text = "Opened";
        break;
      case MessageSendState.received:
        icon = Icon(Icons.square_rounded, size: 14, color: color);
        text = "Received";
        break;
      case MessageSendState.send:
        icon = FaIcon(FontAwesomeIcons.solidPaperPlane, size: 12, color: color);
        text = "Send";
        break;
      case MessageSendState.sending:
      case MessageSendState.receiving:
        icon = Row(
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1, color: color),
            ),
            SizedBox(width: 2),
          ],
        );
        text = "Sending";
        break;
    }

    if (!isDownloaded) {
      text = "Tap do load";
    }

    return Row(
      children: [
        icon,
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12)),
        const SizedBox(width: 5),
      ],
    );
  }
}
