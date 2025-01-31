import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/components/notification_badge.dart';
import 'package:twonly/src/components/user_context_menu.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/providers/download_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chat_item_details_view.dart';
import 'package:twonly/src/views/home_view.dart';
import 'package:twonly/src/views/media_viewer_view.dart';
import 'package:twonly/src/views/search_username_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatItem {
  const ChatItem(
      {required this.username,
      required this.flames,
      required this.userId,
      required this.state,
      required this.lastMessageInSeconds});
  final String username;
  final int lastMessageInSeconds;
  final int flames;
  final int userId;
  final MessageSendState state;
}

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
        .read<ContactChangeProvider>()
        .allContacts
        .where((c) => c.accepted)
        .toList();

    List<Contact> activeUsers = allUsers
        .where((x) => lastMessages.containsKey(x.userId.toInt()))
        .toList();
    activeUsers.sort((b, a) {
      return lastMessages[a.userId.toInt()]!
          .sendOrReceivedAt
          .compareTo(lastMessages[b.userId.toInt()]!.sendOrReceivedAt);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.chatsTitle),
        actions: [
          NotificationBadge(
            count: context.watch<ContactChangeProvider>().newContactRequests,
            child: IconButton(
              icon: Icon(Icons.person_add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchUsernameView(),
                  ),
                );
              },
            ),
          )
        ],
      ),
      body: (activeUsers.isEmpty)
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: OutlinedButton.icon(
                    icon: Icon((activeUsers.isEmpty)
                        ? Icons.person_add
                        : Icons.camera_alt),
                    onPressed: () {
                      (activeUsers.isEmpty)
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchUsernameView(),
                              ),
                            )
                          : globalUpdateOfHomeViewPageIndex(1);
                    },
                    label: Text((activeUsers.isEmpty)
                        ? AppLocalizations.of(context)!
                            .chatListViewSearchUserNameBtn
                        : AppLocalizations.of(context)!
                            .chatListViewSendFirstTwonly)),
              ),
            )
          : ListView.builder(
              restorationId: 'chat_list_view',
              itemCount: activeUsers.length,
              itemBuilder: (BuildContext context, int index) {
                final user = activeUsers[index];
                return UserListItem(
                  user: user,
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

  const UserListItem({
    super.key,
    required this.user,
    required this.lastMessage,
  });

  @override
  State<UserListItem> createState() => _UserListItem();
}

class _UserListItem extends State<UserListItem> {
  int flames = 0;
  int lastMessageInSeconds = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int lastMessageInSeconds = DateTime.now()
        .difference(widget.lastMessage.sendOrReceivedAt)
        .inSeconds;

    MessageSendState state = widget.lastMessage.getSendState();
    bool isDownloading = false;

    if (widget.lastMessage.messageContent != null &&
        widget.lastMessage.messageContent!.downloadToken != null) {
      isDownloading = context
          .watch<DownloadChangeProvider>()
          .currentlyDownloading
          .contains(
              widget.lastMessage.messageContent!.downloadToken!.toString());
    }

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
            if (widget.user.flameCounter > 0)
              Row(
                children: [
                  const SizedBox(width: 5),
                  Text("•"),
                  const SizedBox(width: 5),
                  Text(
                    widget.user.flameCounter.toString(),
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 3),
                  Image.asset(
                    "assets/icons/flame.png",
                    width: 9,
                  ),
                  // FaIcon(
                  //   FontAwesomeIcons.fireFlameCurved,
                  //   color: const Color.fromARGB(255, 215, 131, 58),
                  //   size: 10,
                  // ),
                ],
              ),
          ],
        ),
        leading: InitialsAvatar(displayName: widget.user.displayName),
        onTap: () {
          if (isDownloading) return;
          if (!widget.lastMessage.isDownloaded) {
            List<int> token = widget.lastMessage.messageContent!.downloadToken!;
            tryDownloadMedia(token, force: true);
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
