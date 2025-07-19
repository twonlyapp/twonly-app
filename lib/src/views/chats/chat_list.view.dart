import 'dart:async';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/providers/connection.provider.dart';
import 'package:twonly/src/services/api/media_download.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/camera/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/add_new_user.view.dart';
import 'package:twonly/src/views/chats/chat_list_components/backup_notice.card.dart';
import 'package:twonly/src/views/chats/chat_list_components/connection_info.comp.dart';
import 'package:twonly/src/views/chats/chat_list_components/demo_user.card.dart';
import 'package:twonly/src/views/chats/chat_list_components/last_message_time.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/chats/media_viewer.view.dart';
import 'package:twonly/src/views/chats/start_new_chat.view.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/message_send_state_icon.dart';
import 'package:twonly/src/views/components/notification_badge.dart';
import 'package:twonly/src/views/components/user_context_menu.dart';
import 'package:twonly/src/views/settings/help/changelog.view.dart';
import 'package:twonly/src/views/settings/help/contact_us.view.dart';
import 'package:twonly/src/views/settings/settings_main.view.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';
import 'package:twonly/src/views/tutorial/tutorials.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});
  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  late StreamSubscription<List<Contact>> _contactsSub;
  List<Contact> _contacts = [];
  List<Contact> _pinnedContacts = [];

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
    final stream = twonlyDB.contactsDao.watchContactsForChatList();
    _contactsSub = stream.listen((contacts) {
      setState(() {
        _contacts = contacts.where((x) => !x.pinned).toList();
        _pinnedContacts = contacts.where((x) => x.pinned).toList();
      });
    });

    tutorial = Timer(const Duration(seconds: 1), () async {
      tutorial = null;
      if (!mounted) return;
      await showChatListTutorialSearchOtherUsers(context, searchForOtherUsers);
      if (!mounted) return;
      if (_contacts.isNotEmpty) {
        await showChatListTutorialContextMenu(context, firstUserListItemKey);
      }
    });

    final user = await getUser();
    if (user == null) return;
    setState(() {
      showFeedbackShortcut = user.showFeedbackShortcut;
    });

    final changeLog = await rootBundle.loadString('CHANGELOG.md');
    final changeLogHash =
        (await compute(Sha256().hash, changeLog.codeUnits)).bytes;
    if (!user.hideChangeLog &&
        user.lastChangeLogHash.toString() != changeLogHash.toString()) {
      await updateUserdata((u) {
        u.lastChangeLogHash = changeLogHash;
        return u;
      });
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (context) {
        return ChangeLogView(
          changeLog: changeLog,
        );
      }));
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
        title: Row(children: [
          const Text('twonly '),
          if (planId != 'Free')
            GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const SubscriptionView();
                }));
              },
              child: Container(
                decoration: BoxDecoration(
                  color: context.color.primary,
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
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
        ]),
        actions: [
          if (showFeedbackShortcut)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ContactUsView(),
                  ),
                );
              },
              color: Colors.grey,
              tooltip: context.lang.feedbackTooltip,
              icon: const FaIcon(FontAwesomeIcons.commentDots, size: 19),
            ),
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsMainView(),
                ),
              );
            },
            icon: const FaIcon(FontAwesomeIcons.gear, size: 19),
          )
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
            child: (_contacts.isEmpty && _pinnedContacts.isEmpty)
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
                          label:
                              Text(context.lang.chatListViewSearchUserNameBtn)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await apiService.close(() {});
                      await apiService.connect(force: true);
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      itemCount: _pinnedContacts.length +
                          (_pinnedContacts.isNotEmpty ? 1 : 0) +
                          (gIsDemoUser ? 1 : 0) +
                          _contacts.length +
                          1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const BackupNoticeCard();
                        }
                        index -= 1;
                        if (gIsDemoUser) {
                          if (index == 0) {
                            return const DemoUserCard();
                          }
                          index -= 1;
                        }
                        // Check if the index is for the pinned users
                        if (index < _pinnedContacts.length) {
                          final contact = _pinnedContacts[index];
                          return UserListItem(
                            key: ValueKey(contact.userId),
                            user: contact,
                            firstUserListItemKey: (index == 0 && !gIsDemoUser ||
                                    index == 1 && gIsDemoUser)
                                ? firstUserListItemKey
                                : null,
                          );
                        }

                        // If there are pinned users, account for the Divider
                        var adjustedIndex = index - _pinnedContacts.length;
                        if (_pinnedContacts.isNotEmpty && adjustedIndex == 0) {
                          return const Divider();
                        }

                        // Adjust the index for the contacts list
                        adjustedIndex -= (_pinnedContacts.isNotEmpty ? 1 : 0);

                        // Get the contacts that are not pinned
                        final contact = _contacts.elementAt(
                          adjustedIndex,
                        );
                        return UserListItem(
                          key: ValueKey(contact.userId),
                          user: contact,
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
              MaterialPageRoute(builder: (context) {
                return const StartNewChatView();
              }),
            );
          },
          child: const FaIcon(FontAwesomeIcons.penToSquare),
        ),
      ),
    );
  }
}

