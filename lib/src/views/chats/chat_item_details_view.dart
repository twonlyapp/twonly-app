import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/chats/components/chat_list_entry.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/services/notification_service.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact_view.dart';

Color getMessageColor(Message message) {
  return (message.messageOtherId == null)
      ? Color.fromARGB(107, 124, 77, 255)
      : Color.fromARGB(83, 68, 137, 255);
}

/// Displays detailed information about a SampleItem.
class ChatItemDetailsView extends StatefulWidget {
  const ChatItemDetailsView(this.contact, {super.key});

  final Contact contact;

  @override
  State<ChatItemDetailsView> createState() => _ChatItemDetailsViewState();
}

class _ChatItemDetailsViewState extends State<ChatItemDetailsView> {
  TextEditingController newMessageController = TextEditingController();
  HashSet<int> alreadyReportedOpened = HashSet<int>();
  late Contact user;
  String currentInputText = "";
  late StreamSubscription<Contact> userSub;
  late StreamSubscription<List<Message>> messageSub;
  List<Message> messages = [];
  Map<int, List<Message>> reactionsToMyMessages = {};
  Map<int, List<Message>> reactionsToOtherMessages = {};
  Message? responseToMessage;
  late FocusNode textFieldFocus;

  @override
  void initState() {
    super.initState();
    user = widget.contact;
    textFieldFocus = FocusNode();
    initStreams();
  }

  @override
  void dispose() {
    super.dispose();
    userSub.cancel();
    messageSub.cancel();
    textFieldFocus.dispose();
  }

  Future initStreams() async {
    await twonlyDatabase.messagesDao.removeOldMessages();
    Stream<Contact> contact =
        twonlyDatabase.contactsDao.watchContact(widget.contact.userId);
    userSub = contact.listen((contact) {
      setState(() {
        user = contact;
      });
    });

    Stream<List<Message>> msgStream =
        twonlyDatabase.messagesDao.watchAllMessagesFrom(widget.contact.userId);
    messageSub = msgStream.listen((msgs) {
      // if (!context.mounted) return;
      if (Platform.isAndroid) {
        flutterLocalNotificationsPlugin.cancel(widget.contact.userId);
      } else {
        flutterLocalNotificationsPlugin.cancelAll();
      }
      List<Message> displayedMessages = [];
      // should be cleared
      Map<int, List<Message>> tmpReactionsToMyMessages = {};
      Map<int, List<Message>> tmpReactionsToOtherMessages = {};

      List<int> openedMessageOtherIds = [];
      for (Message msg in msgs) {
        if (msg.kind == MessageKind.textMessage &&
            msg.messageOtherId != null &&
            msg.openedAt == null) {
          openedMessageOtherIds.add(msg.messageOtherId!);
        }

        if (msg.responseToOtherMessageId != null) {
          if (!tmpReactionsToOtherMessages
              .containsKey(msg.responseToOtherMessageId!)) {
            tmpReactionsToOtherMessages[msg.responseToOtherMessageId!] = [msg];
          } else {
            tmpReactionsToOtherMessages[msg.responseToOtherMessageId!]!
                .add(msg);
          }
        } else if (msg.responseToMessageId != null) {
          if (!tmpReactionsToMyMessages.containsKey(msg.responseToMessageId!)) {
            tmpReactionsToMyMessages[msg.responseToMessageId!] = [msg];
          } else {
            tmpReactionsToMyMessages[msg.responseToMessageId!]!.add(msg);
          }
        } else {
          displayedMessages.add(msg);
        }
      }
      if (openedMessageOtherIds.isNotEmpty) {
        notifyContactAboutOpeningMessage(
            widget.contact.userId, openedMessageOtherIds);
      }
      twonlyDatabase.messagesDao
          .openedAllNonMediaMessages(widget.contact.userId);
      // should be fixed with that
      // if (!updated) {
      //   // The stream should be get an update, so only update the UI when all are opened
      setState(() {
        reactionsToMyMessages = tmpReactionsToMyMessages;
        reactionsToOtherMessages = tmpReactionsToOtherMessages;
        messages = displayedMessages;
      });
      // }
    });
  }

  Future _sendMessage() async {
    if (newMessageController.text == "") return;
    await sendTextMessage(
      user.userId,
      TextMessageContent(
        text: newMessageController.text,
        responseToMessageId: responseToMessage?.messageOtherId,
      ),
      PushKind.text,
      responseToMessageId: responseToMessage?.messageId,
    );
    newMessageController.clear();
    currentInputText = "";
    responseToMessage = null;
    setState(() {});
  }

  Widget getResponsePreview(Message message) {
    String? subtitle;

    if (message.kind == MessageKind.textMessage) {
      if (message.contentJson != null) {
        MessageContent? content = MessageContent.fromJson(
            MessageKind.textMessage, jsonDecode(message.contentJson!));
        if (content is TextMessageContent) {
          subtitle = truncateString(content.text);
        }
      }
    }
    if (message.kind == MessageKind.media) {
      MessageContent? content = MessageContent.fromJson(
          MessageKind.media, jsonDecode(message.contentJson!));
      if (content is MediaMessageContent) {
        subtitle = content.isVideo ? "Video" : "Image";
      }
    }

    String username = "You";
    if (message.messageOtherId != null) {
      username = getContactDisplayName(widget.contact);
    }

    Color color = getMessageColor(message);

    return Container(
      padding: EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: color,
            width: 2.0,
          ),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) Text(subtitle)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return ContactView(widget.contact.userId);
            }));
          },
          child: Row(
            children: [
              ContactAvatar(
                contact: user,
                fontSize: 19,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Text(getContactDisplayName(user)),
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
                    key: Key(msg.messageId.toString()),
                    msg,
                    user,
                    lastMessageFromSameUser,
                    reactions,
                    onResponseTriggered: (message) {
                      setState(() {
                        responseToMessage = message;
                      });
                      textFieldFocus.requestFocus();
                    },
                  );
                },
              ),
            ),
            if (responseToMessage != null)
              Container(
                padding: const EdgeInsets.only(
                  bottom: 00,
                  left: 20,
                  right: 20,
                  top: 10,
                ),
                child: Row(
                  children: [
                    Expanded(child: getResponsePreview(responseToMessage!)),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          responseToMessage = null;
                        });
                      },
                      icon: FaIcon(
                        FontAwesomeIcons.xmark,
                        size: 16,
                      ),
                    )
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 30,
                left: 20,
                right: 20,
                top: 10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: newMessageController,
                      focusNode: textFieldFocus,
                      onChanged: (value) {
                        currentInputText = value;
                        setState(() {});
                      },
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration: inputTextMessageDeco(context),
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return CameraSendToView(widget.contact);
                                },
                              ),
                            );
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
