import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show listEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/bridge/database/reactions.dart' as rust_reactions;
import 'package:twonly/core/bridge/database/stickers.dart' as rust_stickers;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart' as db_messages;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/reactions/table.dart';
import 'package:twonly/core/database/app/stickers/table.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/model/message_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/notifications/native.notifications.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/mentions.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/contact_groups.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_components/chat_body_safe_area.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/animated_new_message.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/blink.component.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_group_action.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_list_entry.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/chat_notification_listener.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/chat_date_chip.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/entries/friendly_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/game_chat_messages.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/in_chat_group_overview.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_input.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/pending_chat_messages.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/response_container.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/typing_indicator.dart';

class _MessageAnimationState {
  bool hasReceivedFirstBatch = false;
  DateTime? newestKnownAt;
  final HashSet<String> knownMessageIds = HashSet<String>();
  final HashSet<String> animateMessageIds = HashSet<String>();
  final HashSet<String> reportedOpenedMessageIds = HashSet<String>();
}

class _ChatViewData {
  Map<int, Contact> contactsById = {};
  Map<String, MediaFile> mediaFilesById = {};
  Map<String, List<StoredReaction>> reactionsByMessageId = {};
  Set<String> ackedMessageIds = {};
  Set<String> failedMessageIds = {};

  List<ChatItem> chatItems = [];
  List<StoredMessage> allMessages = [];
  List<StoredMessage> latestMessages = [];
  List<StoredMessage> olderMessages = [];
  Map<String, StoredMessage> messagesById = {};
  List<GroupHistory> groupActions = [];
  List<MemoryItem> galleryItems = [];
  Set<String> galleryMessageIds = {};
  Set<String> watchedMessageIds = {};
  Set<int> watchedContactIds = {};
  DateTime? watchedGroupActionsSince;
}

class _ChatSubscriptions {
  StreamSubscription<Group?>? group;
  StreamSubscription<List<StoredMessage>>? messages;
  StreamSubscription<List<GroupHistory>>? groupActions;
  StreamSubscription<List<Contact>>? contacts;
  StreamSubscription<List<MediaFile>>? media;
  StreamSubscription<List<StoredReaction>>? reactions;
  StreamSubscription<List<MessageAction>>? messageActions;

  Future<void> cancelAll() async {
    final pending = <Future<void>>[
      if (group != null) group!.cancel(),
      if (messages != null) messages!.cancel(),
      if (groupActions != null) groupActions!.cancel(),
      if (contacts != null) contacts!.cancel(),
      if (media != null) media!.cancel(),
      if (reactions != null) reactions!.cancel(),
      if (messageActions != null) messageActions!.cancel(),
    ];
    group = null;
    messages = null;
    groupActions = null;
    contacts = null;
    media = null;
    reactions = null;
    messageActions = null;
    await Future.wait(pending);
  }
}

class ChatMessagesView extends StatefulWidget {
  const ChatMessagesView(this.groupId, {this.initialGroup, super.key});

  final String groupId;

  /// Handed over by the caller when it already holds the row, so the first
  /// frame can draw the real chat instead of waiting for the group stream.
  final Group? initialGroup;

  @override
  State<ChatMessagesView> createState() => _ChatMessagesViewState();
}

class _ChatMessagesViewState extends State<ChatMessagesView> {
  static const _messagePageSize = 100;

  final _animationState = _MessageAnimationState();
  final _subscriptions = _ChatSubscriptions();
  final _data = _ChatViewData();
  final _pendingMessages = PendingChatMessages();
  final ValueNotifier<int> _messageDataVersion = ValueNotifier(0);

  int _chatLoadGeneration = 0;
  bool _loadingMessages = true;
  bool _chatLoadFailed = false;
  Group? _group;
  List<Contact> _groupContacts = [];
  StoredMessage? quotesMessage;
  GlobalKey verifyShieldKey = GlobalKey();
  FocusNode? textFieldFocus;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  int? focusedScrollItem;
  bool _receiverDeletedAccount = false;
  ChatInputPanel _inputPanel = ChatInputPanel.none;
  Future<void>? _olderMessagesLoad;
  bool _hasMoreMessages = true;
  int _loadedMessagesRevision = 0;

