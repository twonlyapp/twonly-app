import 'add_new_user_view.dart';
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
          username: "Franz",
          lastMessageInSeconds: 20829,
          flames: 0,
          state: MessageSendState.received),
      ChatItem(
          userId: 2,
          username: "Heiner",
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

  Widget createInitialsAvatar(String username) {
    // Extract initials from the username
    List<String> nameParts = username.split(' ');
    String initials = nameParts.map((part) => part[0]).join().toUpperCase();
    if (initials.length > 2) {
      initials = initials[0] + initials[1];
    }

    // Generate a color based on the initials (you can customize this logic)
    Color avatarColor = _getColorFromInitials(initials);

    return CircleAvatar(
      backgroundColor: avatarColor,
      child: Text(
        initials,
        style: TextStyle(
            color: _getTextColor(Colors.white), fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate the luminance of the background color
    double luminance = backgroundColor.computeLuminance();
    // Return white for dark backgrounds and black for light backgrounds
    return luminance < 0.5 ? Colors.white : Colors.black;
  }

  Color _getColorFromInitials(String initials) {
    // Define color lists for light and dark themes
    List<Color> lightColors = [
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.cyan,
      Colors.lime,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];

    List<Color> darkColors = [
      Colors.deepOrange,
      Colors.deepPurple,
      Colors.redAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.amberAccent,
      Colors.indigoAccent,
      Colors.cyanAccent,
      Colors.limeAccent,
      Colors.pinkAccent,
    ];

    // Simple logic to generate a hash from initials
    int hash = initials.codeUnits.fold(0, (prev, element) => prev + element);

    // Select the appropriate color list based on the current theme brightness
    List<Color> colors = Theme.of(context).brightness == Brightness.dark
        ? darkColors
        : lightColors;

    // Use the hash to select a color from the list
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: ListView.builder(
        restorationId: 'sampleItemListView',
        itemCount: widget.items.length,
        itemBuilder: (BuildContext context, int index) {
          final item = widget.items[index];
          return ListTile(
              title: Text(item.username),
              subtitle: getSubtitle(item),
              leading: createInitialsAvatar(item.username),
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
              builder: (context) => AddNewUserView(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
