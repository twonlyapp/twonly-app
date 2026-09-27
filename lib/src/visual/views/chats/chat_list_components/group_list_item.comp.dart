import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/tables/messages.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/media_download_policy.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/contact_groups.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/context_menu/group.context_menu.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/last_message_time.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/typing_indicator_subtitle.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/message_send_state_icon.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_expiry_timer.dart';

class GroupListItemComp extends StatefulWidget {
  const GroupListItemComp({
    required this.group,
    this.isTyping,
    this.contacts,
    this.unopenedMessages,
    this.lastReaction,
    this.lastMessage,
    this.mediaFiles,
    this.useSharedSummary = false,
    this.verificationStatus,
    this.contactGroups = const [],
    this.storyItems,
    super.key,
  });
  final Group group;
  final bool? isTyping;
  final List<Contact>? contacts;
  final List<Message>? unopenedMessages;
  final Reaction? lastReaction;
  final Message? lastMessage;
  final Map<String, MediaFile>? mediaFiles;
  final bool useSharedSummary;
  final VerificationStatus? verificationStatus;
  final List<ContactGroup> contactGroups;

  /// The contact's story items in a direct chat. Null subscribes itself.
  final List<StoryItem>? storyItems;

  @override
  State<GroupListItemComp> createState() => _UserListItem();
}

class _UserListItem extends State<GroupListItemComp> {
  Message? _currentMessage;

  List<Message> _messagesNotOpened = [];
  StreamSubscription<List<Message>>? _messagesNotOpenedStream;

  Message? _lastMessage;
  Reaction? _lastReaction;
  StreamSubscription<Message?>? _lastMessageStream;
  StreamSubscription<Reaction?>? _lastReactionStream;
  StreamSubscription<List<MediaFile>>? _lastMediaFilesStream;
  Contact? _directContact;
  StreamSubscription<List<Contact>>? _directContactStream;
  List<StoryItem> _storyItems = const [];
  StreamSubscription<List<StoryItem>>? _storyItemsStream;
  final StoryExpiryTimer _storyExpiry = StoryExpiryTimer();

  List<Message> _previewMessages = [];
  final List<MediaFile> _previewMediaFiles = [];
  bool _hasNonOpenedMediaFile = false;
  bool _receiverDeletedAccount = false;

  @override
  void initState() {
    super.initState();
    _applyContacts();
    _lastReaction = widget.lastReaction;
    _lastMessage = widget.lastMessage;
    _storyItems = widget.storyItems ?? const [];
    _scheduleStoryExpiry();
    _applyMediaFiles();
    if (widget.useSharedSummary) {
      _updateState(widget.lastMessage, widget.unopenedMessages ?? const []);
    }
    initStreams();
  }

