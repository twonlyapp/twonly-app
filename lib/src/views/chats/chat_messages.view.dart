import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mutex/mutex.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_date_chip.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/response_container.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/groups/group.view.dart';
import 'package:twonly/src/views/tutorial/tutorials.dart';

Color getMessageColor(Message message) {
  return (message.senderId == null)
      ? const Color.fromARGB(255, 58, 136, 102)
      : const Color.fromARGB(233, 68, 137, 255);
}

class ChatItem {
  const ChatItem._({this.message, this.date});
  factory ChatItem.date(DateTime date) {
    return ChatItem._(date: date);
  }
  factory ChatItem.message(Message message) {
    return ChatItem._(message: message);
  }
  final Message? message;
  final DateTime? date;
  bool get isMessage => message != null;
  bool get isDate => date != null;
}

/// Displays detailed information about a SampleItem.
class ChatMessagesView extends StatefulWidget {
  const ChatMessagesView(this.group, {super.key});

  final Group group;

  @override
  State<ChatMessagesView> createState() => _ChatMessagesViewState();
}

class _ChatMessagesViewState extends State<ChatMessagesView> {
  TextEditingController newMessageController = TextEditingController();
  HashSet<int> alreadyReportedOpened = HashSet<int>();
  late Group group;
  String currentInputText = '';
  late StreamSubscription<Group?> userSub;
  late StreamSubscription<List<Message>> messageSub;
  List<ChatItem> messages = [];
  List<MemoryItem> galleryItems = [];
  Message? quotesMessage;
  GlobalKey verifyShieldKey = GlobalKey();
  late FocusNode textFieldFocus;
  Timer? tutorial;
  final ItemScrollController itemScrollController = ItemScrollController();
  int? focusedScrollItem;

  @override
  void initState() {
    super.initState();
    group = widget.group;
    textFieldFocus = FocusNode();
    initStreams();

    tutorial = Timer(const Duration(seconds: 1), () async {
      tutorial = null;
      if (!mounted) return;
      await showVerifyShieldTutorial(context, verifyShieldKey);
    });
  }

  @override
  void dispose() {
    userSub.cancel();
    messageSub.cancel();
    tutorial?.cancel();
    textFieldFocus.dispose();
    super.dispose();
  }

  Mutex protectMessageUpdating = Mutex();

  Future<void> initStreams() async {
    final groupStream = twonlyDB.groupsDao.watchGroup(group.groupId);
    userSub = groupStream.listen((newGroup) {
      if (newGroup == null) return;
      setState(() {
        group = newGroup;
      });
    });

    final msgStream = twonlyDB.messagesDao.watchByGroupId(group.groupId);
    messageSub = msgStream.listen((newMessages) async {
      /// In case a message is not open yet the message is updated, which will trigger this watch to be called again.
      /// So as long as the Mutex is locked just return...
      if (protectMessageUpdating.isLocked) {
        return;
      }
      await protectMessageUpdating.protect(() async {
        await flutterLocalNotificationsPlugin.cancelAll();

        final chatItems = <ChatItem>[];
        final storedMediaFiles = <Message>[];

        DateTime? lastDate;

        final openedMessages = <int, List<String>>{};

        for (final msg in newMessages) {
          if (msg.type == MessageType.text &&
              msg.senderId != null &&
              msg.openedAt == null) {
            if (openedMessages[msg.senderId!] == null) {
              openedMessages[msg.senderId!] = [];
            }
            openedMessages[msg.senderId!]!.add(msg.messageId);
          }

          if (msg.type == MessageType.media && msg.mediaStored) {
            storedMediaFiles.add(msg);
          }

          if (lastDate == null ||
              msg.createdAt.day != lastDate.day ||
              msg.createdAt.month != lastDate.month ||
              msg.createdAt.year != lastDate.year) {
            chatItems.add(ChatItem.date(msg.createdAt));
            lastDate = msg.createdAt;
          }
          chatItems.add(ChatItem.message(msg));
        }

        for (final contactId in openedMessages.keys) {
          await notifyContactAboutOpeningMessage(
            contactId,
            openedMessages[contactId]!,
          );
        }

        if (!mounted) return;
        setState(() {
          messages = chatItems.reversed.toList();
        });

        final items = await MemoryItem.convertFromMessages(storedMediaFiles);
        galleryItems = items.values.toList();
        setState(() {});
      });
    });
  }

  Future<void> _sendMessage() async {
    if (newMessageController.text == '') return;

    await insertAndSendTextMessage(
      group.groupId,
      newMessageController.text,
      quotesMessage?.messageId,
    );

    newMessageController.clear();
    currentInputText = '';
    quotesMessage = null;
    setState(() {});
  }

  Future<void> scrollToMessage(String messageId) async {
    final index = messages.indexWhere(
      (x) => x.isMessage && x.message!.messageId == messageId,
    );
    if (index == -1) return;
    setState(() {
      focusedScrollItem = index;
    });
    await itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      alignment: 0.5,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!context.mounted) return;
      setState(() {
        focusedScrollItem = null;
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
            onTap: () async {
              if (widget.group.isDirectChat) {
                final member = await twonlyDB.groupsDao
                    .getGroupMembers(widget.group.groupId);
                if (!context.mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ContactView(member.first.contactId);
                    },
                  ),
                );
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return GroupView(widget.group);
                    },
                  ),
                );
              }
            },
            child: Row(
              children: [
                AvatarIcon(
                  group: group,
                  fontSize: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ColoredBox(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Text(group.groupName),
                        const SizedBox(width: 10),
                        // if (group.verified)
                        //   VerifiedShield(key: verifyShieldKey, group),
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
                      if (messages[i].isDate) {
                        return ChatDateChip(
                          item: messages[i],
                        );
                      } else {
                        final chatMessage = messages[i].message!;
                        return Transform.translate(
                          offset: Offset(
                            (focusedScrollItem == i)
                                ? (chatMessage.senderId == null)
                                    ? -8
                                    : 8
                                : 0,
                            0,
                          ),
                          child: Transform.scale(
                            scale: (focusedScrollItem == i) ? 1.05 : 1,
                            child: ChatListEntry(
                              key: Key(chatMessage.messageId),
                              message: messages[i].message!,
                              nextMessage:
                                  (i > 0) ? messages[i - 1].message : null,
                              prevMessage: ((i + 1) < messages.length)
                                  ? messages[i + 1].message
                                  : null,
                              group: group,
                              galleryItems: galleryItems,
                              scrollToMessage: scrollToMessage,
                              onResponseTriggered: () {
                                setState(() {
                                  quotesMessage = chatMessage;
                                });
                                textFieldFocus.requestFocus();
                              },
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                if (quotesMessage != null)
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
                            message: quotesMessage,
                            showBorder: true,
                            group: group,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              quotesMessage = null;
                            });
                          },
                          icon: const FaIcon(
                            FontAwesomeIcons.xmark,
                            size: 16,
                          ),
                        ),
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
                            FontAwesomeIcons.solidPaperPlane,
                          ),
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
                                  return CameraSendToView(widget.group);
                                },
                              ),
                            );
                          },
                        ),
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
