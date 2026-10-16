import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/daos/stories.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/connection_status.comp.dart';
import 'package:twonly/src/visual/components/notification_badge.comp.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/empty_chat_list.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/group_list_item.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/news_btn.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/story_bubble_strip.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/typing_indicator.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_expiry_timer.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/finish_setup.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/missing_backup_setup.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/missing_recovery_contacts.comp.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});
  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView>
    with AutomaticKeepAliveClientMixin<ChatListView> {
  StreamSubscription<void>? _userSub;
  StreamSubscription<List<Group>>? _contactsSub;
  StreamSubscription<List<Contact>>? _contactsCountSub;
  StreamSubscription<List<MediaFile>>? _precacheSub;
  StreamSubscription<List<GroupMember>>? _typingMembersSub;
  StreamSubscription<List<(Contact, GroupMember)>>? _groupMembersSub;
  StreamSubscription<List<Message>>? _unopenedMessagesSub;
  StreamSubscription<List<(String, Reaction)>>? _reactionsSub;
  StreamSubscription<List<Message>>? _latestMessagesSub;
  StreamSubscription<List<MediaFile>>? _chatListMediaSub;
  StreamSubscription<Map<String, VerificationStatus>>? _verificationSub;
  StreamSubscription<List<(int, ContactGroup)>>? _contactGroupsSub;
  StreamSubscription<List<(String, ContactGroup)>>? _chatContactGroupsSub;
  StreamSubscription<List<StoryItem>>? _storiesSub;
  StreamSubscription<List<OwnStoryItem>>? _ownStoriesSub;
  final StoryExpiryTimer _ownStoryExpiry = StoryExpiryTimer();
  final StoryExpiryTimer _receivedStoryExpiry = StoryExpiryTimer();
  Timer? _typingUpdateTimer;
  final Set<String> _precachedMediaIds = {};
  List<Group> _groupsNotPinned = [];
  List<Group> _groupsPinned = [];
  List<Group> _groupsArchived = [];
  Set<String> _typingGroupIds = {};
  List<GroupMember> _typingMembers = [];
  Map<String, List<Contact>> _contactsByGroup = {};
  Map<String, List<Message>> _unopenedMessagesByGroup = {};
  Map<String, Reaction> _lastReactionByGroup = {};
  Map<String, Message> _lastMessageByGroup = {};
  Map<String, MediaFile> _chatListMediaById = {};
  Map<String, VerificationStatus> _verificationByGroup = {};
  Map<int, List<ContactGroup>> _contactGroupsByUser = {};
  Map<String, List<ContactGroup>> _contactGroupsByGroup = {};
  Map<String, List<StoryItem>> _storiesByGroup = {};
  List<OwnStoryItem> _ownStories = [];

  final ValueNotifier<bool> _hasContacts = ValueNotifier(false);
  bool _loading = true;
  bool get _hasOpenGroup =>
      _groupsNotPinned.isNotEmpty ||
      _groupsArchived.isNotEmpty ||
      _groupsPinned.isNotEmpty;

  GlobalKey searchForOtherUsers = GlobalKey();
  bool showFeedbackShortcut = false;

  int _countContactRequest = 0;
  int _countAnnouncedUsers = 0;
  final ValueNotifier<int> _badgeCount = ValueNotifier(0);
  late StreamSubscription<int?> _countContactRequestStream;
  late StreamSubscription<int?> _countAnnouncedStream;

  @override
  void initState() {
    super.initState();
    initAsync();
    _userSub = userService.onUserUpdated.listen((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> initAsync() async {
    final stream = twonlyDB.groupsDao.watchGroupsForChatList();
    _contactsSub = stream.listen((groups) {
      if (!mounted) return;
      setState(() {
        _groupsNotPinned = groups
            .where((x) => !x.pinned && !x.archived)
            .toList();
        _groupsPinned = groups.where((x) => x.pinned && !x.archived).toList();
        _groupsArchived = groups.where((x) => x.archived).toList();
        _loading = false;
      });
    });

    _contactsCountSub = twonlyDB.contactsDao.watchAllAcceptedContacts().listen((
      contacts,
    ) {
      if (!mounted) return;
      _hasContacts.value = contacts.isNotEmpty;
    });

    _countContactRequestStream = twonlyDB.contactsDao
        .watchContactsRequestedCount()
        .listen((update) {
          if (update != null) {
            if (!mounted) return;
            _countContactRequest = update;
            _badgeCount.value = _countAnnouncedUsers + _countContactRequest;
          }
        });

    _countAnnouncedStream = twonlyDB.userDiscoveryDao
        .watchNewAnnouncementsWithDataCount()
        .listen((update) {
          if (!mounted) return;
          _countAnnouncedUsers = update;
          _badgeCount.value = _countAnnouncedUsers + _countContactRequest;
        });

    _precacheSub = twonlyDB.messagesDao.watchUnopenedMediaFiles().listen((
      mediaFiles,
    ) {
      if (!mounted) return;
      for (final media in mediaFiles) {
        if (!_precachedMediaIds.contains(media.mediaId)) {
          _precachedMediaIds.add(media.mediaId);
          final fileService = MediaFileService(media);
          if (fileService.tempPath.existsSync()) {
            precacheImage(
              FileImage(fileService.tempPath),
              context,
            ).catchError((Object e, StackTrace st) {
              Log.error('Failed to precache image in ChatListView: $e\n$st');
            });
          }
        }
      }
    });

    _typingMembersSub = twonlyDB.groupsDao.watchTypingGroupMembers().listen((
      members,
    ) {
      if (!mounted) return;
      _typingMembers = members;
      _updateTypingGroupIds();
    });
    _typingUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTypingGroupIds(),
    );
    _groupMembersSub = twonlyDB.groupsDao.watchAllGroupMembers().listen((rows) {
      if (!mounted) return;
      final contactsByGroup = <String, List<Contact>>{};
      for (final row in rows) {
        contactsByGroup.putIfAbsent(row.$2.groupId, () => []).add(row.$1);
      }
      setState(() => _contactsByGroup = contactsByGroup);
    });
    _unopenedMessagesSub = twonlyDB.messagesDao
        .watchAllMessagesNotOpened()
        .listen((messages) {
          if (!mounted) return;
          final byGroup = <String, List<Message>>{};
          for (final message in messages) {
            byGroup.putIfAbsent(message.groupId, () => []).add(message);
          }
          setState(() => _unopenedMessagesByGroup = byGroup);
        });
    _reactionsSub = twonlyDB.reactionsDao.watchLatestReactionsByGroup().listen((
      rows,
    ) {
      if (!mounted) return;
      setState(
        () => _lastReactionByGroup = {for (final row in rows) row.$1: row.$2},
      );
    });
    _latestMessagesSub = twonlyDB.messagesDao
        .watchLatestMessagesByGroup()
        .listen((messages) {
          if (!mounted) return;
          setState(
            () => _lastMessageByGroup = {
              for (final message in messages) message.groupId: message,
            },
          );
        });
    _chatListMediaSub = twonlyDB.mediaFilesDao.watchChatListMediaFiles().listen(
      (mediaFiles) {
        if (!mounted) return;
        setState(
          () => _chatListMediaById = {
            for (final mediaFile in mediaFiles) mediaFile.mediaId: mediaFile,
          },
        );
      },
    );
    _verificationSub = twonlyDB.keyVerificationDao
        .watchAllGroupsVerificationStatus()
        .listen((statuses) {
          if (!mounted) return;
          setState(() => _verificationByGroup = statuses);
        });
    _contactGroupsSub = twonlyDB.contactGroupsDao
        .watchAllVisibleUserGroups()
        .listen((
          rows,
        ) {
          if (!mounted) return;
          final contactGroups = <int, List<ContactGroup>>{};
          for (final row in rows) {
            contactGroups.putIfAbsent(row.$1, () => []).add(row.$2);
          }
          setState(() => _contactGroupsByUser = contactGroups);
        });
    _chatContactGroupsSub = twonlyDB.contactGroupsDao
        .watchAllVisibleChatGroups()
        .listen((rows) {
          if (!mounted) return;
          final contactGroups = <String, List<ContactGroup>>{};
          for (final row in rows) {
            contactGroups.putIfAbsent(row.$1, () => []).add(row.$2);
          }
          setState(() => _contactGroupsByGroup = contactGroups);
        });
    _storiesSub = twonlyDB.storiesDao.watchReceivedStoryItems().listen((items) {
      if (!mounted) return;
      final byGroup = <String, List<StoryItem>>{};
      for (final item in items) {
        byGroup.putIfAbsent(item.message.groupId, () => []).add(item);
      }
      setState(() => _storiesByGroup = byGroup);
      _scheduleReceivedStoryExpiry();
    });
    _ownStoriesSub = twonlyDB.storiesDao.watchOwnStoryItems().listen((items) {
      if (!mounted) return;
      setState(() => _ownStories = items);
      _scheduleOwnStoryExpiry();
    });
  }

  List<OwnStoryItem> get _activeOwnStories {
    final now = clock.now();
    return _ownStories.where((item) => item.isActiveAt(now)).toList();
  }

  List<StoryBubbleItem> get _storyBubbles {
    final contactsById = <int, Contact>{
      for (final contacts in _contactsByGroup.values)
        for (final contact in contacts) contact.userId: contact,
    };
    final groupsById = <String, Group>{
      for (final group in [
        ..._groupsPinned,
        ..._groupsNotPinned,
        ..._groupsArchived,
      ])
        group.groupId: group,
    };
    return buildStoryBubbleItems(
      stories: _storiesByGroup.values.expand((items) => items),
      labelFor: (story) => switch (contactsById[story.senderId]) {
        final Contact contact => getContactDisplayName(contact),
        null =>
          groupsById[story.message.groupId]?.groupName ??
              story.senderId.toString(),
      },
    );
  }

  /// Puts the avatar back when the oldest own story item runs out.
  void _scheduleOwnStoryExpiry() {
    final oldest = _activeOwnStories.firstOrNull;
    if (oldest == null) {
      _ownStoryExpiry.cancel();
      return;
    }
    _ownStoryExpiry.schedule(
      postedAt: oldest.postedAt,
      now: clock.now(),
      onExpired: () {
        if (!mounted) return;
        setState(() {});
        _scheduleOwnStoryExpiry();
      },
    );
  }

  /// Removes an unseen story bubble at its exact 24-hour boundary even if
  /// the database stream is otherwise quiet.
  void _scheduleReceivedStoryExpiry() {
    final now = clock.now();
    final active =
        _storiesByGroup.values
            .expand((items) => items)
            .where((item) => !item.seen && item.isActiveAt(now))
            .toList()
          ..sort((a, b) => a.postedAt.compareTo(b.postedAt));
    final oldest = active.firstOrNull;
    if (oldest == null) {
      _receivedStoryExpiry.cancel();
      return;
    }
    _receivedStoryExpiry.schedule(
      postedAt: oldest.postedAt,
      now: now,
      onExpired: () {
        if (!mounted) return;
        setState(() {});
        _scheduleReceivedStoryExpiry();
      },
    );
  }

  /// Labels of a chat: those of the contact for direct chats, those of the
  /// group itself otherwise.
  List<ContactGroup> _contactGroupsFor(Group group) {
    if (!group.isDirectChat) {
      return _contactGroupsByGroup[group.groupId] ?? const [];
    }
    final contacts = _contactsByGroup[group.groupId];
    if (contacts == null || contacts.isEmpty) return const [];
    return _contactGroupsByUser[contacts.first.userId] ?? const [];
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _contactsSub?.cancel();
    _contactsCountSub?.cancel();
    _countContactRequestStream.cancel();
    _countAnnouncedStream.cancel();
    _userSub?.cancel();
    _precacheSub?.cancel();
    _typingMembersSub?.cancel();
    _typingUpdateTimer?.cancel();
    _groupMembersSub?.cancel();
    _unopenedMessagesSub?.cancel();
    _reactionsSub?.cancel();
    _latestMessagesSub?.cancel();
    _chatListMediaSub?.cancel();
    _verificationSub?.cancel();
    _contactGroupsSub?.cancel();
    _chatContactGroupsSub?.cancel();
    _storiesSub?.cancel();
    _ownStoriesSub?.cancel();
    _ownStoryExpiry.cancel();
    _receivedStoryExpiry.cancel();
    super.dispose();
  }

  void _updateTypingGroupIds() {
    if (!mounted) return;
    final typingGroupIds = _typingMembers
        .where(isTyping)
        .map((member) => member.groupId)
        .toSet();
    if (setEquals(_typingGroupIds, typingGroupIds)) return;
    setState(() => _typingGroupIds = typingGroupIds);
  }

  Map<String, MediaFile> _mediaForGroup(String groupId) {
    final mediaIds = <String>{
      for (final message
          in _unopenedMessagesByGroup[groupId] ?? const <Message>[])
        if (message.mediaId != null) message.mediaId!,
      if (_lastMessageByGroup[groupId]?.mediaId != null)
        _lastMessageByGroup[groupId]!.mediaId!,
    };
    final mediaFiles = <String, MediaFile>{};
    for (final mediaId in mediaIds) {
      final mediaFile = _chatListMediaById[mediaId];
      if (mediaFile != null) mediaFiles[mediaId] = mediaFile;
    }
    return mediaFiles;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final plan = context.select<PurchasesProvider, SubscriptionPlan>(
      (p) => p.plan,
    );
    final storyBubbles = _storyBubbles;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ConnectionStatusComp(
              child: GestureDetector(
                // The profile is where the user's own story is followed.
                onTap: () => context.push(Routes.settingsProfile),
                child: switch (_activeOwnStories.lastOrNull) {
                  // While the user has a story, it replaces their avatar.
                  final OwnStoryItem newest => StoryPreview(
                    mediaFile: newest.mediaFile,
                    width: 28,
                    height: 28,
                    circle: true,
                  ),
                  null => AvatarIcon(
                    myAvatar: true,
                    fontSize: 14,
                    color: context.color.onSurface.withAlpha(20),
                  ),
                },
              ),
            ),
            const SizedBox(width: 10),
            const Text('twonly '),
            if (plan != SubscriptionPlan.Free)
              GestureDetector(
                onTap: () => context.push(Routes.settingsSubscription),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 3,
                  ),
                  child: Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: context.color.onPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          const NewsIconButtonComp(),
          ValueListenableBuilder<int>(
            valueListenable: _badgeCount,
            builder: (context, badgeCount, child) {
              return Stack(
                children: [
                  if (badgeCount > 0)
                    Positioned.fill(
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.color.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: NotificationBadgeComp(
                      backgroundColor: context.color.inverseSurface,
                      textColor: context.color.onInverseSurface,
                      count: badgeCount.toString(),
                      child: IconButton(
                        color: badgeCount > 0 ? context.color.onPrimary : null,
                        key: searchForOtherUsers,
                        icon: const FaIcon(FontAwesomeIcons.userPlus, size: 18),
                        onPressed: () => context.push(Routes.chatsAddNewUser),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          IconButton(
            onPressed: () => context.push(Routes.settings),
            icon: const FaIcon(FontAwesomeIcons.gear, size: 19),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await RustApi.close();
          await RustApi.connect();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          children: [
            const FinishSetupComp(),
            const MissingBackupComp(),
            const MissingRecoveryContactsComp(),
            if (_loading)
              const Expanded(
                child: SizedBox.shrink(),
              )
            else if (!_hasOpenGroup)
              Expanded(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [EmptyChatListComp()],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount:
                      (storyBubbles.isNotEmpty ? 1 : 0) +
                      _groupsPinned.length +
                      (_groupsPinned.isNotEmpty ? 1 : 0) +
                      _groupsNotPinned.length +
                      (_groupsArchived.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (storyBubbles.isNotEmpty) {
                      if (index == 0) {
                        return StoryBubbleStrip(
                          items: storyBubbles,
                          onTap: (item) => context.push(
                            Routes.chatsStory(item.story.senderId),
                          ),
                        );
                      }
                      index -= 1;
                    }
                    if (index >=
                        _groupsNotPinned.length +
                            _groupsPinned.length +
                            (_groupsPinned.isNotEmpty ? 1 : 0)) {
                      if (_groupsArchived.isEmpty) return Container();
                      return ListTile(
                        title: Text(
                          '${context.lang.archivedChats} (${_groupsArchived.length})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                        onTap: () => context.push(Routes.chatsArchived),
                      );
                    }
                    // Check if the index is for the pinned users
                    if (index < _groupsPinned.length) {
                      final group = _groupsPinned[index];
                      return GroupListItemComp(
                        key: ValueKey(group.groupId),
                        group: group,
                        isTyping: _typingGroupIds.contains(group.groupId),
                        contacts: _contactsByGroup[group.groupId] ?? const [],
                        unopenedMessages:
                            _unopenedMessagesByGroup[group.groupId] ?? const [],
                        lastReaction: _lastReactionByGroup[group.groupId],
                        lastMessage: _lastMessageByGroup[group.groupId],
                        mediaFiles: _mediaForGroup(group.groupId),
                        useSharedSummary: true,
                        verificationStatus: _verificationByGroup[group.groupId],
                        contactGroups: _contactGroupsFor(group),
                        storyItems: _storiesByGroup[group.groupId] ?? const [],
                      );
                    }

                    // If there are pinned users, account for the Divider
                    var adjustedIndex = index - _groupsPinned.length;
                    if (_groupsPinned.isNotEmpty && adjustedIndex == 0) {
                      return const Divider();
                    }

                    // Adjust the index for the contacts list
                    adjustedIndex -= (_groupsPinned.isNotEmpty ? 1 : 0);

                    // Get the contacts that are not pinned
                    final group = _groupsNotPinned.elementAt(
                      adjustedIndex,
                    );
                    return GroupListItemComp(
                      key: ValueKey(group.groupId),
                      group: group,
                      isTyping: _typingGroupIds.contains(group.groupId),
                      contacts: _contactsByGroup[group.groupId] ?? const [],
                      unopenedMessages:
                          _unopenedMessagesByGroup[group.groupId] ?? const [],
                      lastReaction: _lastReactionByGroup[group.groupId],
                      lastMessage: _lastMessageByGroup[group.groupId],
                      mediaFiles: _mediaForGroup(group.groupId),
                      useSharedSummary: true,
                      verificationStatus: _verificationByGroup[group.groupId],
                      contactGroups: _contactGroupsFor(group),
                      storyItems: _storiesByGroup[group.groupId] ?? const [],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _hasContacts,
        builder: (context, hasContacts, child) {
          if (!hasContacts) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'qrcode_fab',
                  elevation: 2,
                  backgroundColor: context.color.surfaceContainerHigh,
                  foregroundColor: context.color.onSurface,
                  onPressed: () => context.push(Routes.settingsPublicProfile),
                  child: FaIcon(
                    FontAwesomeIcons.qrcode,
                    color: context.color.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'new_chat_fab',
                  elevation: 2,
                  backgroundColor: context.color.primary,
                  foregroundColor: context.color.onPrimary,
                  onPressed: () => context.push(Routes.chatsStartNewChat),
                  child: FaIcon(
                    FontAwesomeIcons.penToSquare,
                    color: context.color.onPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
