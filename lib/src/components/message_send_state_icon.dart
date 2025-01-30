import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/download_change_provider.dart';

enum MessageSendState {
  received,
  receivedOpened,
  receiving,
  send,
  sendOpened,
  sending,
}

class MessageSendStateIcon extends StatelessWidget {
  final DbMessage message;
  final MainAxisAlignment mainAxisAlignment;

  const MessageSendStateIcon(this.message,
      {super.key, this.mainAxisAlignment = MainAxisAlignment.end});

  @override
  Widget build(BuildContext context) {
    Widget icon = Placeholder();
    String text = "";

    Color color =
        message.messageKind.getColor(Theme.of(context).colorScheme.primary);

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

    switch (message.getSendState()) {
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
        icon = loaderIcon;
        text = "Sending";
        break;
    }

    if (!message.isDownloaded) {
      text = "Tap do load";
    }

    bool isDownloading = false;
    if (message.messageContent != null &&
        message.messageContent!.downloadToken != null) {
      isDownloading = context
          .watch<DownloadChangeProvider>()
          .currentlyDownloading
          .contains(message.messageContent!.downloadToken!);
    }

    if (isDownloading) {
      text = "Downloading";
      icon = loaderIcon;
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
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
