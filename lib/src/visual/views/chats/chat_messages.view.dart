import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/notifications/background.notifications.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/contact_labels.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/themes/colors.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/animated_new_message.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/blink.component.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_group_action.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_date_chip.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/in_chat_group_overview.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_input.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/response_container.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/typing_indicator.dart';

class _MessageAnimationState {
  bool hasReceivedFirstBatch = false;
  final HashSet<String> knownMessageIds = HashSet<String>();
  final HashSet<String> animateMessageIds = HashSet<String>();
}

class _ChatViewData {
  Map<int, Contact> contactsById = {};
  Map<String, MediaFile> mediaFilesById = {};
  Map<String, List<Reaction>> reactionsByMessageId = {};
  Set<String> ackedMessageIds = {};

  List<ChatItem> chatItems = [];
  List<Message> allMessages = [];
  Map<String, Message> messagesById = {};
  List<GroupHistory> groupActions = [];
  List<MemoryItem> galleryItems = [];
  Set<String> galleryMessageIds = {};
}

class _ChatSubscriptions {
  StreamSubscription<Group?>? group;
  StreamSubscription<List<Message>>? messages;
  StreamSubscription<List<GroupHistory>>? groupActions;
  StreamSubscription<List<Contact>>? contacts;
  StreamSubscription<List<MediaFile>>? media;
  StreamSubscription<List<Reaction>>? reactions;
  StreamSubscription<List<MessageAction>>? messageActions;

  void cancelAll() {
    group?.cancel();
    messages?.cancel();
    groupActions?.cancel();
    contacts?.cancel();
    media?.cancel();
    reactions?.cancel();
    messageActions?.cancel();
  }
}

class ChatMessagesView extends StatefulWidget {
  const ChatMessagesView(this.groupId, {super.key});

  final String groupId;

  @override
  State<ChatMessagesView> createState() => _ChatMessagesViewState();
}

