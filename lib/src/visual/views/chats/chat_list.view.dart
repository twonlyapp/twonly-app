import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/connection_status.comp.dart';
import 'package:twonly/src/visual/components/notification_badge.comp.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/empty_chat_list.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/feedback_btn.comp.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/group_list_item.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/finish_setup.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/missing_backup_setup.comp.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});
  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> with AutomaticKeepAliveClientMixin<ChatListView> {
  StreamSubscription<void>? _userSub;
  StreamSubscription<List<Group>>? _contactsSub;
  StreamSubscription<List<Contact>>? _contactsCountSub;
  StreamSubscription<List<MediaFile>>? _precacheSub;
  final Set<String> _precachedMediaIds = {};
  List<Group> _groupsNotPinned = [];
  List<Group> _groupsPinned = [];
  List<Group> _groupsArchived = [];

  bool _hasContacts = false;
  bool _loading = true;
  bool get _hasOpenGroup =>
      _groupsNotPinned.isNotEmpty ||
      _groupsArchived.isNotEmpty ||
      _groupsPinned.isNotEmpty;

  GlobalKey searchForOtherUsers = GlobalKey();
  bool showFeedbackShortcut = false;

  int _countContactRequest = 0;
  int _countAnnouncedUsers = 0;
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
      setState(() {
        _hasContacts = contacts.isNotEmpty;
      });
    });

    _countContactRequestStream = twonlyDB.contactsDao
        .watchContactsRequestedCount()
        .listen((update) {
          if (update != null) {
            if (!mounted) return;
            setState(() {
              _countContactRequest = update;
            });
          }
        });

    _countAnnouncedStream = twonlyDB.userDiscoveryDao
        .watchNewAnnouncementsWithDataCount()
        .listen((update) {
          if (!mounted) return;
          setState(() {
            _countAnnouncedUsers = update;
          });
        });

    _precacheSub = twonlyDB.messagesDao.watchUnopenedMediaFiles().listen((mediaFiles) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final plan = context.watch<PurchasesProvider>().plan;
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
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          const FeedbackIconButtonComp(),
          Stack(
            children: [
              if (_countAnnouncedUsers + _countContactRequest > 0)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              Center(
                child: NotificationBadgeComp(
                  backgroundColor: isDarkMode(context)
                      ? Colors.white
                      : Colors.black,
                  textColor: isDarkMode(context) ? Colors.black : Colors.white,
                  count: (_countAnnouncedUsers + _countContactRequest)
                      .toString(),
                  child: IconButton(
                    color: (_countAnnouncedUsers + _countContactRequest > 0)
                        ? Colors.black
                        : null,
                    key: searchForOtherUsers,
                    icon: const FaIcon(FontAwesomeIcons.userPlus, size: 18),
                    onPressed: () => context.push(Routes.chatsAddNewUser),
                  ),
                ),
              ),
            ],
          ),

          IconButton(
            onPressed: () => context.push(Routes.settings),
            icon: const FaIcon(FontAwesomeIcons.gear, size: 19),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await apiService.close(() {});
          await apiService.connect();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: Column(
          children: [
            const FinishSetupComp(),
            const MissingBackupComp(),
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
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: !_hasContacts
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'qrcode_fab',
                    elevation: 2,
                    backgroundColor: isDarkMode(context)
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    foregroundColor: isDarkMode(context)
                        ? Colors.white
                        : Colors.black87,
                    onPressed: () => context.push(Routes.settingsPublicProfile),
                    child: FaIcon(
                      FontAwesomeIcons.qrcode,
                      color: isDarkMode(context)
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    heroTag: 'new_chat_fab',
                    elevation: 2,
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black87,
                    onPressed: () => context.push(Routes.chatsStartNewChat),
                    child: const FaIcon(
                      FontAwesomeIcons.penToSquare,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
