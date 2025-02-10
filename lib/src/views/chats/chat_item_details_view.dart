import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/components/verified_shield.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/providers/download_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact_view.dart';

class ChatListEntry extends StatelessWidget {
  const ChatListEntry(this.message, this.user, this.lastMessageFromSameUser,
      {super.key});
  final DbMessage message;
  final Contact user;
  final bool lastMessageFromSameUser;

  @override
  Widget build(BuildContext context) {
    bool right = message.messageOtherId == null;
    MessageSendState state = message.getSendState();

    bool isDownloading = false;
    List<int> token = [];

    final content = message.messageContent;
    if (message.messageReceived && content is MediaMessageContent) {
      token = content.downloadToken;
      isDownloading = context
          .watch<DownloadChangeProvider>()
          .currentlyDownloading
          .contains(token.toString());
    }

    Widget child = Container();

    if (content is TextMessageContent) {
      child = Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        padding: EdgeInsets.symmetric(
            vertical: 4, horizontal: 10), // Add some padding around the text
        decoration: BoxDecoration(
          color: right
              ? const Color.fromARGB(107, 124, 77, 255)
              : const Color.fromARGB(
                  83, 68, 137, 255), // Set the background color
          borderRadius: BorderRadius.circular(12.0), // Set border radius
        ),
        child: SelectableText(
          content.text,
          style: TextStyle(
            color: Colors.white, // Set text color for contrast
            fontSize: 17,
          ),
          textAlign: TextAlign.left, // Center the text
        ),
      );
    } else if (content is MediaMessageContent && !content.isVideo) {
      Color color = message.messageContent
          .getColor(Theme.of(context).colorScheme.primary);
      child = GestureDetector(
        onTap: () {
          if (state == MessageSendState.received && !isDownloading) {
            if (message.isDownloaded) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return MediaViewerView(user, message);
                }),
              );
            } else {
              tryDownloadMedia(message.messageId, message.otherUserId, token,
                  force: true);
            }
          }
        },
        child: Container(
          padding: EdgeInsets.all(10),
          width: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: color, // Set the background color
              width: 1.0, // Set the border width here
            ),
            borderRadius: BorderRadius.circular(12.0), // Set border radius
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: MessageSendStateIcon(
              message,
              mainAxisAlignment:
                  right ? MainAxisAlignment.center : MainAxisAlignment.center,
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: right ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
          padding: lastMessageFromSameUser
              ? EdgeInsets.only(top: 5, bottom: 0, right: 10, left: 10)
              : EdgeInsets.only(top: 5, bottom: 20, right: 10, left: 10),
          child: child),
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
  int lastChangeCounter = 0;
  final TextEditingController newMessageController = TextEditingController();
  HashSet<int> alreadyReportedOpened = HashSet<int>();
  late Contact user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
    context
        .read<MessagesChangeProvider>()
        .loadMessagesForUser(user.userId.toInt());
  }

  Future _sendMessage() async {
    if (newMessageController.text == "") return;
    setState(() {});
    await sendTextMessage(user.userId, newMessageController.text);
    newMessageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    user = context
        .watch<ContactChangeProvider>()
        .allContacts
        .firstWhere((c) => c.userId == widget.user.userId);

    List<DbMessage> messages = context
            .watch<MessagesChangeProvider>()
            .allMessagesFromUser[user.userId.toInt()] ??
        [];

    messages.where((x) => x.messageOpenedAt == null).forEach((message) {
      if (message.messageOtherId != null &&
          message.messageContent is TextMessageContent) {
        if (!alreadyReportedOpened.contains(message.messageOtherId!)) {
          setState(() {
            // so the _loadAsync will not be called again by this update
            lastChangeCounter++;
          });
          userOpenedOtherMessage(message.otherUserId, message.messageOtherId!);
          flutterLocalNotificationsPlugin.cancel(message.messageId);
          alreadyReportedOpened.add(message.messageOtherId!);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ContactView(user.userId.toInt());
            }));
          },
          child: Row(
            children: [
              InitialsAvatar(
                displayName: user.displayName,
                fontSize: 19,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Text(user.userId.toString()),
                      SizedBox(width: 10),
                      VerifiedShield(user),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length, // Number of items in the list
              reverse: true,
              itemBuilder: (context, i) {
                bool lastMessageFromSameUser = false;
                if (i > 0) {
                  lastMessageFromSameUser =
                      (messages[i - 1].messageOtherId == null &&
                              messages[i].messageOtherId == null) ||
                          (messages[i - 1].messageOtherId != null &&
                              messages[i].messageOtherId != null);
                }
                if (messages[i].messageOpenedAt != null) {
                  if ((DateTime.now())
                          .difference(messages[i].messageOpenedAt!)
                          .inHours >=
                      24) {
                    return Container();
                  }
                }
                return ChatListEntry(
                  messages[i],
                  user,
                  lastMessageFromSameUser,
                );
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
                    controller: newMessageController,
                    onSubmitted: (_) {
                      _sendMessage();
                    },
                    decoration: InputDecoration(
                      hintText: context.lang.chatListDetailInput,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            20), // Set the border radius here
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0), // Customize border color and width
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Same radius for focused border
                        borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                            20.0), // Same radius for enabled border
                        borderSide: BorderSide(color: Colors.grey, width: 2.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () {
                    _sendMessage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
