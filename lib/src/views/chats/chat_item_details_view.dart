import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/animate_icon.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/components/verified_shield.dart';
import 'package:twonly/src/database/contacts_db.dart';
import 'package:twonly/src/database/database.dart';
import 'package:twonly/src/database/messages_db.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/send_next_media_to.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact_view.dart';
import 'package:twonly/src/views/home_view.dart';

class ChatListEntry extends StatelessWidget {
  const ChatListEntry(this.message, this.userId, this.lastMessageFromSameUser,
      {super.key});
  final Message message;
  final int userId;
  final bool lastMessageFromSameUser;

  @override
  Widget build(BuildContext context) {
    bool right = message.messageOtherId == null;
    MessageSendState state = messageSendStateFromMessage(message);

    bool isDownloading = false;
    List<int> token = [];

    final messageJson = MessageJson.fromJson(jsonDecode(message.contentJson!));
    final content = messageJson.content;
    if (message.messageOtherId != null && content is MediaMessageContent) {
      token = content.downloadToken;
      isDownloading = message.downloadState == DownloadState.downloading;
    }

    Widget child = Container();

    if (content is TextMessageContent) {
      if (EmojiAnimation.supported(content.text)) {
        child = child = Container(
          constraints: BoxConstraints(
            maxWidth: 100,
          ),
          padding: EdgeInsets.symmetric(
              vertical: 4, horizontal: 10), // Add some padding around the text
          child: EmojiAnimation(emoji: content.text),
        );
      } else {
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
      }
    } else if (content is MediaMessageContent && !content.isVideo) {
      Color color = getMessageColorFromType(
          content, Theme.of(context).colorScheme.primary);

      child = GestureDetector(
        onTap: () {
          if (state == MessageSendState.received && !isDownloading) {
            if (message.downloadState == DownloadState.downloaded) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return MediaViewerView(userId);
                }),
              );
            } else {
              tryDownloadMedia(message.messageId, message.contactId, token,
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
              [message],
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
  const ChatItemDetailsView(this.userid, {super.key});

  final int userid;

  @override
  State<ChatItemDetailsView> createState() => _ChatItemDetailsViewState();
}

class _ChatItemDetailsViewState extends State<ChatItemDetailsView> {
  TextEditingController newMessageController = TextEditingController();
  HashSet<int> alreadyReportedOpened = HashSet<int>();
  Contact? user;
  String currentInputText = "";
  late StreamSubscription<Contact> userSub;
  late StreamSubscription<List<Message>> messageSub;
  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    initStreams();
  }

  @override
  void dispose() {
    super.dispose();
    userSub.cancel();
    messageSub.cancel();
  }

  Future initStreams() async {
    Stream<Contact> contact = context.db.watchContact(widget.userid);
    userSub = contact.listen((contact) {
      setState(() {
        user = contact;
      });
    });

    Stream<List<Message>> msgStream =
        context.db.watchAllMessagesFrom(widget.userid);
    messageSub = msgStream.listen((msgs) {
      if (!context.mounted) return;
      var updated = false;
      for (Message msg in msgs) {
        if (msg.kind == MessageKind.textMessage &&
            msg.messageOtherId != null &&
            msg.openedAt == null) {
          updated = true;
          flutterLocalNotificationsPlugin.cancel(msg.messageId);
          notifyContactAboutOpeningMessage(widget.userid, msg.messageOtherId!);
        }
      }
      if (updated) {
        context.db.openedAllTextMessages(widget.userid);
      } else {
        // The stream should be get an update, so only update the UI when all are opened
        setState(() {
          messages = msgs;
        });
      }
    });
  }

  Future _sendMessage() async {
    if (newMessageController.text == "" || user == null) return;
    await sendTextMessage(user!.userId, newMessageController.text);
    newMessageController.clear();
    currentInputText = "";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ContactView(widget.userid);
            }));
          },
          child: (user == null)
              ? Container()
              : Row(
                  children: [
                    InitialsAvatar(
                      getContactDisplayName(user!),
                      fontSize: 19,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        child: Row(
                          children: [
                            Text(getContactDisplayName(user!)),
                            SizedBox(width: 10),
                            VerifiedShield(user!),
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
                // if (messages[i].openedAt != null) {
                //   if (calculateTimeDifference(
                //               DateTime.now(), messages[i].openedAt!)
                //           .inHours >=
                //       24) {
                //     return Container();
                //   }
                // }
                return ChatListEntry(
                  messages[i],
                  widget.userid,
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
                    onChanged: (value) {
                      currentInputText = value;
                      setState(() {});
                    },
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
                (currentInputText != "")
                    ? IconButton(
                        icon: FaIcon(FontAwesomeIcons.solidPaperPlane),
                        onPressed: () {
                          _sendMessage();
                        },
                      )
                    : IconButton(
                        icon: FaIcon(FontAwesomeIcons.camera),
                        onPressed: () {
                          context
                              .read<SendNextMediaTo>()
                              .updateSendNextMediaTo(widget.userid);
                          globalUpdateOfHomeViewPageIndex(0);
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                      )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
