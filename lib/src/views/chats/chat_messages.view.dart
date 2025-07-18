import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/protobuf/push_notification/push_notification.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_date_chip.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/response_container.dart';
import 'package:twonly/src/views/components/animate_icon.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/user_context_menu.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/tutorial/tutorials.dart';

Color getMessageColor(Message message) {
  return (message.messageOtherId == null)
      ? const Color.fromARGB(255, 58, 136, 102)
      : const Color.fromARGB(233, 68, 137, 255);
}

class ChatMessage {
  ChatMessage({required this.message, required this.responseTo});
  final Message message;
  final Message? responseTo;
}

class ChatItem {
  const ChatItem._({this.message, this.date, this.time});
  factory ChatItem.date(DateTime date) {
    return ChatItem._(date: date);
  }
  factory ChatItem.time(DateTime time) {
    return ChatItem._(time: time);
  }
  factory ChatItem.message(ChatMessage message) {
    return ChatItem._(message: message);
  }
  final ChatMessage? message;
  final DateTime? date;
  final DateTime? time;
  bool get isMessage => message != null;
  bool get isDate => date != null;
  bool get isTime => time != null;
}

/// Displays detailed information about a SampleItem.
class ChatMessagesView extends StatefulWidget {
  const ChatMessagesView(this.contact, {super.key});

  final Contact contact;

  @override
  State<ChatMessagesView> createState() => _ChatMessagesViewState();
}