  @override
  void didUpdateWidget(GroupListItemComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.contacts != oldWidget.contacts) _applyContacts();
    if (widget.lastReaction != oldWidget.lastReaction) {
      _lastReaction = widget.lastReaction;
    }
    if (widget.unopenedMessages != oldWidget.unopenedMessages) {
      _updateState(widget.lastMessage, widget.unopenedMessages ?? const []);
    } else if (widget.lastMessage != oldWidget.lastMessage) {
      _updateState(widget.lastMessage, widget.unopenedMessages ?? const []);
    }
    if (widget.mediaFiles != oldWidget.mediaFiles) _applyMediaFiles();
    if (widget.storyItems != null &&
        widget.storyItems != oldWidget.storyItems) {
      _storyItems = widget.storyItems!;
      _scheduleStoryExpiry();
    }
  }

  void _applyContacts() {
    if (widget.contacts == null) return;
    _directContact = widget.group.isDirectChat && widget.contacts!.isNotEmpty
        ? widget.contacts!.first
        : null;
    _receiverDeletedAccount =
        widget.contacts!.length == 1 && widget.contacts!.first.accountDeleted;
  }

  void _applyMediaFiles() {
    if (widget.mediaFiles == null) return;
    _previewMediaFiles
      ..clear()
      ..addAll(widget.mediaFiles!.values);
  }

  @override
  void dispose() {
    _messagesNotOpenedStream?.cancel();
    _lastReactionStream?.cancel();
    _lastMessageStream?.cancel();
    _lastMediaFilesStream?.cancel();
    _directContactStream?.cancel();
    _storyItemsStream?.cancel();
    _storyExpiry.cancel();
    super.dispose();
  }

  Future<void> initStreams() async {
    if (widget.storyItems == null && widget.group.isDirectChat) {
      _storyItemsStream = twonlyDB.storiesDao
          .watchReceivedStoryItemsForGroup(widget.group.groupId)
          .listen((items) {
            if (!mounted) return;
            setState(() => _storyItems = items);
            _scheduleStoryExpiry();
          });
    }

    if (!widget.useSharedSummary) {
      final lastMsgStream = await twonlyDB.messagesDao.watchLastMessage(
        widget.group.groupId,
      );
      if (!mounted) return;
      _lastMessageStream = lastMsgStream.listen((update) {
        _updateState(update, _messagesNotOpened);
      });
    }

    if (!widget.useSharedSummary) {
      _lastReactionStream = twonlyDB.reactionsDao
          .watchLastReactions(widget.group.groupId)
          .listen((update) {
            if (!mounted) return;
            setState(() {
              _lastReaction = update;
            });
          });
    }

    if (widget.useSharedSummary) {
      _messagesNotOpened = widget.unopenedMessages!;
    } else {
      _messagesNotOpenedStream = twonlyDB.messagesDao
          .watchMessageNotOpened(widget.group.groupId)
          .listen((update) {
            _updateState(_lastMessage, update);
          });
    }

    if (!widget.useSharedSummary) {
      _lastMediaFilesStream = twonlyDB.mediaFilesDao
          .watchMediaFilesForGroup(widget.group.groupId)
          .listen((mediaFiles) {
            if (!mounted) return;
            for (final mediaFile in mediaFiles) {
              final index = _previewMediaFiles.indexWhere(
                (t) => t.mediaId == mediaFile.mediaId,
              );
              if (index >= 0) {
                _previewMediaFiles[index] = mediaFile;
              }
            }
            setState(() {});
          });
    }

    if (widget.contacts != null) {
      // Contact data is shared by the parent chat list.
    } else if (widget.group.isDirectChat) {
      _directContactStream = twonlyDB.groupsDao
          .watchGroupContact(widget.group.groupId)
          .listen((contacts) {
            if (!mounted) return;
            if (contacts.isNotEmpty) {
              setState(() {
                _directContact = contacts.first;
                _receiverDeletedAccount = _directContact!.accountDeleted;
              });
            }
          });
    } else {
      final groupContacts = await twonlyDB.groupsDao.getGroupContact(
        widget.group.groupId,
      );
      if (!mounted) return;
      if (groupContacts.length == 1) {
        _receiverDeletedAccount = groupContacts.first.accountDeleted;
      }
    }
  }

  void _updateState(
    Message? newLastMessage,
    List<Message> newMessagesNotOpened,
  ) {
    if (!mounted) return;
    if (newLastMessage == null) {
      // there are no messages at all
      _currentMessage = null;
      _previewMessages = [];
    } else if (newMessagesNotOpened.isNotEmpty) {
      // Filter for the preview non opened messages. First messages which where
      // send but not yet opened by the other side.
      final receivedMessages = newMessagesNotOpened
          .where((x) => x.senderId != null)
          .toList();

      if (receivedMessages.isNotEmpty) {
        _previewMessages = receivedMessages;
        _currentMessage = receivedMessages.first;
      } else {
        _previewMessages = newMessagesNotOpened;
        _currentMessage = newMessagesNotOpened.first;
      }
    } else {
      // there are no not opened messages show just the last message in the table
      // only shows the last message in case there was no newer messages which
      // already got deleted. This prevents showing that an image got stored 10
      // days ago...
      if (newLastMessage.createdAt.isAfter(
        widget.group.lastMessageExchange.subtract(const Duration(days: 2)),
      )) {
        _currentMessage = newLastMessage;
        _previewMessages = [newLastMessage];
      } else {
        _currentMessage = null;
        _previewMessages = [];
      }
    }

    final msgs = _previewMessages
        .where((x) => x.type == MessageType.media.name && !x.isWidgetMedia)
        .toList();
    if (msgs.isNotEmpty &&
        msgs.first.type == MessageType.media.name &&
        !msgs.first.isDeletedFromSender &&
        msgs.first.senderId != null &&
        msgs.first.openedAt == null) {
      _hasNonOpenedMediaFile = true;
    } else {
      _hasNonOpenedMediaFile = false;
    }

    _lastMessage = newLastMessage;
    _messagesNotOpened = newMessagesNotOpened;
    setState(() {});

    // Only fetch on first load when a mediaId is not yet cached.
    _fetchMissingMediaFiles();
  }

  /// Fetches any media files referenced by preview messages but not yet in the
  /// local cache. Fire-and-forget; updates state when results arrive.
  Future<void> _fetchMissingMediaFiles() async {
    if (widget.useSharedSummary) return;
    final missing = <MediaFile>[];
    for (final message in _previewMessages) {
      if (message.mediaId != null &&
          !_previewMediaFiles.any((t) => t.mediaId == message.mediaId)) {
        final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(
          message.mediaId!,
        );
        if (mediaFile != null) {
          missing.add(mediaFile);
        }
      }
    }
    if (missing.isNotEmpty && mounted) {
      setState(() {
        _previewMediaFiles.addAll(missing);
      });
    }
  }

  Future<void> onTap() async {
    if (_currentMessage == null && widget.group.totalMediaCounter == 0) {
      await context.push(
        Routes.chatsCameraSendTo,
        extra: widget.group,
      );
      return;
    }

    if (_hasNonOpenedMediaFile) {
      final msgs = _previewMessages
          .where((x) => x.type == MessageType.media.name && !x.isWidgetMedia)
          .toList();
      final mediaFile = await twonlyDB.mediaFilesDao.getMediaFileById(
        msgs.first.mediaId!,
      );
      if (mediaFile?.type != MediaType.audio) {
        if (mediaFile?.downloadState == null) return;
        if (mediaFile!.downloadState! == DownloadState.pending) {
          await startDownloadMedia(mediaFile, true);
          return;
        }
        if (mediaFile.downloadState! == DownloadState.ready) {
          if (!mounted) return;
          await context.push(
            Routes.chatsMediaViewer,
            extra: widget.group,
          );
          return;
        }
      }
    }
    if (!mounted) return;
    await context.push(
      Routes.chatsMessages(widget.group.groupId),
      extra: widget.group,
    );
  }

  List<StoryItem> get _activeStoryItems {
    final now = clock.now();
    return _storyItems.where((item) => item.isActiveAt(now)).toList();
  }

  /// Redraws the row when its oldest story item runs out, so the preview
  /// does not outlive the story.
  void _scheduleStoryExpiry() {
    final oldest = _activeStoryItems.firstOrNull;
    if (oldest == null) {
      _storyExpiry.cancel();
      return;
    }
    _storyExpiry.schedule(
      postedAt: oldest.postedAt,
      now: clock.now(),
      onExpired: () {
        if (!mounted) return;
        setState(() {});
        _scheduleStoryExpiry();
      },
    );
  }

  /// While the contact has a story, it stands in for their avatar: the item
  /// that plays first, with the avatar small in its corner. Once all of it
  /// has been seen it is drawn softer.
  Widget _avatar() {
    final avatar = AvatarIcon(group: widget.group, contacts: widget.contacts);
    if (!widget.group.isDirectChat) return avatar;
    final active = _activeStoryItems;
    if (active.isEmpty) return avatar;
    final unseen = active.where((item) => !item.seen);
    final shown = unseen.firstOrNull ?? active.last;
    return StoryPreview(
      mediaFile: shown.mediaFile,
      width: 40,
      height: 40,
      faded: unseen.isEmpty,
      badge: AvatarIcon(
        group: widget.group,
        contacts: widget.contacts,
        fontSize: 9,
      ),
    );
  }

  /// A contact's avatar opens their story while they have one, and their
  /// profile otherwise.
  Future<void> _onAvatarTap() async {
    if (!widget.group.isDirectChat) {
      await context.push(Routes.profileGroup(widget.group.groupId));
      return;
    }
    final active = _activeStoryItems;
    if (active.isNotEmpty) {
      await context.push(Routes.chatsStory(active.first.senderId));
      return;
    }
    final contacts = await twonlyDB.groupsDao.getGroupContact(
      widget.group.groupId,
    );
    if (!mounted || contacts.isEmpty) return;
    await context.push(Routes.profileContact(contacts.first.userId));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        return GroupContextMenu(
          group: widget.group,
          child: ListTile(
            title: LayoutBuilder(
              builder: (context, constraints) {
                // Without labels the name may use the whole row.
                final showBadges = widget.contactGroups.isNotEmpty;
                // The name is capped instead of flexible so the badges get all
                // of the space it does not use, rather than only half the row.
                final nameMaxWidth = showBadges
                    ? constraints.maxWidth * 0.6
                    : constraints.maxWidth;
                return Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: nameMaxWidth),
                      child: Text(
                        widget.group.groupName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    VerificationBadgeComp(
                      group: widget.group,
                      verificationStatus: widget.verificationStatus,
                      useProvidedStatus: widget.useSharedSummary,
                      showOnlyIfVerified: true,
                      clickable: false,
                      size: 12,
                    ),
                    if (showBadges) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: ContactGroupBadges(
                          userId: _directContact?.userId,
                          groupId: widget.group.isDirectChat
                              ? null
                              : widget.group.groupId,
                          contactGroups: widget.contactGroups,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            subtitle: _receiverDeletedAccount
                ? Text(context.lang.userDeletedAccount)
                : (_currentMessage == null)
                ? (widget.group.totalMediaCounter == 0)
                      ? Text(context.lang.chatsTapToSend)
                      : Row(
                          children: [
                            LastMessageTimeComp(
                              key: ValueKey(widget.group.groupId),
                              dateTime: widget.group.lastMessageExchange,
                            ),
                            FlameCounterWidget(
                              group: widget.group,
                              prefix: true,
                            ),
                          ],
                        )
                : Row(
                    children: [
                      TypingIndicatorSubtitleComp(
                        groupId: widget.group.groupId,
                        isTyping: widget.isTyping,
                      ),
                      MessageSendStateIcon(
                        _previewMessages,
                        _previewMediaFiles,
                        lastReaction: _lastReaction,
                        group: widget.group,
                      ),
                      const Text('•'),
                      const SizedBox(width: 5),
                      if (_currentMessage != null)
                        LastMessageTimeComp(
                          key: ValueKey(widget.group.groupId),
                          message: _currentMessage,
                        ),
                      FlameCounterWidget(
                        group: widget.group,
                        prefix: true,
                      ),
                    ],
                  ),
            leading: GestureDetector(
              onTap: _onAvatarTap,
              child: _avatar(),
            ),
            trailing: (widget.group.leftGroup || _receiverDeletedAccount)
                ? null
                : IconButton(
                    onPressed: () {
                      if (_hasNonOpenedMediaFile) {
                        context.push(
                          Routes.chatsMessages(widget.group.groupId),
                          extra: widget.group,
                        );
                      } else {
                        context.push(
                          Routes.chatsCameraSendTo,
                          extra: widget.group,
                        );
                      }
                    },
                    icon: FaIcon(
                      _hasNonOpenedMediaFile
                          ? FontAwesomeIcons.solidComments
                          : FontAwesomeIcons.camera,
                      color: context.color.outline.withAlpha(150),
                    ),
                  ),
            onTap: onTap,
          ),
        );
      },
    );
  }
}
