import 'package:flutter/material.dart';

enum MessageSendState {
  opened,
  received,
  send,
  sending,
}

class MessageSendStateIcon extends StatelessWidget {
  final MessageSendState state;

  const MessageSendStateIcon({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Widget icon = Placeholder();
    String text = "";

    switch (state) {
      case MessageSendState.opened:
        icon = Icon(
          Icons.crop_square,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        );
        text = "Opened";
        break;
      case MessageSendState.received:
        icon = Icon(
          Icons.square_rounded,
          size: 14,
          color: Theme.of(context).colorScheme.primary,
        );
        text = "Received";
        break;
      case MessageSendState.send:
        icon = Icon(
          Icons.send,
          size: 14,
        );
        text = "Send";
        break;
      case MessageSendState.sending:
        icon = Row(
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1,
              ),
            ),
            SizedBox(width: 2),
          ],
        );
        text = "Sending";
        break;
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