class _ChatMessagesViewState extends State<ChatMessagesView>
    with SingleTickerProviderStateMixin {
  TextEditingController newMessageController = TextEditingController();
  HashSet<int> alreadyReportedOpened = HashSet<int>();
  late Contact user;
  String currentInputText = '';
  late StreamSubscription<Contact?> userSub;
  late StreamSubscription<List<Message>> messageSub;
  List<ChatItem> messages = [];
  List<MemoryItem> galleryItems = [];
  Map<int, List<Message>> emojiReactionsToMessageId = {};
  Message? responseToMessage;
  GlobalKey verifyShieldKey = GlobalKey();
  late FocusNode textFieldFocus;
  Timer? tutorial;
  final ItemScrollController itemScrollController = ItemScrollController();
  int? focusedScrollItem;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    user = widget.contact;
    textFieldFocus = FocusNode();
    initStreams();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    tutorial = Timer(const Duration(seconds: 1), () async {
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

  Future<void> initStreams() async {
    await twonlyDB.messagesDao.removeOldMessages();
    final contact = twonlyDB.contactsDao.watchContact(widget.contact.userId);
    userSub = contact.listen((contact) {
      if (contact == null) return;
      setState(() {
        user = contact;
      });
    });

    final msgStream =
        twonlyDB.messagesDao.watchAllMessagesFrom(widget.contact.userId);
    messageSub = msgStream.listen((newMessages) async {
      // if (!context.mounted) return;
      if (Platform.isAndroid) {
        await flutterLocalNotificationsPlugin.cancel(widget.contact.userId);
      } else {
        await flutterLocalNotificationsPlugin.cancelAll();
      }
      final chatItems = <ChatItem>[];
      final storedMediaFiles = <Message>[];
      DateTime? lastDate;
      final tmpEmojiReactionsToMessageId = <int, List<Message>>{};

      final openedMessageOtherIds = <int>[];

      final messageOtherMessageIdToMyMessageId = <int, int>{};
      final messageIdToMessage = <int, Message>{};

      /// there is probably a better way...
      for (final msg in newMessages) {
        if (msg.messageOtherId != null) {
          messageOtherMessageIdToMyMessageId[msg.messageOtherId!] =
              msg.messageId;
        }
        messageIdToMessage[msg.messageId] = msg;
      }

      for (final msg in newMessages) {
        if (msg.kind == MessageKind.textMessage &&
            msg.messageOtherId != null &&
            msg.openedAt == null) {
          openedMessageOtherIds.add(msg.messageOtherId!);
        }

        Message? responseTo;

        if (msg.kind == MessageKind.media && msg.mediaStored) {
          storedMediaFiles.add(msg);
        }

        final responseId = msg.responseToMessageId ??
            messageOtherMessageIdToMyMessageId[msg.responseToOtherMessageId];

        var isReaction = false;
        if (responseId != null) {
          responseTo = messageIdToMessage[responseId];
          final content = MessageContent.fromJson(
            msg.kind,
            jsonDecode(msg.contentJson!) as Map,
          );
          if (content is TextMessageContent) {
            if (isEmoji(content.text)) {
              isReaction = true;
              tmpEmojiReactionsToMessageId
                  .putIfAbsent(responseId, () => [])
                  .add(msg);
            }
          }
          if (msg.kind == MessageKind.reopenedMedia) {
            isReaction = true;
            tmpEmojiReactionsToMessageId
                .putIfAbsent(responseId, () => [])
                .add(msg);
          }
        }
        if (!isReaction) {
          if (lastDate == null ||
              msg.sendAt.day != lastDate.day ||
              msg.sendAt.month != lastDate.month ||
              msg.sendAt.year != lastDate.year) {
            chatItems.add(ChatItem.date(msg.sendAt));
            lastDate = msg.sendAt;
          } else if (msg.sendAt.difference(lastDate).inMinutes >= 20) {
            chatItems.add(ChatItem.time(msg.sendAt));
            lastDate = msg.sendAt;
          }
          chatItems.add(ChatItem.message(ChatMessage(
            message: msg,
            responseTo: responseTo,
          )));
        }
      }

      if (openedMessageOtherIds.isNotEmpty) {
        await notifyContactAboutOpeningMessage(
          widget.contact.userId,
          openedMessageOtherIds,
        );
      }

      await twonlyDB.messagesDao
          .openedAllNonMediaMessages(widget.contact.userId);

      setState(() {
        emojiReactionsToMessageId = tmpEmojiReactionsToMessageId;
        messages = chatItems.reversed.toList();
      });

      final items = await MemoryItem.convertFromMessages(storedMediaFiles);
      galleryItems = items.values.toList();
      setState(() {});
    });
  }

  Future<void> _sendMessage() async {
    if (newMessageController.text == '') return;

    await sendTextMessage(
      user.userId,
      TextMessageContent(
        text: newMessageController.text,
        responseToMessageId: responseToMessage?.messageOtherId,
        responseToOtherMessageId: responseToMessage?.messageId,
      ),
      PushNotification(
        kind: (responseToMessage == null)
            ? PushKind.text
            : (isEmoji(newMessageController.text))
                ? PushKind.reaction
                : PushKind.response,
        reactionContent: (isEmoji(newMessageController.text))
            ? newMessageController.text
            : null,
      ),
    );
    newMessageController.clear();
    currentInputText = '';
    responseToMessage = null;
    setState(() {});
  }

  Future<void> scrollToMessage(int messageId) async {
    final index = messages.indexWhere(
        (x) => x.isMessage && x.message!.message.messageId == messageId);
    if (index == -1) return;
    await itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      alignment: 0.5,
    );
    setState(() {
      focusedScrollItem = index;
      _animationController.forward().then((_) {
        _animationController.reverse().then((_) {
          setState(() {
            _animationController.value = 0.0;
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                const SizedBox(width: 10),
                Expanded(
                  child: ColoredBox(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Text(getContactDisplayName(user)),
                        const SizedBox(width: 10),
                        VerifiedShield(key: verifyShieldKey, user),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: PieCanvas(
          theme: getPieCanvasTheme(context),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ScrollablePositionedList.builder(
                    reverse: true,
                    itemCount: messages.length + 1,
                    itemScrollController: itemScrollController,
                    itemBuilder: (context, i) {
                      if (i == messages.length) {
                        return const Padding(
                          padding: EdgeInsetsGeometry.only(top: 10),
                        );
                      }
                      if (messages[i].isDate || messages[i].isTime) {
                        return ChatDateChip(
                          item: messages[i],
                        );
                      } else {
                        final chatMessage = messages[i].message!;
                        return ScaleTransition(
                          scale: Tween<double>(
                                  begin: 1,
                                  end: (focusedScrollItem == i) ? 1.03 : 1)
                              .animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: ChatListEntry(
                            key: Key(chatMessage.message.messageId.toString()),
                            chatMessage,
                            user,
                            galleryItems,
                            isLastMessageFromSameUser(messages, i),
                            emojiReactionsToMessageId[
                                    chatMessage.message.messageId] ??
                                [],
                            scrollToMessage: scrollToMessage,
                            onResponseTriggered: () {
                              setState(() {
                                responseToMessage = chatMessage.message;
                              });
                              textFieldFocus.requestFocus();
                            },
                          ),
                        );
                      }
                    },
                  ),
                ),
                if (responseToMessage != null && !user.deleted)
                  Container(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ResponsePreview(
                            message: responseToMessage!,
                            showBorder: true,
                            contact: user,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              responseToMessage = null;
                            });
                          },
                          icon: const FaIcon(
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
                                keyboardType: TextInputType.multiline,
                                maxLines: 4,
                                minLines: 1,
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
                            if (currentInputText != '')
                              IconButton(
                                padding: const EdgeInsets.all(15),
                                icon: const FaIcon(
                                    FontAwesomeIcons.solidPaperPlane),
                                onPressed: _sendMessage,
                              )
                            else
                              IconButton(
                                icon: const FaIcon(FontAwesomeIcons.camera),
                                padding: const EdgeInsets.all(15),
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
        ),
      ),
    );
  }
}

bool isLastMessageFromSameUser(List<ChatItem> messages, int index) {
  if (index <= 0) {
    return true; // If there is no previous message, return true
  }

  final lastMessage = messages[index - 1];
  final currentMessage = messages[index];

  if (lastMessage.isMessage && currentMessage.isMessage) {
    // Check if both messages have the same messageOtherId (or both are null)
    return (lastMessage.message!.message.messageOtherId == null &&
            currentMessage.message!.message.messageOtherId == null) ||
        (lastMessage.message!.message.messageOtherId != null &&
            currentMessage.message!.message.messageOtherId != null);
  }
  return false;
}

double calculateNumberOfLines(String text, double width, double fontSize) {
  final textPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: width - 32);
  return textPainter.computeLineMetrics().length.toDouble();
}
