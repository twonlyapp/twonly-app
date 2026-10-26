import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show listEquals, mapEquals, setEquals;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/bridge/database/contact_groups.dart'
    as rust_contact_groups;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/database/key_verifications.dart'
    as rust_key_verifications;
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/bridge/database/messages.dart' as rust_messages;
import 'package:twonly/core/bridge/database/reactions.dart' as rust_reactions;
import 'package:twonly/core/bridge/database/stories.dart' as rust_stories;
import 'package:twonly/core/bridge/database/user_discovery.dart'
    as rust_user_discovery;
import 'package:twonly/core/database/app/contact_groups/table.dart';
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/key_verifications/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/core/database/app/messages/table.dart' as db_messages;
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/reactions/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/connection_status.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart'
    show emptyFlameState;
import 'package:twonly/src/visual/components/notification_badge.comp.dart';
import 'package:twonly/src/visual/components/story_preview.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/empty_chat_list.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/group_list_item.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/news_btn.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/story_bubble_strip.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/typing_indicator.dart';
import 'package:twonly/src/visual/views/chats/media_viewer_components/story_expiry_timer.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/finish_setup.comp.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({this.active = true, super.key});
  final bool active;
  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView>
    with AutomaticKeepAliveClientMixin<ChatListView>, WidgetsBindingObserver {
  bool _watching = false;
  bool _appVisible = true;
  final _flameRefresh = StreamController<void>.broadcast();
  StreamSubscription<Map<String, FlameState>>? _flamesSub;
  Map<String, FlameState> _flamesByGroup = {};
  Timer? _flameDayTimer;
  final Map<String, Map<String, MediaFile>> _mediaByGroup = {};
  StreamSubscription<List<Group>>? _contactsSub;
  StreamSubscription<int>? _contactsCountSub;
  StreamSubscription<List<MediaFile>>? _precacheSub;
  StreamSubscription<List<GroupMember>>? _typingMembersSub;
  StreamSubscription<List<ChatListContact>>? _groupMembersSub;
  StreamSubscription<List<StoredMessage>>? _unopenedMessagesSub;
  StreamSubscription<List<(String, StoredReaction)>>? _reactionsSub;
  StreamSubscription<List<StoredMessage>>? _latestMessagesSub;
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
  Map<String, List<ChatListContact>> _contactsByGroup = {};
  Map<String, List<StoredMessage>> _unopenedMessagesByGroup = {};
  Map<String, StoredReaction> _lastReactionByGroup = {};
  Map<String, StoredMessage> _lastMessageByGroup = {};
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
  StreamSubscription<int>? _countContactRequestStream;
  StreamSubscription<int>? _countAnnouncedStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appVisible =
        lifecycle != AppLifecycleState.paused &&
        lifecycle != AppLifecycleState.hidden &&
        lifecycle != AppLifecycleState.detached;
    _syncWatchActivity();
  }

  @override
  void didUpdateWidget(ChatListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _syncWatchActivity();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wasWatching = _watching;
      _appVisible = true;
      _syncWatchActivity();
      if (wasWatching && _watching) _flameRefresh.add(null);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _appVisible = false;
      _syncWatchActivity();
    }
    if (mounted) setState(() {});
  }

  void _syncWatchActivity() {
    if (widget.active && _appVisible) {
      if (!_watching) _startWatches();
    } else {
      _stopWatches();
    }
  }

  void _startWatches() {
    _watching = true;
    _scheduleFlameDayRefresh();
    _flamesSub =
        restartDatabaseWatch(
          () => watchRustDatabase(
            (control) => rust_groups.watchGroupFlames(control: control),
          ),
          _flameRefresh.stream,
        ).listen((states) {
          if (!mounted || !_watching) return;
          setState(() => _flamesByGroup = states);
        });
    final stream = watchRustDatabase(
      (control) => rust_groups.watchGroups(
        input: const db_groups.GroupQuery(
          filter: db_groups.GroupFilter.chatList,
        ),
        control: control,
      ),
    );
    _contactsSub = stream.listen((groups) {
      if (!mounted || !_watching) return;
      setState(() {
        _groupsNotPinned = groups
            .where((x) => !x.pinned && !x.archived)
            .toList();
        _groupsPinned = groups.where((x) => x.pinned && !x.archived).toList();
        _groupsArchived = groups.where((x) => x.archived).toList();
        _loading = false;
      });
    });

    _contactsCountSub =
        watchRustDatabase(
          (control) => rust_contacts.watchContactsCount(
            metric: db_contacts.ContactCount.accepted,
            control: control,
          ),
        ).listen((count) {
          if (!mounted || !_watching) return;
          _hasContacts.value = count > 0;
        });

    _countContactRequestStream =
        watchRustDatabase(
          (control) => rust_contacts.watchContactsCount(
            metric: db_contacts.ContactCount.requested,
            control: control,
          ),
        ).listen((update) {
          if (!mounted || !_watching) return;
          _countContactRequest = update;
          _badgeCount.value = _countAnnouncedUsers + _countContactRequest;
        });

    var discoveryThreshold = userService.currentUser.userDiscoveryThreshold;
    _countAnnouncedStream =
        restartDatabaseWatch(
          () => watchRustDatabase(
            (control) => rust_user_discovery.watchDiscoveryCount(
              threshold: userService.currentUser.userDiscoveryThreshold,
              control: control,
            ),
          ),
          userService.onUserUpdated.where((_) {
            final next = userService.currentUser.userDiscoveryThreshold;
            if (next == discoveryThreshold) return false;
            discoveryThreshold = next;
            return true;
          }),
        ).listen((update) {
          if (!mounted || !_watching) return;
          _countAnnouncedUsers = update;
          _badgeCount.value = _countAnnouncedUsers + _countContactRequest;
        });

    _precacheSub =
        watchRustDatabase(
          (control) => rust_messages
              .watchUnopenedMedia(control: control)
              .map(orderedMediaFiles),
        ).listen((
          mediaFiles,
        ) {
          if (!mounted || !_watching) return;
          for (final media in mediaFiles) {
            if (!_precachedMediaIds.contains(media.mediaId)) {
              _precachedMediaIds.add(media.mediaId);
              final fileService = MediaFileService(media);
              if (fileService.tempPath.existsSync()) {
                precacheImage(
                  FileImage(fileService.tempPath),
                  context,
                ).catchError((Object e, StackTrace st) {
                  Log.error(
                    'Failed to precache image in ChatListView: $e\n$st',
                  );
                });
              }
            }
          }
        });

    _typingMembersSub =
        watchRustDatabase(
          (control) => rust_groups.watchGroupMembers(
            input: const db_groups.GroupMembersQuery(
              typingOnly: true,
            ),
            control: control,
          ),
        ).listen((
          members,
        ) {
          if (!mounted || !_watching) return;
          _typingMembers = members;
          _updateTypingGroupIds();
        });
    _typingUpdateTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTypingGroupIds(),
    );
    _groupMembersSub =
        watchRustDatabase(
          (control) => rust_groups.watchChatListContacts(control: control),
        ).listen((rows) {
          if (!mounted || !_watching) return;
          final contactsByGroup = <String, List<ChatListContact>>{};
          for (final row in rows) {
            contactsByGroup.putIfAbsent(row.groupId, () => []).add(row);
          }
          for (final entry in contactsByGroup.entries) {
            final previous = _contactsByGroup[entry.key];
            if (listEquals(previous, entry.value)) {
              contactsByGroup[entry.key] = previous!;
            }
          }
          setState(() => _contactsByGroup = contactsByGroup);
        });
    _unopenedMessagesSub =
        watchRustDatabase(
          (control) => rust_messages.watchMessages(
            input: db_messages.MessageQuery(
              filter: db_messages.MessageFilter.unopened,
              nowMs: clock.now().millisecondsSinceEpoch,
            ),
            control: control,
          ),
        ).listen((
          messages,
        ) {
          if (!mounted || !_watching) return;
          final byGroup = <String, List<StoredMessage>>{};
          for (final message in messages) {
            byGroup.putIfAbsent(message.groupId, () => []).add(message);
          }
          setState(() => _unopenedMessagesByGroup = byGroup);
        });
    _reactionsSub =
        watchRustDatabase(
          (control) => rust_reactions
              .watchLatestGroupReactions(control: control)
              .map(
                (rows) => rows
                    .map((row) => (row.groupId, row.reaction))
                    .toList(growable: false),
              ),
        ).listen((
          rows,
        ) {
          if (!mounted || !_watching) return;
          setState(
            () =>
                _lastReactionByGroup = {for (final row in rows) row.$1: row.$2},
          );
        });
    _latestMessagesSub =
        watchRustDatabase(
          (control) => rust_messages.watchMessages(
            input: db_messages.MessageQuery(
              filter: db_messages.MessageFilter.latestByGroup,
              nowMs: clock.now().millisecondsSinceEpoch,
            ),
            control: control,
          ),
        ).listen((
          messages,
        ) {
          if (!mounted || !_watching) return;
          setState(
            () => _lastMessageByGroup = {
              for (final message in messages) message.groupId: message,
            },
          );
        });
    _chatListMediaSub =
        watchRustDatabase(
          (control) => rust_mediafiles
              .watchMediaFiles(
                input: const db_mediafiles.MediaQuery(
                  filter: db_mediafiles.MediaFilter.chatList,
                ),
                control: control,
              )
              .map(orderedMediaFiles),
        ).listen(
          (mediaFiles) {
            if (!mounted || !_watching) return;
            setState(
              () => _chatListMediaById = {
                for (final mediaFile in mediaFiles)
                  mediaFile.mediaId: mediaFile,
              },
            );
          },
        );
    _verificationSub =
        watchRustDatabase(
              (control) => rust_key_verifications.watchGroupsVerification(
                control: control,
              ),
            )
            .map((rows) => {for (final row in rows) row.groupId: row.status})
            .listen((statuses) {
              if (!mounted || !_watching) return;
              setState(() => _verificationByGroup = statuses);
            });
    _contactGroupsSub =
        watchRustDatabase(
          (control) => rust_contact_groups
              .watchContactGroupLabels(forUsers: true, control: control)
              .map((labels) {
                final groups = {
                  for (final group in labels.groups) group.id: group,
                };
                return [
                  for (final member in labels.members)
                    (member.userId!, groups[member.contactGroupId]!),
                ];
              }),
        ).listen((
          rows,
        ) {
          if (!mounted || !_watching) return;
          final contactGroups = <int, List<ContactGroup>>{};
          for (final row in rows) {
            contactGroups.putIfAbsent(row.$1, () => []).add(row.$2);
          }
          setState(() => _contactGroupsByUser = contactGroups);
        });
    _chatContactGroupsSub =
        watchRustDatabase(
          (control) => rust_contact_groups
              .watchContactGroupLabels(forUsers: false, control: control)
              .map((labels) {
                final groups = {
                  for (final group in labels.groups) group.id: group,
                };
                return [
                  for (final member in labels.members)
                    (member.groupId!, groups[member.contactGroupId]!),
                ];
              }),
        ).listen(
          (rows) {
            if (!mounted || !_watching) return;
            final contactGroups = <String, List<ContactGroup>>{};
            for (final row in rows) {
              contactGroups.putIfAbsent(row.$1, () => []).add(row.$2);
            }
            setState(() => _contactGroupsByGroup = contactGroups);
          },
        );
    _storiesSub =
        (() {
          final cutoff =
              clock.now().subtract(storyLifetime).millisecondsSinceEpoch ~/
              1000;
          return watchRustDatabase(
            (control) => rust_stories
                .watchReceivedStories(cutoff: cutoff, control: control)
                .map(receivedStoryItems),
          );
        })().listen((items) {
          if (!mounted || !_watching) return;
          final byGroup = <String, List<StoryItem>>{};
          for (final item in items) {
            byGroup.putIfAbsent(item.message.groupId, () => []).add(item);
          }
          setState(() => _storiesByGroup = byGroup);
          _scheduleReceivedStoryExpiry();
        });
    _ownStoriesSub =
        (() {
          final cutoff =
              clock.now().subtract(storyLifetime).millisecondsSinceEpoch ~/
              1000;
          return watchRustDatabase(
            (control) => rust_stories
                .watchOwnStories(cutoff: cutoff, control: control)
                .map(ownStoryItems),
          );
        })().listen((items) {
          if (!mounted || !_watching) return;
          setState(() => _ownStories = items);
          _scheduleOwnStoryExpiry();
        });
  }

  List<OwnStoryItem> get _activeOwnStories {
    final now = clock.now();
    return _ownStories.where((item) => item.isActiveAt(now)).toList();
  }

  List<StoryBubbleItem> get _storyBubbles {
    final contactsById = <int, ChatListContact>{
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
        final ChatListContact contact => getChatListContactDisplayName(contact),
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
        if (!mounted || !_watching) return;
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
        if (!mounted || !_watching) return;
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

  void _scheduleFlameDayRefresh() {
    _flameDayTimer?.cancel();
    final now = clock.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _flameDayTimer = Timer(tomorrow.difference(now), () {
      if (!_watching) return;
      _flameRefresh.add(null);
      _scheduleFlameDayRefresh();
    });
  }

  void _stopWatches() {
    if (!_watching) return;
    _watching = false;
    _flamesSub?.cancel();
    _flameDayTimer?.cancel();
    _contactsSub?.cancel();
    _contactsCountSub?.cancel();
    _countContactRequestStream?.cancel();
    _countAnnouncedStream?.cancel();
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopWatches();
    unawaited(_flameRefresh.close());
    _hasContacts.dispose();
    _badgeCount.dispose();
    super.dispose();
  }

  void _updateTypingGroupIds() {
    if (!mounted || !_watching) return;
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
          in _unopenedMessagesByGroup[groupId] ?? const <StoredMessage>[])
        if (message.mediaId != null) message.mediaId!,
      if (_lastMessageByGroup[groupId]?.mediaId != null)
        _lastMessageByGroup[groupId]!.mediaId!,
    };
    final mediaFiles = <String, MediaFile>{};
    for (final mediaId in mediaIds) {
      final mediaFile = _chatListMediaById[mediaId];
      if (mediaFile != null) mediaFiles[mediaId] = mediaFile;
    }
    final previous = _mediaByGroup[groupId];
    if (previous != null && mapEquals(previous, mediaFiles)) return previous;
    _mediaByGroup[groupId] = mediaFiles;
    return mediaFiles;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!widget.active || !_appVisible) return const SizedBox.shrink();
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
                  key: const PageStorageKey('chat-list'),
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
                        chatContacts:
                            _contactsByGroup[group.groupId] ?? const [],
                        flameState:
                            _flamesByGroup[group.groupId] ?? emptyFlameState,
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
                      chatContacts: _contactsByGroup[group.groupId] ?? const [],
                      flameState:
                          _flamesByGroup[group.groupId] ?? emptyFlameState,
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
