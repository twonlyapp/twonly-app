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
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
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
  final HashSet<String> reportedOpenedMessageIds = HashSet<String>();
}

class _ChatViewData {
  Map<int, Contact> contactsById = {};
  Map<String, MediaFile> mediaFilesById = {};
  Map<String, List<Reaction>> reactionsByMessageId = {};
  Set<String> ackedMessageIds = {};

  List<ChatItem> chatItems = [];
  List<Message> allMessages = [];
  List<Message> latestMessages = [];
  List<Message> olderMessages = [];
  Map<String, Message> messagesById = {};
  List<GroupHistory> groupActions = [];
  List<MemoryItem> galleryItems = [];
  Set<String> galleryMessageIds = {};
  Set<String> watchedMessageIds = {};
  Set<int> watchedContactIds = {};
  DateTime? watchedGroupActionsSince;
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
  static const _messagePageSize = 100;

  final _animationState = _MessageAnimationState();
  final _subscriptions = _ChatSubscriptions();
  final _data = _ChatViewData();
  final ValueNotifier<int> _messageDataVersion = ValueNotifier(0);

  Group? _group;
  List<Contact> _groupContacts = [];
  Message? quotesMessage;
  GlobalKey verifyShieldKey = GlobalKey();
  FocusNode? textFieldFocus;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  int? focusedScrollItem;
  bool _receiverDeletedAccount = false;
  Future<void>? _olderMessagesLoad;
  bool _hasMoreMessages = true;

  Timer? _nextTypingIndicator;

