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
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/chats/add_new_user.view.dart';
import 'package:twonly/src/views/chats/archived_chats.view.dart';
import 'package:twonly/src/views/chats/chat_list_components/connection_info.comp.dart';
import 'package:twonly/src/views/chats/chat_list_components/feedback_btn.dart';
import 'package:twonly/src/views/chats/chat_list_components/group_list_item.dart';
import 'package:twonly/src/views/chats/start_new_chat.view.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/notification_badge.dart';
import 'package:twonly/src/views/public_profile.view.dart';
import 'package:twonly/src/views/settings/help/changelog.view.dart';
import 'package:twonly/src/views/settings/profile/profile.view.dart';
import 'package:twonly/src/views/settings/settings_main.view.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';
import 'package:twonly/src/views/user_study/user_study_welcome.view.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});
  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  late StreamSubscription<List<Group>> _contactsSub;
  List<Group> _groupsNotPinned = [];
  List<Group> _groupsPinned = [];
  List<Group> _groupsArchived = [];

  GlobalKey searchForOtherUsers = GlobalKey();
  bool showFeedbackShortcut = false;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    final stream = twonlyDB.groupsDao.watchGroupsForChatList();
    _contactsSub = stream.listen((groups) {
      setState(() {
        _groupsNotPinned =
            groups.where((x) => !x.pinned && !x.archived).toList();
        _groupsPinned = groups.where((x) => x.pinned && !x.archived).toList();
        _groupsArchived = groups.where((x) => x.archived).toList();
      });
    });

    // In case the user is already a Tester, ask him for permission.

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (gUser.subscriptionPlan == SubscriptionPlan.Tester.name &&
          !gUser.askedForUserStudyPermission) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const UserStudyWelcomeView(
                wasOpenedAutomatic: true,
              );
            },
          ),
        );
      }

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
    });
  }

  @override
  void dispose() {
    _contactsSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<CustomChangeProvider>().isConnected;
    final plan = context.watch<PurchasesProvider>().plan;
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
                myAvatar: true,
                fontSize: 14,
                color: context.color.onSurface.withAlpha(20),
              ),
            ),
            const SizedBox(width: 10),
            const Text('twonly '),
            if (plan != SubscriptionPlan.Free)
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
            child: RefreshIndicator(
              onRefresh: () async {
                await apiService.close(() {});
                await apiService.connect();
                await Future.delayed(const Duration(seconds: 1));
              },
              child: (_groupsNotPinned.isEmpty &&
                      _groupsPinned.isEmpty &&
                      _groupsArchived.isEmpty)
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
                          label: Text(
                            context.lang.chatListViewSearchUserNameBtn,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _groupsPinned.length +
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) {
                                    return const ArchivedChatsView();
                                  },
                                ),
                              );
                            },
                          );
                        }
                        // Check if the index is for the pinned users
                        if (index < _groupsPinned.length) {
                          final group = _groupsPinned[index];
                          return GroupListItem(
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
                        return GroupListItem(
                          key: ValueKey(group.groupId),
                          group: group,
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Material(
              elevation: 3,
              shape: const CircleBorder(),
              color: context.color.primary,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return const PublicProfileView();
                      },
                    ),
                  );
                },
                child: SizedBox(
                  width: 45,
                  height: 45,
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.qrcode,
                      color: isDarkMode(context) ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              backgroundColor: context.color.primary,
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
              child: FaIcon(
                FontAwesomeIcons.penToSquare,
                color: isDarkMode(context) ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
