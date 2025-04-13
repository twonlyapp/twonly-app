import 'dart:async';
import 'dart:convert';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/connection_state.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/components/notification_badge.dart';
import 'package:twonly/src/components/user_context_menu.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/json_models/message.dart';
import 'package:twonly/src/providers/api/media.dart';
import 'package:twonly/src/providers/connection_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera_to_share/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';
import 'package:twonly/src/views/chats/start_new_chat.dart';
import 'package:twonly/src/views/settings/settings_main_view.dart';
import 'package:twonly/src/views/chats/search_username_view.dart';
import 'package:flutter/material.dart';

class ChatListView extends StatefulWidget {
  const ChatListView({super.key});
  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  @override
  Widget build(BuildContext context) {
    bool isConnected = context.watch<ConnectionChangeProvider>().isConnected;
    return Scaffold(
      appBar: AppBar(
        title: Text("twonly"),
        actions: [
          StreamBuilder(
            stream: twonlyDatabase.contactsDao.watchContactsRequested(),
            builder: (context, snapshot) {
              var count = 0;
              if (snapshot.hasData && snapshot.data != null) {
                count = snapshot.data!;
              }
              return NotificationBadge(
                count: count.toString(),
                child: IconButton(
                  icon: FaIcon(FontAwesomeIcons.userPlus, size: 18),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchUsernameView(),
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
                  builder: (context) => SettingsMainView(),
                ),
              );
            },
            icon: FaIcon(FontAwesomeIcons.gear, size: 19),
          )
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: isConnected ? Container() : ConnectionInfo(),
          ),
          Positioned.fill(
            child: StreamBuilder(
              stream: twonlyDatabase.contactsDao.watchContactsForChatList(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Container();
                }

                var contacts = snapshot.data!;
                if (contacts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: OutlinedButton.icon(
                          icon: Icon(Icons.person_add),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchUsernameView(),
                              ),
                            );
                          },
                          label:
                              Text(context.lang.chatListViewSearchUserNameBtn)),
                    ),
                  );
                }

                int maxTotalMediaCounter = 0;
                if (contacts.isNotEmpty) {
                  maxTotalMediaCounter = contacts
                      .map((x) => x.totalMediaCounter)
                      .reduce((a, b) => a > b ? a : b);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await apiProvider.close(() {});
                    await apiProvider.connect();
                    await Future.delayed(Duration(seconds: 1));
                  },
                  child: ListView.builder(
                    restorationId: 'chat_list_view',
                    itemCount: contacts.length,
                    itemBuilder: (BuildContext context, int index) {
                      final user = contacts[index];
                      return UserListItem(
                        key: ValueKey(user.userId),
                        user: user,
                        maxTotalMediaCounter: maxTotalMediaCounter,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: FloatingActionButton(
          foregroundColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return StartNewChat();
              }),
            );
          },
          child: FaIcon(FontAwesomeIcons.penToSquare),
        ),
      ),
    );
  }
}

class UserListItem extends StatefulWidget {
  final Contact user;
  final int maxTotalMediaCounter;

  const UserListItem({
    super.key,
    required this.user,
    required this.maxTotalMediaCounter,
  });

  @override
  State<UserListItem> createState() => _UserListItem();
}

class _UserListItem extends State<UserListItem> {
  int lastMessageInSeconds = 0;
  MessageSendState state = MessageSendState.send;
  Message? currentMessage;

  List<Message> messagesNotOpened = [];
  late StreamSubscription<List<Message>> messagesNotOpenedStream;

  List<Message> lastMessages = [];
  late StreamSubscription<List<Message>> lastMessageStream;

  List<Message> previewMessages = [];

  Timer? updateTime;

  @override
  void initState() {
    super.initState();
    initStreams();
    lastUpdateTime();
  }

  @override
  void dispose() {
    updateTime?.cancel();
    messagesNotOpenedStream.cancel();
    lastMessageStream.cancel();
    super.dispose();
  }

  void initStreams() {
    lastMessageStream = twonlyDatabase.messagesDao
        .watchLastMessage(widget.user.userId)
        .listen((update) {
      updateState(update, messagesNotOpened);
    });

    messagesNotOpenedStream = twonlyDatabase.messagesDao
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

  void lastUpdateTime() {
    // Change the color every 200 milliseconds
    updateTime = Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        if (currentMessage != null) {
          lastMessageInSeconds =
              (DateTime.now().difference(currentMessage!.sendAt)).inSeconds;
          if (lastMessageInSeconds < 0) {
            lastMessageInSeconds = 0;
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int flameCounter = getFlameCounterFromContact(widget.user);

    return UserContextMenu(
      contact: widget.user,
      child: ListTile(
        title: Text(getContactDisplayName(widget.user)),
        subtitle: (currentMessage == null)
            ? Text(context.lang.chatsTapToSend)
            : Row(
                children: [
                  MessageSendStateIcon(previewMessages),
                  Text("•"),
                  const SizedBox(width: 5),
                  Text(
                    formatDuration(lastMessageInSeconds),
                    style: TextStyle(fontSize: 12),
                  ),
                  if (flameCounter > 0)
                    FlameCounterWidget(
                      widget.user,
                      flameCounter,
                      widget.maxTotalMediaCounter,
                      prefix: true,
                    ),
                ],
              ),
        leading: ContactAvatar(contact: widget.user),
        trailing: IconButton(
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
          List<Message> msgs = previewMessages
              .where((x) => x.kind == MessageKind.media)
              .toList();
          if (msgs.isNotEmpty &&
              msgs.first.kind == MessageKind.media &&
              msgs.first.messageOtherId != null &&
              msgs.first.openedAt == null) {
            switch (msgs.first.downloadState) {
              case DownloadState.pending:
                MediaMessageContent content = MediaMessageContent.fromJson(
                    jsonDecode(msgs.first.contentJson!));
                tryDownloadMedia(
                    msgs.first.messageId, msgs.first.contactId, content,
                    force: true);
              case DownloadState.downloaded:
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return MediaViewerView(widget.user);
                  }),
                );
              default:
            }
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return ChatItemDetailsView(widget.user);
            }),
          );
        },
      ),
    );
  }
}
