import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/animate_icon.dart';
import 'package:twonly/src/components/better_text.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/components/verified_shield.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/json_models/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/api/media.dart';
import 'package:twonly/src/providers/send_next_media_to.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact_view.dart';
import 'package:twonly/src/views/home_view.dart';

class ChatListEntry extends StatelessWidget {
  const ChatListEntry(
      this.message, this.userId, this.lastMessageFromSameUser, this.reactions,
      {super.key});
  final Message message;
  final int userId;
  final bool lastMessageFromSameUser;
  final List<Message> reactions;

  Widget getReactionRow() {
    List<Widget> children = [];
    for (final reaction in reactions) {
      if (children.isNotEmpty) break;
      MessageContent? content = MessageContent.fromJson(
          reaction.kind, jsonDecode(reaction.contentJson!));
      if (content is TextMessageContent) {
        late Widget child;
        if (EmojiAnimation.animatedIcons.containsKey(content.text)) {
          child = SizedBox(
            height: 18,
            child: EmojiAnimation(emoji: content.text),
          );
        } else {
          child = Text(content.text, style: TextStyle(fontSize: 14));
        }
        children.add(Padding(
          padding: EdgeInsets.only(left: 3),
          child: child,
        ));
      }
    }

    if (children.isEmpty) return Container();

    return Row(
      mainAxisAlignment: message.messageOtherId == null
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool right = message.messageOtherId == null;

    MessageContent? content =
        MessageContent.fromJson(message.kind, jsonDecode(message.contentJson!));

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
          padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
          decoration: BoxDecoration(
            color: right
                ? const Color.fromARGB(107, 124, 77, 255)
                : const Color.fromARGB(83, 68, 137, 255),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: BetterText(text: content.text),
        );
      }
    } else if (content is MediaMessageContent && !content.isVideo) {
      Color color = getMessageColorFromType(
        content,
        Theme.of(context).colorScheme.primary,
      );

      child = GestureDetector(
        onTap: () {
          if (message.kind == MessageKind.media) {
            if (message.downloadState == DownloadState.downloaded &&
                message.openedAt == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return MediaViewerView(userId);
                }),
              );
            } else {
              tryDownloadMedia(message.messageId, message.contactId, content,
                  force: true);
            }
          }
        },
        child: Container(
          padding: EdgeInsets.all(10),
          width: 150,
          decoration: BoxDecoration(
            border: Border.all(
              color: color,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: MessageSendStateIcon(
              [message],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),
        ),
      );
    } else if (message.kind == MessageKind.storedMediaFile) {
      child = Container(
        padding: EdgeInsets.all(5),
        width: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color: messageKindColors["text"]!,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: MessageSendStateIcon(
            [message],
            mainAxisAlignment:
                right ? MainAxisAlignment.center : MainAxisAlignment.center,
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
        child: Stack(
          alignment: right ? Alignment.centerRight : Alignment.centerLeft,
          children: [
            child,
            Positioned(bottom: 5, left: 5, right: 5, child: getReactionRow()),
          ],
        ),
      ),
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
  Map<int, List<Message>> reactionsToMyMessages = {};
  Map<int, List<Message>> reactionsToOtherMessages = {};

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
    await twonlyDatabase.messagesDao.removeOldMessages();
    Stream<Contact> contact =
        twonlyDatabase.contactsDao.watchContact(widget.userid);
    userSub = contact.listen((contact) {
      setState(() {
        user = contact;
      });
    });

    Stream<List<Message>> msgStream =
        twonlyDatabase.messagesDao.watchAllMessagesFrom(widget.userid);
    messageSub = msgStream.listen((msgs) {
      if (!context.mounted) return;
      flutterLocalNotificationsPlugin.cancel(widget.userid);
      var updated = false;
      List<Message> displayedMessages = [];
      // should be cleared
      Map<int, List<Message>> tmpReactionsToMyMessages = {};
      Map<int, List<Message>> tmpTeactionsToOtherMessages = {};
      for (Message msg in msgs) {
        if (msg.kind == MessageKind.textMessage &&
            msg.messageOtherId != null &&
            msg.openedAt == null) {
          updated = true;
          notifyContactAboutOpeningMessage(widget.userid, msg.messageOtherId!);
        }

        if (msg.responseToMessageId != null) {
          if (!tmpReactionsToMyMessages.containsKey(msg.responseToMessageId!)) {
            tmpReactionsToMyMessages[msg.responseToMessageId!] = [msg];
          } else {
            tmpReactionsToMyMessages[msg.responseToMessageId!]!.add(msg);
          }
        } else if (msg.responseToOtherMessageId != null) {
          if (!tmpTeactionsToOtherMessages
              .containsKey(msg.responseToOtherMessageId!)) {
            tmpTeactionsToOtherMessages[msg.responseToOtherMessageId!] = [msg];
          } else {
            tmpTeactionsToOtherMessages[msg.responseToOtherMessageId!]!
                .add(msg);
          }
        } else {
          displayedMessages.add(msg);
        }
      }
      twonlyDatabase.messagesDao.openedAllNonMediaMessages(widget.userid);
      if (!updated) {
        // The stream should be get an update, so only update the UI when all are opened
        setState(() {
          reactionsToMyMessages = tmpReactionsToMyMessages;
          reactionsToOtherMessages = tmpTeactionsToOtherMessages;
          messages = displayedMessages;
        });
      }
    });
  }

  Future _sendMessage() async {
    if (newMessageController.text == "" || user == null) return;
    await sendTextMessage(
      user!.userId,
      TextMessageContent(
        text: newMessageController.text,
      ),
      PushKind.text,
    );
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
                    ContactAvatar(
                      contact: user!,
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
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
                  Message msg = messages[i];
                  List<Message> reactions = [];
                  if (reactionsToMyMessages.containsKey(msg.messageId)) {
                    reactions = reactionsToMyMessages[msg.messageId]!;
                  }
                  if (msg.messageOtherId != null &&
                      reactionsToOtherMessages
                          .containsKey(msg.messageOtherId!)) {
                    reactions = reactionsToOtherMessages[msg.messageOtherId!]!;
                  }
                  return ChatListEntry(
                    msg,
                    widget.userid,
                    lastMessageFromSameUser,
                    reactions,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 30, left: 20, right: 20, top: 10),
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
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2.0),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.0),
                          borderSide:
                              BorderSide(color: Colors.grey, width: 2.0),
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
                            Navigator.popUntil(
                                context, (route) => route.isFirst);
                          },
                        )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
