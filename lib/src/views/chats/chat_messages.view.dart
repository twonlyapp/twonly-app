import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_message_entry.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/notification.service.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/views/tutorial/tutorials.dart';

Color getMessageColor(Message message) {
  return (message.messageOtherId == null)
      ? Color.fromARGB(255, 58, 136, 102)
      : Color.fromARGB(83, 68, 137, 255);
}

/// Displays detailed information about a SampleItem.
class ChatMessagesView extends StatefulWidget {
  const ChatMessagesView(this.contact, {super.key});

  final Contact contact;

  @override
  State<ChatMessagesView> createState() => _ChatMessagesViewState();
}

class _ChatMessagesViewState extends State<ChatMessagesView> {
  TextEditingController newMessageController = TextEditingController();
  HashSet<int> alreadyReportedOpened = HashSet<int>();
  late Contact user;
  String currentInputText = "";
  late StreamSubscription<Contact?> userSub;
  late StreamSubscription<List<Message>> messageSub;
  List<Message> messages = [];
  List<MemoryItem> galleryItems = [];
  Map<int, List<Message>> textReactionsToMessageId = {};
  Map<int, List<Message>> emojiReactionsToMessageId = {};
  Message? responseToMessage;
  GlobalKey verifyShieldKey = GlobalKey();
  late FocusNode textFieldFocus;
  Timer? tutorial;

  @override
  void initState() {
    super.initState();
    user = widget.contact;
    textFieldFocus = FocusNode();
    initStreams();

    tutorial = Timer(Duration(seconds: 1), () async {
      tutorial = null;
      if (!mounted) return;
      await showVerifyShieldTutorial(context, verifyShieldKey);
    });
  }

  @override
  void dispose() {
    super.dispose();
    userSub.cancel();
    messageSub.cancel();
    tutorial?.cancel();
    textFieldFocus.dispose();
  }

  Future initStreams() async {
    await twonlyDB.messagesDao.removeOldMessages();
    Stream<Contact?> contact =
        twonlyDB.contactsDao.watchContact(widget.contact.userId);
    userSub = contact.listen((contact) {
      if (contact == null) return;
      setState(() {
        user = contact;
      });
    });

    Stream<List<Message>> msgStream =
        twonlyDB.messagesDao.watchAllMessagesFrom(widget.contact.userId);
    messageSub = msgStream.listen((msgs) async {
      // if (!context.mounted) return;
      if (Platform.isAndroid) {
        flutterLocalNotificationsPlugin.cancel(widget.contact.userId);
      } else {
        flutterLocalNotificationsPlugin.cancelAll();
      }
      List<Message> displayedMessages = [];
      // should be cleared
      Map<int, List<Message>> tmpTextReactionsToMessageId = {};
      Map<int, List<Message>> tmpEmojiReactionsToMessageId = {};

      List<int> openedMessageOtherIds = [];

      Map<int, int> messageOtherMessageIdToMyMessageId = {};

      /// there is probably a better way...
      for (Message msg in msgs) {
        if (msg.messageOtherId != null) {
          messageOtherMessageIdToMyMessageId[msg.messageOtherId!] =
              msg.messageId;
        }
      }

      for (Message msg in msgs) {
        if (msg.kind == MessageKind.textMessage &&
            msg.messageOtherId != null &&
            msg.openedAt == null) {
          openedMessageOtherIds.add(msg.messageOtherId!);
        }

        int? responseId = msg.responseToMessageId ??
            messageOtherMessageIdToMyMessageId[msg.responseToOtherMessageId];

        if (responseId != null) {
          bool added = false;
          MessageContent? content =
              MessageContent.fromJson(msg.kind, jsonDecode(msg.contentJson!));
          if (content is TextMessageContent) {
            if (content.text.isNotEmpty && !isEmoji(content.text)) {
              added = true;
              tmpTextReactionsToMessageId
                  .putIfAbsent(responseId, () => [])
                  .add(msg);
            }
          }
          if (!added) {
            tmpEmojiReactionsToMessageId
                .putIfAbsent(responseId, () => [])
                .add(msg);
          }
        } else {
          displayedMessages.add(msg);
        }
      }

      if (openedMessageOtherIds.isNotEmpty) {
        await notifyContactAboutOpeningMessage(
          widget.contact.userId,
          openedMessageOtherIds,
        );
      }

      twonlyDB.messagesDao.openedAllNonMediaMessages(widget.contact.userId);

      setState(() {
        textReactionsToMessageId = tmpTextReactionsToMessageId;
        emojiReactionsToMessageId = tmpEmojiReactionsToMessageId;
        messages = displayedMessages;
      });

      final filteredMediaFiles = displayedMessages
          .where((x) => x.kind == MessageKind.media && x.mediaStored)
          .toList()
          .reversed
          .toList();
      final items = await MemoryItem.convertFromMessages(filteredMediaFiles);
      setState(() {
        galleryItems = items.values.toList();
      });
    });
  }