  Timer? _nextTypingIndicator;

  /// Set by the composer while it is announcing that the user is typing.
  final ValueNotifier<bool> _composing = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
    textFieldFocus = FocusNode();
    itemPositionsListener.itemPositions.addListener(_loadOlderWhenNeeded);
    unawaited(initStreams());
  }

  @override
  void dispose() {
    _chatLoadGeneration++;
    _loadedMessagesRevision++;
    unawaited(_subscriptions.cancelAll());
    _messageDataVersion.dispose();
    itemPositionsListener.itemPositions.removeListener(_loadOlderWhenNeeded);
    _nextTypingIndicator?.cancel();
    _composing.dispose();
    if (userService.currentUser.typingIndicators) {
      unawaitedRustCall(
        RustApi.sendChatClosed(groupId: widget.groupId),
        'sendChatClosed',
      );
    }
    try {
      textFieldFocus?.dispose();
      // ignore: empty_catches
    } catch (e) {}
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

  void _sendMessage({
    required String text,
    String? quoteMessageId,
    LocalSticker? sticker,
  }) {
    final message = _pendingMessages.add(
      groupId: widget.groupId,
      text: text,
      quoteMessageId: quoteMessageId,
      additionalMessageData: sticker == null
          ? null
          : StickerService.encodeAdditional(sticker),
    );
    _animationState.animateMessageIds.add(message.messageId);
    setState(() => quotesMessage = null);
    _showPendingMessages();
    unawaited(_persistOutgoingMessage(message, sticker));
  }

  void _showPendingMessages() {
    final messages = _pendingMessages.merge([
      ..._data.olderMessages,
      ..._data.latestMessages,
    ]);
    _data.allMessages = messages;
    _data.messagesById = {
      for (final message in messages) message.messageId: message,
    };
    // setMessages publishes synchronously; it does not wait for database work.
    unawaited(setMessages(messages, _data.groupActions));
  }

  Future<void> _persistOutgoingMessage(
    StoredMessage message,
    LocalSticker? sticker,
  ) async {
    try {
      await RustApi.insertAndSendText(
        groupId: message.groupId,
        text: message.content!,
        quoteMessageId: message.quotesMessageId,
        additionalMessageData: message.additionalMessageData,
        messageId: message.messageId,
        timestampMs: message.createdAt.millisecondsSinceEpoch,
      );
    } catch (error, stackTrace) {
      Log.error(
        'Could not persist outgoing message',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted || !_pendingMessages.remove(message.messageId)) return;
      _showPendingMessages();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.lang.errorInternalError),
          action: SnackBarAction(
            label: context.lang.manualVerificationRetry,
            onPressed: () {
              if (!mounted) return;
              _pendingMessages.track(message);
              _showPendingMessages();
              unawaited(_persistOutgoingMessage(message, sticker));
            },
          ),
        ),
      );
      return;
    }
    // A completed bridge call does not mean the database stream has emitted.
    // Keep the bubble until the corresponding stored row replaces it.
    if (sticker != null) {
      unawaitedRustCall(
        rust_stickers.recordStickerUse(
          hash: sticker.contentHash,
          transaction: currentDatabaseSession(),
        ),
        'recordStickerUse',
      );
    }
  }

  void _chatLoadingFailed(Object error, [StackTrace? stackTrace]) {
    Log.error(
      'Could not load conversation ${widget.groupId}',
      error: error,
      stackTrace: stackTrace,
    );
    if (!mounted) return;
    setState(() {
      _chatLoadFailed = true;
      _loadingMessages = false;
    });
  }

  Future<void> _retryChatLoading() async {
    _chatLoadGeneration++;
    _loadedMessagesRevision++;
    setState(() {
      _chatLoadFailed = false;
      _loadingMessages = _data.allMessages.isEmpty;
    });
    _nextTypingIndicator?.cancel();
    await _subscriptions.cancelAll();
    if (mounted) await initStreams();
  }

  Widget _chatLoadError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.lang.errorInternalError),
        TextButton.icon(
          onPressed: _retryChatLoading,
          icon: const Icon(Icons.refresh),
          label: Text(context.lang.manualVerificationRetry),
        ),
      ],
    ),
  );

  Future<void> initStreams() async {
    final generation = ++_chatLoadGeneration;
    try {
      await _initStreams(generation);
    } catch (error, stackTrace) {
      if (mounted && generation == _chatLoadGeneration) {
        _chatLoadingFailed(error, stackTrace);
      }
    }
  }

  Future<void> _initStreams(int generation) async {
    bool active() => mounted && generation == _chatLoadGeneration;
    void failed(Object error, [StackTrace? stackTrace]) {
      if (active()) _chatLoadingFailed(error, stackTrace);
    }

    final groupStream = watchRustDatabase(
      (control) => rust_groups.watchGroups(
        input: db_groups.GroupQuery(
          filter: db_groups.GroupFilter.id,
          groupId: widget.groupId,
        ),
        control: control,
      ),
    ).map((rows) => rows.isEmpty ? null : rows.single);
    _subscriptions.group = groupStream.listen((newGroup) {
      if (!active()) return;
      if (newGroup == null) {
        failed(StateError('Conversation is unavailable'));
        return;
      }
      setState(() {
        _group = newGroup;
      });
    }, onError: failed);

    final msgStream = await Future.value(
      watchRustDatabase(
        (control) => rust_messages.watchMessages(
          input: db_messages.MessageQuery(
            filter: db_messages.MessageFilter.page,
            groupId: widget.groupId,
            nowMs: clock.now().millisecondsSinceEpoch,
          ),
          control: control,
        ),
      ),
    );
    if (!active()) return;
    _subscriptions.messages = msgStream.listen((update) async {
      if (!active()) return;
      _data.latestMessages = update;
      if (_data.olderMessages.isEmpty) {
        _hasMoreMessages = update.length == _messagePageSize;
      }
      try {
        await _applyLoadedMessages(reportOpened: true);
        if (!active()) return;
        _animationState.hasReceivedFirstBatch = true;
        setState(() {
          _loadingMessages = false;
          _chatLoadFailed = false;
        });
      } catch (error, stackTrace) {
        failed(error, stackTrace);
      }
    }, onError: failed);

    final groupContacts = joinedGroupContacts(
      await rust_groups.getGroupContacts(
        input: db_groups.GroupMembersQuery(
          groupId: widget.groupId,
          orderForChats: true,
        ),
        transaction: currentDatabaseSession(),
      ),
    ).map((row) => row.$1).toList(growable: false);
    if (!active()) return;
    if (mounted) {
      setState(() {
        _groupContacts = groupContacts;
        _receiverDeletedAccount =
            groupContacts.length == 1 && groupContacts.first.accountDeleted;
      });
      _watchRelevantContacts();
    }

    if (userService.currentUser.typingIndicators) {
      unawaitedRustCall(
        RustApi.sendTyping(groupId: widget.groupId, isTyping: false),
        'sendTyping',
      );
      _nextTypingIndicator = Timer.periodic(chatOpenPingInterval, (_) {
        // A typing announcement refreshes the contact's chat-open state as
        // well, so pinging while the composer is active would spend a second
        // message only to clear the typing flag that composer just set.
        if (_isViewActive() && !_composing.value) {
          unawaitedRustCall(
            RustApi.sendTyping(groupId: widget.groupId, isTyping: false),
            'sendTyping',
          );
        }
      });
    }
  }

  Future<void> _applyLoadedMessages({required bool reportOpened}) async {
    final revision = ++_loadedMessagesRevision;
    // Game cards on older pages can change player, position or disappear.
    // Refresh them too, and discard cached automatic text from older snapshots.
    final olderGameMessageIds = _data.olderMessages
        .where(
          (message) =>
              message.type == MessageType.webxdcApp.name ||
              gameAnnouncementInstance(message) != null,
        )
        .map((message) => message.messageId)
        .toSet();
    if (olderGameMessageIds.isNotEmpty) {
      final current = await watchRustDatabase(
        (control) => rust_messages.watchMessages(
          input: db_messages.MessageQuery(
            filter: db_messages.MessageFilter.ids,
            ids: olderGameMessageIds.toList(),
            nowMs: clock.now().millisecondsSinceEpoch,
          ),
          control: control,
        ),
      ).first;
      if (!mounted || revision != _loadedMessagesRevision) return;
      _data.olderMessages = [
        ..._data.olderMessages.where(
          (message) => !olderGameMessageIds.contains(message.messageId),
        ),
        ...current,
      ];
    }
    final byId = <String, StoredMessage>{
      for (final message in _data.olderMessages) message.messageId: message,
      for (final message in _data.latestMessages) message.messageId: message,
    };
    final loadedMessages = byId.values.toList()
      ..sort((a, b) {
        final byTime = a.createdAt.compareTo(b.createdAt);
        return byTime != 0 ? byTime : a.messageId.compareTo(b.messageId);
      });

    // A media row must know its type before it is exposed to the list. Without
    // this initial read, stored media first renders as an empty bubble and then
    // grows to the preview height when the media watch emits. That changes the
    // extent of rows around the active scroll position and makes the positioned
    // list jump, especially while another page is being appended.
    final missingMediaIds = loadedMessages
        .map((message) => message.mediaId)
        .whereType<String>()
        .where((mediaId) => !_data.mediaFilesById.containsKey(mediaId))
        .toSet();
    final missingMediaFiles = missingMediaIds.isEmpty
        ? const <MediaFile>[]
        : await rust_mediafiles.listMediaFiles(
            input: db_mediafiles.MediaQuery(
              filter: db_mediafiles.MediaFilter.ids,
              ids: missingMediaIds.toList().toList(),
            ),
            transaction: currentDatabaseSession(),
          );
    if (!mounted || revision != _loadedMessagesRevision) return;

    if (missingMediaFiles.isNotEmpty) {
      _data.mediaFilesById = {
        ..._data.mediaFilesById,
        for (final mediaFile in missingMediaFiles) mediaFile.mediaId: mediaFile,
      };
    }
    // Merge after the media read: a send may have added a pending bubble while
    // that read was in flight. A stored row with the same ID wins immediately.
    final visibleMessages = _pendingMessages.merge(loadedMessages);
    _data.allMessages = visibleMessages;
    _data.messagesById = {
      for (final message in visibleMessages) message.messageId: message,
    };
    _watchGroupActionsForLoadedRange();
    _watchLoadedMessageData();
    _watchRelevantContacts();
    await setMessages(
      visibleMessages,
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
    _subscriptions.groupActions =
        watchRustDatabase(
          (control) => rust_groups.watchGroupHistory(
            group: widget.groupId,
            since: since == null ? null : since.millisecondsSinceEpoch ~/ 1000,
            control: control,
          ),
        ).listen((actions) async {
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
    final older = await rust_messages.listMessages(
      input: db_messages.MessageQuery(
        filter: db_messages.MessageFilter.page,
        groupId: widget.groupId,
        before: oldestMessage.createdAt.millisecondsSinceEpoch ~/ 1000,
        beforeMessageId: oldestMessage.messageId,
        nowMs: clock.now().millisecondsSinceEpoch,
      ),
      transaction: currentDatabaseSession(),
    );
    _hasMoreMessages = older.length == _messagePageSize;
    _data.olderMessages = [...older, ..._data.olderMessages];
    await _applyLoadedMessages(reportOpened: true);
  }

  void _watchLoadedMessageData() {
    final messageIds = _data.messagesById.keys
        .where((messageId) => !_pendingMessages.contains(messageId))
        .toSet();
    if (setEquals(_data.watchedMessageIds, messageIds)) return;
    _data.watchedMessageIds = messageIds;

    unawaited(_subscriptions.media?.cancel());
    unawaited(_subscriptions.reactions?.cancel());
    unawaited(_subscriptions.messageActions?.cancel());

    final mediaIds = _data.allMessages
        .map((message) => message.mediaId)
        .whereType<String>()
        .toSet();
    _subscriptions.media =
        watchRustDatabase(
          (control) => rust_mediafiles
              .watchMediaFiles(
                input: db_mediafiles.MediaQuery(
                  filter: db_mediafiles.MediaFilter.ids,
                  ids: mediaIds.toList(),
                ),
                control: control,
              )
              .map(orderedMediaFiles),
        ).listen((
          mediaFiles,
        ) {
          if (!mounted) return;
          _data.mediaFilesById = {
            for (final mediaFile in mediaFiles) mediaFile.mediaId: mediaFile,
          };
          _updateGalleryItems(force: true);
          // Publish the media map and matching gallery snapshot together. A
          // single database emission must not rebuild the entire message list
          // once with stale gallery data and immediately again with fresh data.
          _notifyMessageDataChanged();
        });
    _subscriptions.reactions =
        watchRustDatabase(
          (control) => rust_reactions.watchReactions(
            messages: messageIds.toList(),
            control: control,
          ),
        ).listen((reactions) {
          if (!mounted) return;
          final byMessage = <String, List<StoredReaction>>{};
          for (final reaction in reactions) {
            byMessage.putIfAbsent(reaction.messageId, () => []).add(reaction);
          }
          _data.reactionsByMessageId = byMessage;
          _notifyMessageDataChanged();
        });
    _subscriptions.messageActions =
        watchRustDatabase(
          (control) => rust_messages.watchDeliveryActions(
            ids: messageIds.toList(),
            control: control,
          ),
        ).listen((actions) {
          if (!mounted) return;
          _data.ackedMessageIds = actions
              .where((action) => action.type == MessageActionType.ackByUserAt)
              .map((action) => action.messageId)
              .toSet();
          _data.failedMessageIds = actions
              .where((action) => action.type == MessageActionType.sendFailed)
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
    _subscriptions.contacts =
        watchRustDatabase(
          (control) => rust_contacts.watchContacts(
            input: db_contacts.ContactQuery(
              filter: db_contacts.ContactFilter.ids,
              ids: Int64List.fromList(contactIds.toList()),
            ),
            control: control,
          ),
        ).listen(
          (contacts) {
            if (!mounted) return;
            _data.contactsById = {
              for (final contact in contacts) contact.userId: contact,
            };
            _notifyMessageDataChanged();
          },
        );
  }

  Iterable<int> _referencedContactIds() sync* {
    for (final message in _data.allMessages) {
      yield* parseMentions(
        message.content ?? '',
      ).map((part) => part.userId).nonNulls;
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
    List<StoredMessage> newMessages,
    List<GroupHistory> groupActions, {
    bool reportOpened = false,
  }) async {
    final newestKnownAt = _animationState.newestKnownAt;

    // Only a message the user just sent pulls the list back down. Deciding
    // this from the newest known message alone would scroll on every unrelated
    // update as well: reactions, media state, group actions and every page of
    // older messages run through here too, and each of them would yank the
    // reader back to the bottom whenever their own message ends the chat.
    final lastMessage = newMessages.lastOrNull;
    final wasSentByMe =
        _animationState.hasReceivedFirstBatch &&
        lastMessage != null &&
        lastMessage.senderId == null &&
        !_animationState.knownMessageIds.contains(
          messageActivityId(lastMessage),
        );

    for (final msg in newMessages) {
      // Only messages appended after the newest one already loaded are new to
      // the user. Messages fetched by scrolling up are older and must not
      // animate, no matter who sent them.
      if (_animationState.hasReceivedFirstBatch &&
          msg.senderId != null &&
          newestKnownAt != null &&
          msg.createdAt.isAfter(newestKnownAt) &&
          !_animationState.knownMessageIds.contains(messageActivityId(msg))) {
        _animationState.animateMessageIds.add(msg.messageId);
      }
      _animationState.knownMessageIds.add(messageActivityId(msg));
      final currentNewest = _animationState.newestKnownAt;
      if (currentNewest == null || msg.createdAt.isAfter(currentNewest)) {
        _animationState.newestKnownAt = msg.createdAt;
      }
    }

    final chatItems = <ChatItem>[];
    final storedMediaFiles = <StoredMessage>[];
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
          !_animationState.reportedOpenedMessageIds.contains(
            messageActivityId(msg),
          )) {
        if (openedMessages[msg.senderId!] == null) {
          openedMessages[msg.senderId!] = [];
        }
        openedMessages[msg.senderId!]!.add(messageActivityId(msg));
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

    if (!mounted) return;
    _data.chatItems = chatItems.reversed.toList();
    _updateGalleryItems(messages: storedMediaFiles);
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

  void _updateGalleryItems({
    List<StoredMessage>? messages,
    bool force = false,
  }) {
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

    final messagesByMediaId = <String, List<StoredMessage>>{};
    for (final message in storedMediaMessages) {
      final mediaFile = _data.mediaFilesById[message.mediaId];
      if (mediaFile == null) continue;
      if (!MediaFileService(mediaFile).imagePreviewAvailable) continue;
      messagesByMediaId
          .putIfAbsent(mediaFile.mediaId, () => <StoredMessage>[])
          .add(message);
    }
    if (!mounted) return;

    final previousItems = {
      for (final item in _data.galleryItems)
        item.mediaService.mediaFile.mediaId: item,
    };
    final nextItems = <MemoryItem>[];
    for (final entry in messagesByMediaId.entries) {
      final mediaFile = _data.mediaFilesById[entry.key]!;
      final previous = previousItems[entry.key];
      if (previous != null &&
          previous.mediaService.mediaFile == mediaFile &&
          listEquals(previous.messages, entry.value)) {
        nextItems.add(previous);
      } else {
        nextItems.add(
          MemoryItem(
            mediaService: MediaFileService(mediaFile),
            messages: entry.value,
          ),
        );
      }
    }

    final previousOrder = _data.galleryItems
        .map((item) => item.mediaService.mediaFile.mediaId)
        .toList();
    final nextOrder = nextItems
        .map((item) => item.mediaService.mediaFile.mediaId)
        .toList();
    if (listEquals(previousOrder, nextOrder)) {
      // Preserve the list identity when its indexes are unchanged. Media rows
      // cache their gallery index, so replacing this list on every media status
      // update made every visible preview scan the whole gallery again.
      for (var i = 0; i < nextItems.length; i++) {
        _data.galleryItems[i] = nextItems[i];
      }
    } else {
      _data.galleryItems = nextItems;
    }
    _data.galleryMessageIds = messageIds;
  }

  Future<void> scrollToMessage(String messageId) async {
    // A quoted story is not in the chat to scroll to. The user's own story
    // leads to their profile, which lists it with its viewers; a contact's
    // story leads nowhere.
    if (!_data.messagesById.containsKey(messageId)) {
      final quoted = await rust_messages.getMessage(
        id: messageId,
        transaction: currentDatabaseSession(),
      );
      if (quoted != null && quoted.isStory && !quoted.mediaStored) {
        if (quoted.senderId == null && mounted) {
          await context.push(Routes.settingsProfile);
        }
        return;
      }
    }
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
  Widget build(BuildContext context) => ChatNotificationListener(
    conversationId: widget.groupId,
    child: _buildChat(context),
  );

  Widget _buildChat(BuildContext context) {
    if (_group == null) {
      // Drawing nothing leaves the pushed route black until the group row
      // arrives, which is plainly visible whenever the database is busy. The
      // empty app bar keeps the back button reachable during that wait.
      return Scaffold(
        appBar: AppBar(),
        body: _chatLoadFailed ? _chatLoadError() : null,
      );
    }
    final group = _group!;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        if (_inputPanel != ChatInputPanel.none) {
          setState(() => _inputPanel = ChatInputPanel.none);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: _inputPanel == ChatInputPanel.none,
        appBar: AppBar(
          title: GestureDetector(
            onTap: () async {
              if (group.isDirectChat) {
                final member = await rust_groups.listGroupMembers(
                  input: db_groups.GroupMembersQuery(
                    groupId: group.groupId,
                    activeOnly: false,
                  ),
                  transaction: currentDatabaseSession(),
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
                        if (!group.isDirectChat)
                          ContactGroupBadges(groupId: group.groupId)
                        else if (_groupContacts.isNotEmpty)
                          ContactGroupBadges(
                            userId: _groupContacts.first.userId,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: ChatBodySafeArea(
          showingPicker: _inputPanel != ChatInputPanel.none,
          child: Column(
            children: [
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _messageDataVersion,
                  builder: (context, _, _) =>
                      _chatLoadFailed && _data.allMessages.isEmpty
                      ? _chatLoadError()
                      : Align(
                          alignment: Alignment.topCenter,
                          child: ChatMessageActionScope(
                            ackedMessageIds: _data.ackedMessageIds,
                            failedMessageIds: _data.failedMessageIds,
                            child: ScrollablePositionedList.builder(
                              reverse: true,
                              itemCount:
                                  _data.chatItems.length +
                                  1 +
                                  (_loadingMessages ? 0 : 1),
                              itemScrollController: itemScrollController,
                              itemPositionsListener: itemPositionsListener,
                              itemBuilder: (context, i) {
                                if (i == 0) {
                                  return userService
                                          .currentUser
                                          .typingIndicators
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
                                      _data
                                          .chatItems[i]
                                          .groupAction!
                                          .groupHistoryId,
                                    ),
                                    action: _data.chatItems[i].groupAction!,
                                    contactsById: _data.contactsById,
                                  );
                                } else {
                                  final chatMessage =
                                      _data.chatItems[i].message!;
                                  return BlinkWidget(
                                    key: Key('blink_${chatMessage.messageId}'),
                                    enabled: focusedScrollItem == i,
                                    child: AnimatedNewMessage(
                                      key: Key('anim_${chatMessage.messageId}'),
                                      messageId: chatMessage.messageId,
                                      animateIds:
                                          _animationState.animateMessageIds,
                                      isOwnMessage:
                                          chatMessage.senderId == null,
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
                                            _data
                                                .reactionsByMessageId[chatMessage
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
                  panel: _inputPanel,
                  onMessageSend: _sendMessage,
                  onPanelChanged: (panel) {
                    if (_inputPanel == panel) return;
                    setState(() => _inputPanel = panel);
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

Color getMessageColor(BuildContext context, bool isOther) {
  return isOther
      ? context.appColor(AppColor.chatBubbleReceived)
      : context.appColor(AppColor.chatBubbleSent);
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
  factory ChatItem.message(StoredMessage message) {
    return ChatItem._(message: message);
  }
  factory ChatItem.groupAction(GroupHistory groupAction) {
    return ChatItem._(groupAction: groupAction);
  }
  final GroupHistory? groupAction;
  final StoredMessage? message;
  final DateTime? date;
  bool get isMessage => message != null;
  bool get isDate => date != null;
  bool get isGroupAction => groupAction != null;
}
