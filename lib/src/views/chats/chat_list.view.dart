import 'dart:async';
import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/chats/add_new_user.view.dart';
import 'package:twonly/src/views/chats/chat_list_components/backup_notice.card.dart';
import 'package:twonly/src/views/chats/chat_list_components/connection_info.comp.dart';
import 'package:twonly/src/views/chats/chat_list_components/feedback_btn.dart';
import 'package:twonly/src/views/chats/chat_list_components/group_list_item.dart';
import 'package:twonly/src/views/chats/start_new_chat.view.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/notification_badge.dart';
import 'package:twonly/src/views/settings/help/changelog.view.dart';
import 'package:twonly/src/views/settings/profile/profile.view.dart';
import 'package:twonly/src/views/settings/settings_main.view.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';
import 'package:twonly/src/views/tutorial/tutorials.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});
  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  late StreamSubscription<List<Group>> _contactsSub;
  List<Group> _groupsNotPinned = [];
  List<Group> _groupsPinned = [];

  GlobalKey firstUserListItemKey = GlobalKey();
  GlobalKey searchForOtherUsers = GlobalKey();
  Timer? tutorial;
  bool showFeedbackShortcut = false;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    final stream = twonlyDB.groupsDao.watchGroups();
    _contactsSub = stream.listen((groups) {
      setState(() {
        _groupsNotPinned = groups.where((x) => !x.pinned).toList();
        _groupsPinned = groups.where((x) => x.pinned).toList();
      });
    });

    tutorial = Timer(const Duration(seconds: 1), () async {
      tutorial = null;
      if (!mounted) return;
      await showChatListTutorialSearchOtherUsers(context, searchForOtherUsers);
      if (!mounted) return;
      if (_groupsNotPinned.isNotEmpty) {
        await showChatListTutorialContextMenu(context, firstUserListItemKey);
      }
    });

    final changeLog = await rootBundle.loadString('CHANGELOG.md');
    final changeLogHash =
        (await compute(Sha256().hash, changeLog.codeUnits)).bytes;
    if (!gUser.hideChangeLog &&
        gUser.lastChangeLogHash.toString() != changeLogHash.toString()) {
      await updateUserdata((u) {
        u.lastChangeLogHash = changeLogHash;
        return u;
      });
      if (!mounted) return;
      // only show changelog to people who already have contacts
      // this prevents that this is shown directly after the user registered
      if (_groupsNotPinned.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ChangeLogView(
                changeLog: changeLog,
              );
            },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    tutorial?.cancel();
    _contactsSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<CustomChangeProvider>().isConnected;
    final planId = context.watch<CustomChangeProvider>().plan;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const ProfileView();
                    },
                  ),
                );
                if (!mounted) return;
                setState(() {}); // gUser has updated
              },
              child: AvatarIcon(
                userData: gUser,
                fontSize: 14,
                color: context.color.onSurface.withAlpha(20),
              ),
            ),
            const SizedBox(width: 10),
            const Text('twonly '),
            if (planId != 'Free')
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const SubscriptionView();
                      },
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: context.color.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Text(
                    planId,
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
          const FeedbackIconButton(),
          StreamBuilder(
            stream: twonlyDB.contactsDao.watchContactsRequested(),
            builder: (context, snapshot) {
              var count = 0;
              if (snapshot.hasData && snapshot.data != null) {
                count = snapshot.data!;
              }
              return NotificationBadge(
                count: count.toString(),
                child: IconButton(
                  key: searchForOtherUsers,
                  icon: const FaIcon(FontAwesomeIcons.userPlus, size: 18),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddNewUserView(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsMainView(),
                ),
              );
              if (!mounted) return;
              setState(() {}); // gUser may has changed...
            },
            icon: const FaIcon(FontAwesomeIcons.gear, size: 19),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: isConnected ? Container() : const ConnectionInfo(),
          ),
          Positioned.fill(
            child: (_groupsNotPinned.isEmpty && _groupsPinned.isEmpty)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_add),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNewUserView(),
                            ),
                          );
                        },
                        label: Text(context.lang.chatListViewSearchUserNameBtn),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await apiService.close(() {});
                      await apiService.connect(force: true);
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      itemCount: _groupsPinned.length +
                          (_groupsPinned.isNotEmpty ? 1 : 0) +
                          _groupsNotPinned.length +
                          1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const BackupNoticeCard();
                        }
                        index -= 1;
                        // Check if the index is for the pinned users
                        if (index < _groupsPinned.length) {
                          final group = _groupsPinned[index];
                          return GroupListItem(
                            key: ValueKey(group.groupId),
                            group: group,
                            firstUserListItemKey: (index == 0 || index == 1)
                                ? firstUserListItemKey
                                : null,
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
                        return GroupListItem(
                          key: ValueKey(group.groupId),
                          group: group,
                          firstUserListItemKey:
                              (index == 0) ? firstUserListItemKey : null,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return const StartNewChatView();
                },
              ),
            );
          },
          child: const FaIcon(FontAwesomeIcons.penToSquare),
        ),
      ),
    );
  }
}
