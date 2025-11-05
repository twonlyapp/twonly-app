import 'dart:async';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mutex/mutex.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_date_chip.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_group_action.dart';
import 'package:twonly/src/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/views/chats/chat_messages_components/message_input.dart';
import 'package:twonly/src/views/chats/chat_messages_components/response_container.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/groups/group.view.dart';
import 'package:twonly/src/views/tutorial/tutorials.dart';

Color getMessageColor(Message message) {
  return (message.senderId == null)
      ? const Color.fromARGB(255, 58, 136, 102)
      : const Color.fromARGB(233, 68, 137, 255);
}

class ChatItem {
  const ChatItem._({
    this.message,
    this.date,
    this.lastOpenedPosition,
    this.groupAction,
  });
  factory ChatItem.date(DateTime date) {
    return ChatItem._(date: date);
  }
  factory ChatItem.message(Message message) {
    return ChatItem._(message: message);
  }
  factory ChatItem.lastOpenedPosition(List<Contact> contacts) {
    return ChatItem._(lastOpenedPosition: contacts);
  }
  factory ChatItem.groupAction(GroupHistory groupAction) {
    return ChatItem._(groupAction: groupAction);
  }
  final GroupHistory? groupAction;
  final Message? message;
  final DateTime? date;
  final List<Contact>? lastOpenedPosition;
  bool get isMessage => message != null;
  bool get isDate => date != null;
  bool get isGroupAction => groupAction != null;
  bool get isLastOpenedPosition => lastOpenedPosition != null;
}

/// Displays detailed information about a SampleItem.
class ChatMessagesView extends StatefulWidget {
  const ChatMessagesView(this.group, {super.key});

  final Group group;

  @override
  State<ChatMessagesView> createState() => _ChatMessagesViewState();
}

class _ChatMessagesViewState extends State<ChatMessagesView> {
  HashSet<int> alreadyReportedOpened = HashSet<int>();
  late Group group;
  late StreamSubscription<Group?> userSub;
  late StreamSubscription<List<Message>> messageSub;
  StreamSubscription<List<GroupHistory>>? groupActionsSub;
  StreamSubscription<List<Contact>>? contactSub;
  StreamSubscription<Future<List<(Message, Contact)>>>?
      lastOpenedMessageByContactSub;

  Map<int, Contact> userIdToContact = {};

  List<ChatItem> messages = [];
  List<Message> allMessages = [];
  List<(Message, Contact)> lastOpenedMessageByContact = [];
  List<GroupHistory> groupActions = [];
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
    contactSub?.cancel();
    groupActionsSub?.cancel();
    lastOpenedMessageByContactSub?.cancel();
    tutorial?.cancel();
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

    if (!widget.group.isDirectChat) {
      final lastOpenedStream =
          twonlyDB.messagesDao.watchLastOpenedMessagePerContact(group.groupId);
      lastOpenedMessageByContactSub =
          lastOpenedStream.listen((lastActionsFuture) async {
        final update = await lastActionsFuture;
        lastOpenedMessageByContact = update;
        await setMessages(allMessages, update, groupActions);
      });

      final actionsStream = twonlyDB.groupsDao.watchGroupActions(group.groupId);
      groupActionsSub = actionsStream.listen((update) async {
        groupActions = update;
        await setMessages(allMessages, lastOpenedMessageByContact, update);
      });

      final contactsStream = twonlyDB.contactsDao.watchAllContacts();
      contactSub = contactsStream.listen((contacts) {
        for (final contact in contacts) {
          userIdToContact[contact.userId] = contact;
        }
      });
    }

    final msgStream = twonlyDB.messagesDao.watchByGroupId(group.groupId);
    messageSub = msgStream.listen((update) async {
      allMessages = update;

      /// In case a message is not open yet the message is updated, which will trigger this watch to be called again.
      /// So as long as the Mutex is locked just return...
      if (protectMessageUpdating.isLocked) {
        // return;
      }
      await protectMessageUpdating.protect(() async {
        await setMessages(update, lastOpenedMessageByContact, groupActions);
      });
    });
  }

  Future<void> setMessages(
    List<Message> newMessages,
    List<(Message, Contact)> lastOpenedMessageByContact,
    List<GroupHistory> groupActions,
  ) async {
    await flutterLocalNotificationsPlugin.cancelAll();

    final chatItems = <ChatItem>[];
    final storedMediaFiles = <Message>[];

    DateTime? lastDate;

    final openedMessages = <int, List<String>>{};
    final lastOpenedMessageToContact = <String, List<Contact>>{};

    final myLastMessageIndex =
        newMessages.lastIndexWhere((t) => t.senderId == null);

    for (final opened in lastOpenedMessageByContact) {
      if (!lastOpenedMessageToContact.containsKey(opened.$1.messageId)) {
        lastOpenedMessageToContact[opened.$1.messageId] = [opened.$2];
      } else {
        lastOpenedMessageToContact[opened.$1.messageId]!.add(opened.$2);
      }
    }
    var index = 0;
    var groupHistoryIndex = 0;

    for (final msg in newMessages) {
      if (groupHistoryIndex < groupActions.length) {
        for (; groupHistoryIndex < groupActions.length; groupHistoryIndex++) {
          if (msg.createdAt.isAfter(groupActions[groupHistoryIndex].actionAt)) {
            chatItems
                .add(ChatItem.groupAction(groupActions[groupHistoryIndex]));
            // groupHistoryIndex++;
          } else {
            break;
          }
        }
      }
      index += 1;
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

      if (index <= myLastMessageIndex || index == newMessages.length) {
        if (lastOpenedMessageToContact.containsKey(msg.messageId)) {
          chatItems.add(
            ChatItem.lastOpenedPosition(
              lastOpenedMessageToContact[msg.messageId]!,
            ),
          );
        }
      }
    }
    if (groupHistoryIndex < groupActions.length) {
      for (var i = groupHistoryIndex; i < groupActions.length; i++) {
        chatItems.add(ChatItem.groupAction(groupActions[i]));
      }
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
              if (group.isDirectChat) {
                final member =
                    await twonlyDB.groupsDao.getAllGroupMembers(group.groupId);
                if (!context.mounted) return;
                if (member.isEmpty) return;
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
                      return GroupView(group);
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
                        Text(
                          substringBy(group.groupName, 20),
                        ),
                        const SizedBox(width: 10),
                        VerifiedShield(key: verifyShieldKey, group: group),
                        const SizedBox(width: 10),
                        FlameCounterWidget(groupId: group.groupId),
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
                    } else if (messages[i].isLastOpenedPosition) {
                      return Wrap(
                        spacing: 8,
                        alignment: WrapAlignment.center,
                        children: messages[i].lastOpenedPosition!.map((w) {
                          return AvatarIcon(
                            contactId: w.userId,
                            fontSize: 12,
                          );
                        }).toList(),
                      );
                    } else if (messages[i].isGroupAction) {
                      return ChatGroupAction(
                        key: Key(messages[i].groupAction!.groupHistoryId),
                        action: messages[i].groupAction!,
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
                            userIdToContact: userIdToContact,
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
              if (!group.leftGroup)
                MessageInput(
                  group: group,
                  quotesMessage: quotesMessage,
                  textFieldFocus: textFieldFocus,
                  onMessageSend: () {
                    setState(() {
                      quotesMessage = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