class _ChatMessagesViewState extends State<ChatMessagesView>
    with WidgetsBindingObserver {
  HashSet<int> alreadyReportedOpened = HashSet<int>();

  final _animationState = _MessageAnimationState();
  final _subscriptions = _ChatSubscriptions();
  final _data = _ChatViewData();

  Group? _group;
  List<Contact> _groupContacts = [];
  Message? quotesMessage;
  GlobalKey verifyShieldKey = GlobalKey();
  FocusNode? textFieldFocus;
  final ItemScrollController itemScrollController = ItemScrollController();
  int? focusedScrollItem;
  bool _receiverDeletedAccount = false;

  Timer? _nextTypingIndicator;

  @override
  void initState() {
    super.initState();
    textFieldFocus = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    initStreams();
  }

  @override
  void dispose() {
    _subscriptions.cancelAll();
    _nextTypingIndicator?.cancel();
    try {
      textFieldFocus?.dispose();
      // ignore: empty_catches
    } catch (e) {}
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _isViewActive() {
    if (!mounted) return false;
    return !AppState.isAppInBackground &&
        (ModalRoute.of(context)?.isCurrent ?? false);
  }

  Future<void> initStreams() async {
    final groupStream = twonlyDB.groupsDao.watchGroup(widget.groupId);
    _subscriptions.group = groupStream.listen((newGroup) {
      if (newGroup == null) return;
      if (!mounted) return;
      setState(() {
        _group = newGroup;
      });

      if (_subscriptions.groupActions == null) {
        final actionsStream = twonlyDB.groupsDao.watchGroupActions(
          newGroup.groupId,
        );
        _subscriptions.groupActions = actionsStream.listen((update) async {
          _data.groupActions = update;
          await setMessages(_data.allMessages, update);
        });

        final contactsStream = twonlyDB.contactsDao.watchAllContacts();
        _subscriptions.contacts = contactsStream.listen((contacts) {
          final contactMap = <int, Contact>{};
          for (final contact in contacts) {
            contactMap[contact.userId] = contact;
          }
          if (mounted) setState(() => _data.contactsById = contactMap);
        });
      }
    });

    final msgStream = await twonlyDB.messagesDao.watchByGroupId(widget.groupId);
    _subscriptions.messages = msgStream.listen((update) async {
      _data.allMessages = update;
      _data.messagesById = {
        for (final message in update) message.messageId: message,
      };
      await setMessages(update, _data.groupActions);
      _animationState.hasReceivedFirstBatch = true;
    });

    _subscriptions.media = twonlyDB.mediaFilesDao
        .watchMediaFilesForGroup(widget.groupId)
        .listen((mediaFiles) {
          if (!mounted) return;
          setState(
            () => _data.mediaFilesById = {
              for (final mediaFile in mediaFiles) mediaFile.mediaId: mediaFile,
            },
          );
        });
    _subscriptions.reactions = twonlyDB.reactionsDao
        .watchReactionsForGroup(widget.groupId)
        .listen((reactions) {
          if (!mounted) return;
          final byMessage = <String, List<Reaction>>{};
          for (final reaction in reactions) {
            byMessage.putIfAbsent(reaction.messageId, () => []).add(reaction);
          }
          setState(() => _data.reactionsByMessageId = byMessage);
        });
    _subscriptions.messageActions = twonlyDB.messagesDao
        .watchMessageActionsForGroup(widget.groupId)
        .listen((actions) {
          if (!mounted) return;
          setState(
            () => _data.ackedMessageIds = actions
                .where(
                  (action) => action.type == MessageActionType.ackByUserAt,
                )
                .map((action) => action.messageId)
                .toSet(),
          );
        });

    final groupContacts = await twonlyDB.groupsDao.getGroupContact(
      widget.groupId,
    );
    if (mounted) {
      setState(() {
        _groupContacts = groupContacts;
        _receiverDeletedAccount =
            groupContacts.length == 1 && groupContacts.first.accountDeleted;
      });
    }

    if (userService.currentUser.typingIndicators) {
      unawaited(sendTypingIndication(widget.groupId, false));
      _nextTypingIndicator = Timer.periodic(const Duration(seconds: 2), (
        _,
      ) async {
        if (_isViewActive()) {
          await sendTypingIndication(widget.groupId, false);
        }
      });
    }
  }

  Future<void> setMessages(
    List<Message> newMessages,
    List<GroupHistory> groupActions,
  ) async {
    if (_isViewActive()) {
      unawaited(flutterLocalNotificationsPlugin.cancelAll());
    }

    for (final msg in newMessages) {
      if (_animationState.hasReceivedFirstBatch &&
          !_animationState.knownMessageIds.contains(msg.messageId) &&
          msg.senderId == null) {
        _animationState.animateMessageIds.add(msg.messageId);
      }
      _animationState.knownMessageIds.add(msg.messageId);
    }

    final chatItems = <ChatItem>[];
    final storedMediaFiles = <Message>[];

    DateTime? lastDate;

    final openedMessages = <int, List<String>>{};

    var groupHistoryIndex = 0;

    for (final msg in newMessages) {
      if (groupHistoryIndex < groupActions.length) {
        for (; groupHistoryIndex < groupActions.length; groupHistoryIndex++) {
          if (msg.createdAt.isAfter(groupActions[groupHistoryIndex].actionAt)) {
            chatItems.add(
              ChatItem.groupAction(groupActions[groupHistoryIndex]),
            );
            // groupHistoryIndex++;
          } else {
            break;
          }
        }
      }
      if (msg.type != MessageType.media.name &&
          msg.senderId != null &&
          msg.openedAt == null) {
        if (openedMessages[msg.senderId!] == null) {
          openedMessages[msg.senderId!] = [];
        }
        openedMessages[msg.senderId!]!.add(msg.messageId);
      }

      if (msg.type == MessageType.media.name && msg.mediaStored) {
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
    if (groupHistoryIndex < groupActions.length) {
      for (var i = groupHistoryIndex; i < groupActions.length; i++) {
        chatItems.add(ChatItem.groupAction(groupActions[i]));
      }
    }

    if (_isViewActive()) {
      for (final contactId in openedMessages.keys) {
        unawaited(
          notifyContactAboutOpeningMessage(
            contactId,
            openedMessages[contactId]!,
          ),
        );
      }
    }

    final wasSentByMe =
        _animationState.hasReceivedFirstBatch &&
        newMessages.isNotEmpty &&
        newMessages.last.senderId == null;

    if (!mounted) return;
    setState(() {
      _data.chatItems = chatItems.reversed.toList();
    });

    if (wasSentByMe) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !itemScrollController.isAttached) return;
        try {
          unawaited(
            itemScrollController.scrollTo(
              index: 0,
              duration: const Duration(milliseconds: 150),
            ),
          );
        } catch (_) {
          // Ignore if the inner scroll controller is still not attached
        }
      });
    }

    final galleryMessageIds = storedMediaFiles
        .map((message) => message.messageId)
        .toSet();
    if (setEquals(_data.galleryMessageIds, galleryMessageIds)) return;
    final items = await MemoryItem.convertFromMessages(storedMediaFiles);
    if (!mounted) return;
    setState(() {
      _data.galleryMessageIds = galleryMessageIds;
      _data.galleryItems = items.values.toList();
    });
  }

  Future<void> scrollToMessage(String messageId) async {
    final index = _data.chatItems.indexWhere(
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
    if (_group == null) return Container();
    final group = _group!;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: () async {
              if (group.isDirectChat) {
                final member = await twonlyDB.groupsDao.getAllGroupMembers(
                  group.groupId,
                );
                if (!context.mounted) return;
                if (member.isEmpty) return;
                await context.push(
                  Routes.profileContact(member.first.contactId),
                );
              } else {
                await context.push(Routes.profileGroup(group.groupId));
              }
            },
            child: Row(
              children: [
                AvatarIcon(
                  group: group,
                  contacts: _groupContacts,
                  fontSize: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ColoredBox(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(
                              substringBy(group.groupName, 20),
                            ),
                            const SizedBox(width: 5),
                            VerificationBadgeComp(
                              key: verifyShieldKey,
                              group: group,
                            ),
                            const SizedBox(width: 10),
                            FlameCounterWidget(group: group),
                          ],
                        ),
                        if (group.isDirectChat)
                          StreamBuilder<List<Contact>>(
                            stream: twonlyDB.groupsDao.watchGroupContact(
                              group.groupId,
                            ),
                            builder: (context, snapshot) {
                              final contacts = snapshot.data ?? [];
                              if (contacts.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return ContactLabels(
                                contactId: contacts.first.userId,
                              );
                            },
                          ),
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
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ChatMessageActionScope(
                    ackedMessageIds: _data.ackedMessageIds,
                    child: ScrollablePositionedList.builder(
                      reverse: true,
                      itemCount: _data.chatItems.length + 1 + 1,
                      itemScrollController: itemScrollController,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return userService.currentUser.typingIndicators
                              ? TypingIndicator(group: group)
                              : Container();
                        }
                        i -= 1;
                        if (i == _data.chatItems.length) {
                          return Padding(
                            key: Key('overview_${group.groupId}'),
                            padding: const EdgeInsets.only(top: 10),
                            child: InChatGroupOverview(
                              group: group,
                            ),
                          );
                        }
                        if (_data.chatItems[i].isDate) {
                          return ChatDateChip(
                            item: _data.chatItems[i],
                          );
                        } else if (_data.chatItems[i].isGroupAction) {
                          return ChatGroupAction(
                            key: Key(
                              _data.chatItems[i].groupAction!.groupHistoryId,
                            ),
                            action: _data.chatItems[i].groupAction!,
                            contactsById: _data.contactsById,
                          );
                        } else {
                          final chatMessage = _data.chatItems[i].message!;
                          return BlinkWidget(
                            key: Key('blink_${chatMessage.messageId}'),
                            enabled: focusedScrollItem == i,
                            child: AnimatedNewMessage(
                              key: Key('anim_${chatMessage.messageId}'),
                              messageId: chatMessage.messageId,
                              animateIds: _animationState.animateMessageIds,
                              child: ChatListEntry(
                                key: Key(chatMessage.messageId),
                                message: _data.chatItems[i].message!,
                                nextMessage: (i > 0)
                                    ? _data.chatItems[i - 1].message
                                    : null,
                                prevMessage: ((i + 1) < _data.chatItems.length)
                                    ? _data.chatItems[i + 1].message
                                    : null,
                                group: group,
                                galleryItems: _data.galleryItems,
                                userIdToContact: _data.contactsById,
                                mediaFile: chatMessage.mediaId == null
                                    ? null
                                    : _data.mediaFilesById[chatMessage.mediaId],
                                reactions:
                                    _data.reactionsByMessageId[chatMessage
                                        .messageId] ??
                                    const [],
                                messagesById: _data.messagesById,
                                mediaFilesById: _data.mediaFilesById,
                                useSharedData: true,
                                scrollToMessage: scrollToMessage,
                                onResponseTriggered: () {
                                  setState(() {
                                    quotesMessage = chatMessage;
                                  });
                                  textFieldFocus?.requestFocus();
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
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

              if (!group.leftGroup && !_receiverDeletedAccount)
                MessageInput(
                  group: group,
                  quotesMessage: quotesMessage,
                  textFieldFocus: textFieldFocus!,
                  onMessageSend: () {
                    setState(() {
                      quotesMessage = null;
                    });
                  },
                ),
              if (_receiverDeletedAccount)
                Text(context.lang.userDeletedAccount),
            ],
          ),
        ),
      ),
    );
  }
}

Color getMessageColor(bool isOther) {
  return isOther ? DefaultColors.messageSelf : DefaultColors.messageOther;
}

class ChatItem {
  const ChatItem._({
    this.message,
    this.date,
    this.groupAction,
  });
  factory ChatItem.date(DateTime date) {
    return ChatItem._(date: date);
  }
  factory ChatItem.message(Message message) {
    return ChatItem._(message: message);
  }
  factory ChatItem.groupAction(GroupHistory groupAction) {
    return ChatItem._(groupAction: groupAction);
  }
  final GroupHistory? groupAction;
  final Message? message;
  final DateTime? date;
  bool get isMessage => message != null;
  bool get isDate => date != null;
  bool get isGroupAction => groupAction != null;
}