class UserListItem extends StatefulWidget {
  const UserListItem({
    required this.user,
    required this.firstUserListItemKey,
    super.key,
  });
  final Contact user;
  final GlobalKey? firstUserListItemKey;

  @override
  State<UserListItem> createState() => _UserListItem();
}

class _UserListItem extends State<UserListItem> {
  MessageSendState state = MessageSendState.send;
  Message? currentMessage;

  List<Message> messagesNotOpened = [];
  late StreamSubscription<List<Message>> messagesNotOpenedStream;

  List<Message> lastMessages = [];
  late StreamSubscription<List<Message>> lastMessageStream;

  List<Message> previewMessages = [];

  @override
  void initState() {
    super.initState();
    initStreams();
  }

  @override
  void dispose() {
    messagesNotOpenedStream.cancel();
    lastMessageStream.cancel();
    super.dispose();
  }

  void initStreams() {
    lastMessageStream = twonlyDB.messagesDao
        .watchLastMessage(widget.user.userId)
        .listen((update) {
      updateState(update, messagesNotOpened);
    });

    messagesNotOpenedStream = twonlyDB.messagesDao
        .watchMessageNotOpened(widget.user.userId)
        .listen((update) {
      updateState(lastMessages, update);
    });
  }

  void updateState(
    List<Message> newLastMessages,
    List<Message> newMessagesNotOpened,
  ) {
    if (newLastMessages.isEmpty) {
      // there are no messages at all
      currentMessage = null;
      previewMessages = [];
    } else if (newMessagesNotOpened.isEmpty) {
      // there are no not opened messages show just the last message in the table
      currentMessage = newLastMessages.last;
      previewMessages = newLastMessages;
    } else {
      // filter first for received messages
      final receivedMessages =
          newMessagesNotOpened.where((x) => x.messageOtherId != null).toList();

      if (receivedMessages.isNotEmpty) {
        previewMessages = receivedMessages;
        currentMessage = receivedMessages.first;
      } else {
        previewMessages = newMessagesNotOpened;
        currentMessage = newMessagesNotOpened.first;
      }
    }

    lastMessages = newLastMessages;
    messagesNotOpened = newMessagesNotOpened;
    setState(() {
      // sets lastMessages, messagesNotOpened and currentMessage
    });
  }

  @override
  Widget build(BuildContext context) {
    final flameCounter = getFlameCounterFromContact(widget.user);

    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 50,
          child: SizedBox(
            key: widget.firstUserListItemKey,
            height: 20,
            width: 20,
          ),
        ),
        UserContextMenu(
          contact: widget.user,
          child: ListTile(
            title: Text(
              getContactDisplayName(widget.user),
            ),
            subtitle: (widget.user.deleted)
                ? Text(context.lang.userDeletedAccount)
                : (currentMessage == null)
                    ? Text(context.lang.chatsTapToSend)
                    : Row(
                        children: [
                          MessageSendStateIcon(previewMessages),
                          const Text('•'),
                          const SizedBox(width: 5),
                          if (currentMessage != null)
                            LastMessageTime(message: currentMessage!),
                          if (flameCounter > 0)
                            FlameCounterWidget(
                              widget.user,
                              flameCounter,
                              prefix: true,
                            ),
                        ],
                      ),
            leading: ContactAvatar(contact: widget.user),
            trailing: (widget.user.deleted)
                ? null
                : IconButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return CameraSendToView(widget.user);
                        },
                      ));
                    },
                    icon: FaIcon(FontAwesomeIcons.camera,
                        color: context.color.outline.withAlpha(150)),
                  ),
            onTap: () {
              if (currentMessage == null) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) {
                    return CameraSendToView(widget.user);
                  },
                ));
                return;
              }
              final msgs = previewMessages
                  .where((x) => x.kind == MessageKind.media)
                  .toList();
              if (msgs.isNotEmpty &&
                  msgs.first.kind == MessageKind.media &&
                  msgs.first.messageOtherId != null &&
                  msgs.first.openedAt == null) {
                switch (msgs.first.downloadState) {
                  case DownloadState.pending:
                    startDownloadMedia(msgs.first, true);
                    return;
                  case DownloadState.downloaded:
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return MediaViewerView(widget.user);
                      }),
                    );
                    return;
                  case DownloadState.downloading:
                    return;
                }
              }
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return ChatMessagesView(widget.user);
                }),
              );
            },
          ),
        )
      ],
    );
  }
}
