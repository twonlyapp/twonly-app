import 'dart:async';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/components/notification_badge.dart';
import 'package:twonly/src/components/user_context_menu.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/providers/download_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/providers/send_next_media_to.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';
import 'package:twonly/src/views/home_view.dart';
import 'package:twonly/src/views/settings/settings_main_view.dart';
import 'package:twonly/src/views/chats/search_username_view.dart';
import 'package:flutter/material.dart';

/// Displays a list of SampleItems.
class ChatListView extends StatefulWidget {
  const ChatListView({super.key});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  @override
  Widget build(BuildContext context) {
    Map<int, DbMessage> lastMessages =
        context.watch<MessagesChangeProvider>().lastMessage;

    List<Contact> allUsers = context
        .watch<ContactChangeProvider>()
        .allContacts
        .where((c) => c.accepted)
        .toList();

    allUsers.sort((b, a) {
      DbMessage? msgA = lastMessages[a.userId.toInt()];
      DbMessage? msgB = lastMessages[b.userId.toInt()];
      if (msgA == null) return 1;
      if (msgB == null) return -1;
      return msgA.sendAt.compareTo(msgB.sendAt);
    });

    int maxTotalMediaCounter = 0;
    if (allUsers.isNotEmpty) {
      maxTotalMediaCounter = allUsers
          .map((x) => x.totalMediaCounter)
          .reduce((a, b) => a > b ? a : b);
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileView(),
              ),
            );
          },
          child: Text("twonly"),
        ),
        // title:
        actions: [
          NotificationBadge(
            count: context
                .watch<ContactChangeProvider>()
                .newContactRequests
                .toString(),
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
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileView(),
                ),
              );
            },
            icon: FaIcon(FontAwesomeIcons.gear, size: 19),
          )
        ],
      ),
      body: (allUsers.isEmpty)
          ? Center(
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
                    label: Text(context.lang.chatListViewSearchUserNameBtn)),
              ),
            )
          : ListView.builder(
              restorationId: 'chat_list_view',
              itemCount: allUsers.length,
              itemBuilder: (BuildContext context, int index) {
                final user = allUsers[index];
                return UserListItem(
                  user: user,
                  maxTotalMediaCounter: maxTotalMediaCounter,
                  lastMessage: lastMessages[user.userId.toInt()],
                );
              },
            ),
    );
  }
}

class UserListItem extends StatefulWidget {
  final Contact user;
  final DbMessage? lastMessage;
  final int maxTotalMediaCounter;

  const UserListItem(
      {super.key,
      required this.user,
      required this.lastMessage,
      required this.maxTotalMediaCounter});

  @override
  State<UserListItem> createState() => _UserListItem();
}

class _UserListItem extends State<UserListItem> {
  int lastMessageInSeconds = 0;
  MessageSendState state = MessageSendState.send;
  bool isDownloading = false;
  List<int> token = [];

  Timer? updateTime;

  @override
  void initState() {
    super.initState();
    lastUpdateTime();
  }

  void lastUpdateTime() {
    // Change the color every 200 milliseconds
    updateTime = Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        lastMessageInSeconds =
            calculateTimeDifference(DateTime.now(), widget.lastMessage!.sendAt)
                .inSeconds;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    updateTime?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lastMessage != null) {
      state = widget.lastMessage!.getSendState();

      final content = widget.lastMessage!.messageContent;

      if (widget.lastMessage!.messageReceived &&
          content is MediaMessageContent) {
        token = content.downloadToken;
        isDownloading = context
            .watch<DownloadChangeProvider>()
            .currentlyDownloading
            .contains(token.toString());
      }
    }

    int flameCounter = context
            .watch<MessagesChangeProvider>()
            .flamesCounter[widget.user.userId.toInt()] ??
        0;

    return UserContextMenu(
      user: widget.user,
      child: ListTile(
        title: Text(widget.user.displayName),
        subtitle: (widget.lastMessage == null)
            ? Text(context.lang.chatsTapToSend)
            : Row(
                children: [
                  MessageSendStateIcon(widget.lastMessage!),
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
        leading: InitialsAvatar(displayName: widget.user.displayName),
        onTap: () {
          if (widget.lastMessage == null) {
            context
                .read<SendNextMediaTo>()
                .updateSendNextMediaTo(widget.user.userId.toInt());
            globalUpdateOfHomeViewPageIndex(0);
            return;
          }
          if (isDownloading) return;
          if (!widget.lastMessage!.isDownloaded) {
            tryDownloadMedia(widget.lastMessage!.messageId,
                widget.lastMessage!.otherUserId, token,
                force: true);
            return;
          }
          if (state == MessageSendState.received &&
              widget.lastMessage!.containsOtherMedia()) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return MediaViewerView(widget.user, widget.lastMessage!);
              }),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return ChatItemDetailsView(user: widget.user);
            }),
          );
        },
      ),
    );
  }
}