  /// Set by the composer while it is announcing that the user is typing.
  final ValueNotifier<bool> _composing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    textFieldFocus = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    itemPositionsListener.itemPositions.addListener(_loadOlderWhenNeeded);
    // Opening a conversation acknowledges everything it has pending, including
    // the events that survive `notifyMessagesOpened` such as reactions and
    // media status updates. Without this they keep inflating the app badge.
    unawaited(NativeNotificationService.clearConversation(widget.groupId));
    initStreams();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state != AppLifecycleState.resumed) return;
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    // Notifications that arrived while this chat sat in the background are
    // acknowledged as soon as the user looks at it again.
    unawaited(NativeNotificationService.clearConversation(widget.groupId));
  }

  @override
  void dispose() {
    _subscriptions.cancelAll();
    _messageDataVersion.dispose();
    itemPositionsListener.itemPositions.removeListener(_loadOlderWhenNeeded);
    _nextTypingIndicator?.cancel();
    _composing.dispose();
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

  void _notifyMessageDataChanged() {
    _messageDataVersion.value++;
  }

  Future<void> initStreams() async {
    final groupStream = twonlyDB.groupsDao.watchGroup(widget.groupId);
    _subscriptions.group = groupStream.listen((newGroup) {
      if (newGroup == null) return;
      if (!mounted) return;
      setState(() {
        _group = newGroup;
      });
    });

    final msgStream = await twonlyDB.messagesDao.watchByGroupId(widget.groupId);
    _subscriptions.messages = msgStream.listen((update) async {
      _data.latestMessages = update;
      if (_data.olderMessages.isEmpty) {
        _hasMoreMessages = update.length == _messagePageSize;
      }
      await _applyLoadedMessages(reportOpened: true);
      _animationState.hasReceivedFirstBatch = true;
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
      _watchRelevantContacts();
    }

    if (userService.currentUser.typingIndicators) {
      unawaited(RustApi.sendTyping(groupId: widget.groupId, isTyping: false));
      _nextTypingIndicator = Timer.periodic(chatOpenPingInterval, (_) async {
        // A typing announcement refreshes the contact's chat-open state as
        // well, so pinging while the composer is active would spend a second
        // message only to clear the typing flag that composer just set.
        if (_isViewActive() && !_composing.value) {
          await RustApi.sendTyping(groupId: widget.groupId, isTyping: false);
        }
      });
    }
  }

  Future<void> _applyLoadedMessages({required bool reportOpened}) async {
    final byId = <String, Message>{
      for (final message in _data.olderMessages) message.messageId: message,
      for (final message in _data.latestMessages) message.messageId: message,
    };
    final loadedMessages = byId.values.toList()
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.messageId.compareTo(b.messageId);
      });
    _data.allMessages = loadedMessages;
    _data.messagesById = byId;
    _watchGroupActionsForLoadedRange();
    _watchLoadedMessageData();
    _watchRelevantContacts();
    await setMessages(
      loadedMessages,
      _data.groupActions,
      reportOpened: reportOpened,
    );
  }

  void _watchGroupActionsForLoadedRange() {
    final since = _data.allMessages.firstOrNull?.createdAt;
    if (_subscriptions.groupActions != null &&
        _data.watchedGroupActionsSince == since) {
      return;
    }
    _data.watchedGroupActionsSince = since;
    unawaited(_subscriptions.groupActions?.cancel());
    _subscriptions.groupActions = twonlyDB.groupsDao
        .watchGroupActions(widget.groupId, since: since)
        .listen((actions) async {
          _data.groupActions = actions;
          _watchRelevantContacts();
          await setMessages(_data.allMessages, actions);
        });
  }

  void _loadOlderWhenNeeded() {
    if (_olderMessagesLoad != null || !_hasMoreMessages) return;
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;
    final oldestVisibleIndex = positions
        .map((position) => position.index)
        .reduce((a, b) => a > b ? a : b);
    if (oldestVisibleIndex >= _data.chatItems.length - 10) {
      unawaited(_loadOlderMessages());
    }
  }

  Future<void> _loadOlderMessages() async {
    if (_olderMessagesLoad case final pending?) return pending;
    if (!_hasMoreMessages) return;
    final load = _performLoadOlderMessages();
    _olderMessagesLoad = load;
    try {
      await load;
    } finally {
      _olderMessagesLoad = null;
    }
  }

  Future<void> _performLoadOlderMessages() async {
    final oldestMessage = _data.allMessages.firstOrNull;
    if (oldestMessage == null) return;
    final older = await twonlyDB.messagesDao.getMessagesBefore(
      widget.groupId,
      oldestMessage.createdAt,
      beforeMessageId: oldestMessage.messageId,
    );
    _hasMoreMessages = older.length == _messagePageSize;
    _data.olderMessages = [...older, ..._data.olderMessages];
    await _applyLoadedMessages(reportOpened: true);
  }

  void _watchLoadedMessageData() {
    final messageIds = _data.messagesById.keys.toSet();
    if (setEquals(_data.watchedMessageIds, messageIds)) return;
    _data.watchedMessageIds = messageIds;

    unawaited(_subscriptions.media?.cancel());
    unawaited(_subscriptions.reactions?.cancel());
    unawaited(_subscriptions.messageActions?.cancel());

    final mediaIds = _data.allMessages
        .map((message) => message.mediaId)
        .whereType<String>()
        .toSet();
    _subscriptions.media = twonlyDB.mediaFilesDao
        .watchMediaFilesByIds(mediaIds)
        .listen((mediaFiles) {
          if (!mounted) return;
          _data.mediaFilesById = {
            for (final mediaFile in mediaFiles) mediaFile.mediaId: mediaFile,
          };
          _notifyMessageDataChanged();
          _updateGalleryItems(force: true);
        });
    _subscriptions.reactions = twonlyDB.reactionsDao
        .watchReactionsForMessages(messageIds)
        .listen((reactions) {
          if (!mounted) return;
          final byMessage = <String, List<Reaction>>{};
          for (final reaction in reactions) {
            byMessage.putIfAbsent(reaction.messageId, () => []).add(reaction);
          }
          _data.reactionsByMessageId = byMessage;
          _notifyMessageDataChanged();
        });
    _subscriptions.messageActions = twonlyDB.messagesDao
        .watchAcknowledgementsForMessages(messageIds)
        .listen((actions) {
          if (!mounted) return;
          _data.ackedMessageIds = actions
              .map((action) => action.messageId)
              .toSet();
          _notifyMessageDataChanged();
        });
  }

  void _watchRelevantContacts() {
    final contactIds = <int>{
      ..._groupContacts.map((contact) => contact.userId),
      ..._data.allMessages.map((message) => message.senderId).whereType<int>(),
      ..._data.groupActions
          .expand((action) => [action.contactId, action.affectedContactId])
          .whereType<int>(),
      ..._referencedContactIds(),
    };
    if (setEquals(_data.watchedContactIds, contactIds)) return;
    _data.watchedContactIds = contactIds;
    unawaited(_subscriptions.contacts?.cancel());
    _subscriptions.contacts = twonlyDB.contactsDao
        .watchContactsByIds(contactIds)
        .listen((contacts) {
          if (!mounted) return;
          _data.contactsById = {
            for (final contact in contacts) contact.userId: contact,
          };
          _notifyMessageDataChanged();
        });
  }

  Iterable<int> _referencedContactIds() sync* {
    for (final message in _data.allMessages) {
      final bytes = message.additionalMessageData;
      if (bytes == null) continue;
      try {
        final data = AdditionalMessageData.fromBuffer(bytes);
        if (data.hasAskAboutUserId()) yield data.askAboutUserId.toInt();
        for (final contact in data.contacts) {
          yield contact.userId.toInt();
        }
      } catch (_) {
        // Invalid additional data is handled by the corresponding bubble.
      }
    }
  }

  Future<void> setMessages(
    List<Message> newMessages,
    List<GroupHistory> groupActions, {
    bool reportOpened = false,
  }) async {
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
    final oldestLoadedAt = newMessages.firstOrNull?.createdAt;
    final visibleGroupActions = oldestLoadedAt == null
        ? groupActions
        : groupActions
              .where((action) => !action.actionAt.isBefore(oldestLoadedAt))
              .toList();

    DateTime? lastDate;

    final openedMessages = <int, List<String>>{};

    var groupHistoryIndex = 0;

    for (final msg in newMessages) {
      if (groupHistoryIndex < visibleGroupActions.length) {
        for (
          ;
          groupHistoryIndex < visibleGroupActions.length;
          groupHistoryIndex++
        ) {
          if (msg.createdAt.isAfter(
            visibleGroupActions[groupHistoryIndex].actionAt,
          )) {
            chatItems.add(
              ChatItem.groupAction(visibleGroupActions[groupHistoryIndex]),
            );
            // groupHistoryIndex++;
          } else {
            break;
          }
        }
      }
      if (msg.type != MessageType.media.name &&
          msg.senderId != null &&
          msg.openedAt == null &&
          !_animationState.reportedOpenedMessageIds.contains(msg.messageId)) {
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
    if (groupHistoryIndex < visibleGroupActions.length) {
      for (var i = groupHistoryIndex; i < visibleGroupActions.length; i++) {
        chatItems.add(ChatItem.groupAction(visibleGroupActions[i]));
      }
    }

    if (reportOpened && _isViewActive()) {
      for (final contactId in openedMessages.keys) {
        _animationState.reportedOpenedMessageIds.addAll(
          openedMessages[contactId]!,
        );
        unawaited(_reportMessagesOpened(contactId, openedMessages[contactId]!));
      }
    }

    final wasSentByMe =
        _animationState.hasReceivedFirstBatch &&
        newMessages.isNotEmpty &&
        newMessages.last.senderId == null;

    if (!mounted) return;
    _data.chatItems = chatItems.reversed.toList();
    _notifyMessageDataChanged();

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

    _updateGalleryItems(messages: storedMediaFiles);
  }

  Future<void> _reportMessagesOpened(
    int contactId,
    List<String> messageIds,
  ) async {
    // Cancel once immediately for an already visible alert, and once after the
    // durable outbox update to close the small race with a native push worker.
    await NativeNotificationService.cancelNotifications(messageIds);
    try {
      await RustApi.notifyMessagesOpened(
        contactId: contactId,
        messageIds: messageIds,
      );
    } finally {
      await NativeNotificationService.cancelNotifications(messageIds);
    }
  }

  void _updateGalleryItems({List<Message>? messages, bool force = false}) {
    final storedMediaMessages =
        messages ??
        _data.allMessages
            .where(
              (message) =>
                  message.type == MessageType.media.name && message.mediaStored,
            )
            .toList();
    final messageIds = storedMediaMessages
        .map((message) => message.messageId)
        .toSet();
    if (!force && setEquals(_data.galleryMessageIds, messageIds)) return;

    final items = <String, MemoryItem>{};
    for (final message in storedMediaMessages) {
      final mediaFile = _data.mediaFilesById[message.mediaId];
      if (mediaFile == null) continue;
      final mediaService = MediaFileService(mediaFile);
      if (!mediaService.imagePreviewAvailable) continue;
      items
          .putIfAbsent(
            mediaFile.mediaId,
            () => MemoryItem(mediaService: mediaService, messages: []),
          )
          .messages
          .add(message);
    }
    if (!mounted) return;
    _data.galleryMessageIds = messageIds;
    _data.galleryItems = items.values.toList();
    _notifyMessageDataChanged();
  }

  Future<void> scrollToMessage(String messageId) async {
    var index = _data.chatItems.indexWhere(
      (x) => x.isMessage && x.message!.messageId == messageId,
    );
    while (index == -1 && _hasMoreMessages) {
      await _loadOlderMessages();
      index = _data.chatItems.indexWhere(
        (item) => item.isMessage && item.message!.messageId == messageId,
      );
    }
    if (index == -1) return;
    focusedScrollItem = index;
    _notifyMessageDataChanged();
    await itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      alignment: 0.5,
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!context.mounted) return;
      focusedScrollItem = null;
      _notifyMessageDataChanged();
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
                        if (group.isDirectChat && _groupContacts.isNotEmpty)
                          ContactLabels(
                            contactId: _groupContacts.first.userId,
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
                child: ValueListenableBuilder<int>(
                  valueListenable: _messageDataVersion,
                  builder: (context, _, _) => Align(
                    alignment: Alignment.topCenter,
                    child: ChatMessageActionScope(
                      ackedMessageIds: _data.ackedMessageIds,
                      child: ScrollablePositionedList.builder(
                        reverse: true,
                        itemCount: _data.chatItems.length + 1 + 1,
                        itemScrollController: itemScrollController,
                        itemPositionsListener: itemPositionsListener,
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
                                  prevMessage:
                                      ((i + 1) < _data.chatItems.length)
                                      ? _data.chatItems[i + 1].message
                                      : null,
                                  group: group,
                                  galleryItems: _data.galleryItems,
                                  userIdToContact: _data.contactsById,
                                  mediaFile: chatMessage.mediaId == null
                                      ? null
                                      : _data.mediaFilesById[chatMessage
                                            .mediaId],
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
                  composing: _composing,
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