  Future _sendMessage() async {
    if (newMessageController.text == "") return;
    await sendTextMessage(
      user.userId,
      TextMessageContent(
        text: newMessageController.text,
        responseToMessageId: responseToMessage?.messageOtherId,
        responseToOtherMessageId: responseToMessage?.messageId,
      ),
      (responseToMessage == null) ? PushKind.text : PushKind.response,
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
                      VerifiedShield(key: verifyShieldKey, user),
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
                itemCount: messages.length + 1,
                reverse: true,
                itemExtentBuilder: (index, dimensions) {
                  if (index == 0) return 10; // empty padding
                  index -= 1;
                  double size = 44;
                  if (messages[index].kind == MessageKind.textMessage) {
                    TextMessageContent? content = TextMessageContent.fromJson(
                        jsonDecode(messages[index].contentJson!));
                    if (EmojiAnimation.supported(content.text)) {
                      size = 99;
                    } else {
                      size = 11 +
                          calculateNumberOfLines(content.text,
                                  MediaQuery.of(context).size.width * 0.8, 17) *
                              27;
                    }
                  }
                  if (messages[index].mediaStored) {
                    size = 271;
                  }
                  final reactions =
                      textReactionsToMessageId[messages[index].messageId];
                  if (reactions != null && reactions.isNotEmpty) {
                    for (final reaction in reactions) {
                      if (reaction.kind == MessageKind.textMessage) {
                        TextMessageContent? content =
                            TextMessageContent.fromJson(
                                jsonDecode(reaction.contentJson!));
                        size += calculateNumberOfLines(content.text,
                                MediaQuery.of(context).size.width * 0.5, 14) *
                            27;
                      }
                    }
                  }

                  if (!isLastMessageFromSameUser(messages, index)) {
                    size += 20;
                  }
                  return size;
                },
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Container(); // just a padding
                  }
                  i -= 1;
                  return ChatListEntry(
                    key: Key(messages[i].messageId.toString()),
                    messages[i],
                    user,
                    galleryItems,
                    isLastMessageFromSameUser(messages, i),
                    textReactionsToMessageId[messages[i].messageId] ?? [],
                    emojiReactionsToMessageId[messages[i].messageId] ?? [],
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
            if (responseToMessage != null && !user.deleted)
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
                children: (user.deleted)
                    ? []
                    : [
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

bool isLastMessageFromSameUser(List<Message> messages, int index) {
  if (index <= 0) {
    return true; // If there is no previous message, return true
  }

  final lastMessage = messages[index - 1];
  final currentMessage = messages[index];

  // Check if both messages have the same messageOtherId (or both are null)
  return (lastMessage.messageOtherId == null &&
          currentMessage.messageOtherId == null) ||
      (lastMessage.messageOtherId != null &&
          currentMessage.messageOtherId != null);
}

double calculateNumberOfLines(String text, double width, double fontSize) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout(maxWidth: (width - 30));
  return textPainter.computeLineMetrics().length.toDouble();
}
