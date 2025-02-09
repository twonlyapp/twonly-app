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
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';
import 'package:twonly/src/views/home_view.dart';
import 'package:twonly/src/views/chats/media_viewer_view.dart';
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

    List<Contact> activeUsers = allUsers
        .where((x) => lastMessages.containsKey(x.userId.toInt()))
        .toList();
    activeUsers.sort((b, a) {
      return lastMessages[a.userId.toInt()]!
          .sendAt
          .compareTo(lastMessages[b.userId.toInt()]!.sendAt);
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
      body: (activeUsers.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: OutlinedButton.icon(
                    icon: Icon((allUsers.isEmpty)
                        ? Icons.person_add
                        : Icons.camera_alt),
                    onPressed: () {
                      (allUsers.isEmpty)
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchUsernameView(),
                              ),
                            )
                          : globalUpdateOfHomeViewPageIndex(0);
                    },
                    label: Text((allUsers.isEmpty)
                        ? context.lang.chatListViewSearchUserNameBtn
                        : context.lang.chatListViewSendFirstTwonly)),
              ),
            )
          : ListView.builder(
              restorationId: 'chat_list_view',
              itemCount: activeUsers.length,
              itemBuilder: (BuildContext context, int index) {
                final user = activeUsers[index];
                return UserListItem(
                  user: user,
                  maxTotalMediaCounter: maxTotalMediaCounter,
                  lastMessage: lastMessages[user.userId.toInt()]!,
                );
              },
            ),
    );
  }
}

class UserListItem extends StatefulWidget {
  final Contact user;
  final DbMessage lastMessage;
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

  @override
  Widget build(BuildContext context) {
    int lastMessageInSeconds =
        DateTime.now().difference(widget.lastMessage.sendAt).inSeconds;

    MessageSendState state = widget.lastMessage.getSendState();
    bool isDownloading = false;

    final content = widget.lastMessage.messageContent;
    List<int> token = [];

    if (widget.lastMessage.messageReceived && content is MediaMessageContent) {
      token = content.downloadToken;
      isDownloading = context
          .watch<DownloadChangeProvider>()
          .currentlyDownloading
          .contains(token.toString());
    }

    int flameCounter = context
            .watch<MessagesChangeProvider>()
            .flamesCounter[widget.user.userId.toInt()] ??
        0;

    return UserContextMenu(
      user: widget.user,
      child: ListTile(
        title: Text(widget.user.displayName),
        subtitle: Row(
          children: [
            MessageSendStateIcon(widget.lastMessage),
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
          if (isDownloading) return;
          if (!widget.lastMessage.isDownloaded) {
            tryDownloadMedia(widget.lastMessage.messageId,
                widget.lastMessage.otherUserId, token,
                force: true);
            return;
          }
          if (state == MessageSendState.received &&
              widget.lastMessage.containsOtherMedia()) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return MediaViewerView(widget.user, widget.lastMessage);
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
