import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';

class ChatListEntry extends StatelessWidget {
  const ChatListEntry(this.message, {super.key});
  final DbMessage message;
  @override
  Widget build(BuildContext context) {
    bool right = message.messageOtherId == null;

    Widget child = Container();

    switch (message.messageKind) {
      case MessageKind.textMessage:
        child = Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width *
                0.8, // Maximum 80% of the screen width
          ),
          padding: EdgeInsets.symmetric(
              vertical: 4, horizontal: 10), // Add some padding around the text
          decoration: BoxDecoration(
            color: right
                ? Colors.deepPurpleAccent
                : Colors.blueAccent, // Set the background color
            borderRadius: BorderRadius.circular(12.0), // Set border radius
          ),
          child: Text(
            message.messageContent!.text!,
            style: TextStyle(
              color: Colors.white, // Set text color for contrast
              fontSize: 17,
            ),
            textAlign: TextAlign.left, // Center the text
          ),
        );
        break;
      default:
        return Container();
    }

    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(padding: EdgeInsets.all(10), child: child),
    );
  }
}

/// Displays detailed information about a SampleItem.
class ChatItemDetailsView extends StatefulWidget {
  const ChatItemDetailsView({super.key, required this.user});

  final Contact user;

  @override
  State<ChatItemDetailsView> createState() => _ChatItemDetailsViewState();
}

class _ChatItemDetailsViewState extends State<ChatItemDetailsView> {
  List<DbMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadAsync();
  }

  Future _loadAsync() async {
    _messages =
        await DbMessages.getAllMessagesForUser(widget.user.userId.toInt());
  }

  @override
  Widget build(BuildContext context) {
    // messages = messages.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Chat with ${widget.user.displayName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length, // Number of items in the list
              reverse: true,
              itemBuilder: (context, i) {
                return ChatListEntry(_messages[i]);
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.only(bottom: 30, left: 20, right: 20, top: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    // controller: _controller,
                    decoration: InputDecoration(
                        hintText: 'Type a message',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10)
                        // border: OutlineInputBorder(),
                        ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () {
                    // Handle send action
                  },
                ),
              ],
            ),
          ),
          // Container(
          //   child: Row(children: [
          //     Padding(
          //       padding: const EdgeInsets.only(bottom: 40, left: 10, right: 10),
          //       child: TextField(
          //         decoration: InputDecoration(
          //           // border: OutlineInputBorder(),
          //           hintText: 'Enter your message',
          //         ),
          //       ),
          //     ),
          //     IconButton(
          //       icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
          //       onPressed: () {
          //         // Handle send action
          //       },
          //     ),
          //   ]),
          // ),
        ],
      ),
    );
  }
}
