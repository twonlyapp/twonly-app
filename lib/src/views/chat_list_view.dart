import 'package:twonly/src/components/initialsavatar_component.dart';
import 'package:twonly/src/views/search_username_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'new_message_view.dart';
import 'package:flutter/material.dart';
import 'chat_item_details_view.dart';
import 'dart:async';

enum MessageSendState { sending, send, opened, received }

class ChatItem {
  const ChatItem(
      {required this.username,
      required this.flames,
      required this.userId,
      required this.state,
      required this.lastMessageInSeconds});
  final String username;
  final int lastMessageInSeconds;
  final int flames;
  final int userId;
  final MessageSendState state;
}

/// Displays a list of SampleItems.
class ChatListView extends StatefulWidget {
  const ChatListView({
    super.key,
    this.items = const [
      ChatItem(
          userId: 0,
          username: "Alisa",
          lastMessageInSeconds: 10,
          flames: 129,
          state: MessageSendState.sending),
      ChatItem(
          userId: 1,
          username: "Klaus",
          lastMessageInSeconds: 20829,
          flames: 0,
          state: MessageSendState.received),
      ChatItem(
          userId: 2,
          username: "Markus",
          lastMessageInSeconds: 291829,
          state: MessageSendState.opened,
          flames: 38),
    ],
  });

  final List<ChatItem> items;

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  int _secondsSinceOpen = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsSinceOpen++;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  String formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds Sec.';
    } else if (seconds < 3600) {
      int minutes = seconds ~/ 60;
      return '$minutes Min.';
    } else if (seconds < 86400) {
      int hours = seconds ~/ 3600;
      return '$hours Hrs.'; // Assuming "Stu." is for hours
    } else {
      int days = seconds ~/ 86400;
      return '$days Days';
    }
  }

  Widget getMessageSateIcon(MessageSendState state) {
    List<Widget> children = [];
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
        icon = Icon(Icons.square_rounded,
            size: 14, color: Theme.of(context).colorScheme.primary);
        text = "Received";
        break;
      case MessageSendState.send:
        icon = Icon(Icons.send, size: 14);
        text = "Send";
        break;
      case MessageSendState.sending:
        icon = Row(children: [
          SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1,
              )),
          SizedBox(width: 2)
        ]);
        text = "Sending";
        break;
    }
    children.add(const SizedBox(width: 5));
    return Row(
      children: [
        icon,
        const SizedBox(width: 3),
        Text(text, style: TextStyle(fontSize: 12)),
        const SizedBox(width: 5)
      ],
    );
  }

  Widget getSubtitle(ChatItem item) {
    return Row(
      children: [
        getMessageSateIcon(item.state),
        Text("•"),
        const SizedBox(width: 5),
        Text(formatDuration(item.lastMessageInSeconds + _secondsSinceOpen),
            style: TextStyle(fontSize: 12)),
        if (item.flames > 0)
          Row(
            children: [
              const SizedBox(width: 5),
              Text("•"),
              const SizedBox(width: 5),
              Text(item.flames.toString(), style: TextStyle(fontSize: 12)),
              Icon(
                Icons.local_fire_department_sharp,
                color: const Color.fromARGB(255, 215, 73, 58),
                size: 16,
              ),
            ],
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chatsTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add), // User with add icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchUsernameView(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        restorationId: 'sampleItemListView',
        itemCount: widget.items.length,
        itemBuilder: (BuildContext context, int index) {
          final item = widget.items[index];
          return ListTile(
              title: Text(item.username),
              subtitle: getSubtitle(item),
              leading: InitialsAvatar(displayName: item.username),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SampleItemDetailsView(
                      userId: item.userId,
                    ),
                  ),
                );
              });
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewMessageView(),
            ),
          );
        },
        child: const Icon(Icons.edit),
      ),
    );
  }
}
