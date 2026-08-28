import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/connection_status.comp.dart';
import 'package:twonly/src/visual/components/notification_badge.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/empty_chat_list.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/group_list_item.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/news_btn.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_messages_components/typing_indicator.dart';
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
  StreamSubscription<List<(int, Label)>>? _contactLabelsSub;
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
  Map<int, List<Label>> _labelsByContact = {};

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
    _contactLabelsSub = twonlyDB.labelsDao.watchAllContactLabels().listen((
      rows,
    ) {
      if (!mounted) return;
      final labels = <int, List<Label>>{};
      for (final row in rows) {
        labels.putIfAbsent(row.$1, () => []).add(row.$2);
      }
      setState(() => _labelsByContact = labels);
    });
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
    _contactLabelsSub?.cancel();
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
    final dark = isDarkMode(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ConnectionStatusComp(
              child: GestureDetector(
                onTap: () => context.push(Routes.settingsProfile),
                child: AvatarIcon(
                  myAvatar: true,
                  fontSize: 14,
                  color: context.color.onSurface.withAlpha(20),
                ),
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
                      color: dark ? Colors.black : Colors.white,
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
                      backgroundColor: dark ? Colors.white : Colors.black,
                      textColor: dark ? Colors.black : Colors.white,
                      count: badgeCount.toString(),
                      child: IconButton(
                        color: badgeCount > 0 ? Colors.black : null,
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
                      _groupsPinned.length +
                      (_groupsPinned.isNotEmpty ? 1 : 0) +
                      _groupsNotPinned.length +
                      (_groupsArchived.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
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
                        contactLabels:
                            _contactsByGroup[group.groupId]?.isNotEmpty == true
                            ? _labelsByContact[_contactsByGroup[group.groupId]!
                                      .first
                                      .userId] ??
                                  const []
                            : const [],
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
                      contactLabels:
                          _contactsByGroup[group.groupId]?.isNotEmpty == true
                          ? _labelsByContact[_contactsByGroup[group.groupId]!
                                    .first
                                    .userId] ??
                                const []
                          : const [],
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
                  backgroundColor: dark ? Colors.grey[800] : Colors.grey[200],
                  foregroundColor: dark ? Colors.white : Colors.black87,
                  onPressed: () => context.push(Routes.settingsPublicProfile),
                  child: FaIcon(
                    FontAwesomeIcons.qrcode,
                    color: dark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'new_chat_fab',
                  elevation: 2,
                  backgroundColor: context.color.primary,
                  foregroundColor: Colors.black87,
                  onPressed: () => context.push(Routes.chatsStartNewChat),
                  child: const FaIcon(
                    FontAwesomeIcons.penToSquare,
                    color: Colors.black87,
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
