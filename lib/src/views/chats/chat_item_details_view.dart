import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/download_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';
import 'package:twonly/src/utils/misc.dart';

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
        child: Text(
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
              tryDownloadMedia(token, force: true);
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
  List<DbMessage> _messages = [];
  int lastChangeCounter = 0;
  final TextEditingController newMessageController = TextEditingController();
  HashSet<int> alreadyReportedOpened = HashSet<int>();

  @override
  void initState() {
    super.initState();
    _loadAsync(updateOpenStatus: true);
  }

  Future _loadAsync({bool updateOpenStatus = false}) async {
    if (_messages.isEmpty) {
      _messages =
          await DbMessages.getAllMessagesForUser(widget.user.userId.toInt());
    } else {
      int lastMessageId = _messages.first.messageId;
      List<DbMessage> toAppend =
          await DbMessages.getAllMessagesForUserWithHigherMessageId(
              widget.user.userId.toInt(), lastMessageId);
      _messages.insertAll(0, toAppend);
    }

    try {
      if (context.mounted) {
        setState(() {});
      }
    } catch (e) {
      // state should be disposed
      return;
    }

    if (updateOpenStatus) {
      _messages.where((x) => x.messageOpenedAt == null).forEach((message) {
        if (message.messageOtherId != null &&
            message.messageContent is TextMessageContent) {
          if (!alreadyReportedOpened.contains(message.messageOtherId!)) {
            userOpenedOtherMessage(
                message.otherUserId, message.messageOtherId!);
            alreadyReportedOpened.add(message.messageOtherId!);
          }
        }
      });
    }
  }

  Future _sendMessage() async {
    String text = newMessageController.text;
    if (text == "") return;
    await sendTextMessage(widget.user.userId, newMessageController.text);
    newMessageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final changeCounter = context.watch<MessagesChangeProvider>().changeCounter;
    if (changeCounter.containsKey(widget.user.userId.toInt())) {
      if (changeCounter[widget.user.userId.toInt()] != lastChangeCounter) {
        _loadAsync(updateOpenStatus: true);
        lastChangeCounter = changeCounter[widget.user.userId.toInt()]!;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.chatListDetailTitle(widget.user.displayName)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length, // Number of items in the list
              reverse: true,
              itemBuilder: (context, i) {
                bool lastMessageFromSameUser = false;
                if (i > 0) {
                  lastMessageFromSameUser =
                      (_messages[i - 1].messageOtherId == null &&
                              _messages[i].messageOtherId == null) ||
                          (_messages[i - 1].messageOtherId != null &&
                              _messages[i].messageOtherId != null);
                }
                if (_messages[i].messageOpenedAt != null) {
                  if ((DateTime.now())
                          .difference(_messages[i].messageOpenedAt!)
                          .inHours >=
                      24) {
                    return Container();
                  }
                }
                return ChatListEntry(
                  _messages[i],
                  widget.user,
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 10)
                        // border: OutlineInputBorder(),
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
