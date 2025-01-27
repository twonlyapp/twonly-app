import 'dart:collection';

import 'package:fixnum/fixnum.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/components/notification_badge.dart';
import 'package:twonly/src/components/user_context_menu.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/model/messages_model.dart';
import 'package:twonly/src/providers/notify_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chat_item_details_view.dart';
import 'package:twonly/src/views/search_username_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'dart:async';

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
        context.watch<NotifyProvider>().lastMessagesGroupedByUser;

    HashSet<Int64> sendingCurrentlyTo =
        context.watch<NotifyProvider>().sendingCurrentlyTo;

    List<Contact> activeUsers = context
        .read<NotifyProvider>()
        .allContacts
        .where((x) => lastMessages.containsKey(x.userId.toInt()))
        .toList();
    return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.chatsTitle),
          actions: [
            NotificationBadge(
              count: context.watch<NotifyProvider>().newContactRequests,
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
        body: Column(
          children: [
            // if (sendingCurrentlyTo.isNotEmpty)
            //   Container(
            //     padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            //     child: ListTile(
            //       leading: Stack(
            //         // child: Stack(
            //         alignment: Alignment.center,
            //         children: [
            //           CircularProgressIndicator(
            //             strokeWidth: 1,
            //           ),
            //           Icon(
            //             Icons.send, // Replace with your desired icon
            //             color: Theme.of(context).colorScheme.primary,
            //             size: 20, // Adjust the size as needed
            //           ),
            //         ],
            //         // ),
            //       ),
            //       title: Text(sendingCurrentlyTo
            //           .map((e) => _activeUsers
            //               .where((c) => c.userId == e)
            //               .map((c) => c.displayName))
            //           .toList()
            //           .join(", ")),
            //     ),
            // ), //
            Expanded(
              child: ListView.builder(
                restorationId: 'chat_list_view',
                itemCount: activeUsers.length,
                itemBuilder: (BuildContext context, int index) {
                  final user = activeUsers[index];
                  return UserListItem(
                    user: user,
                    lastMessage: lastMessages[user.userId.toInt()]!,
                    isSending: sendingCurrentlyTo.contains(user.userId),
                  );
                },
              ),
            )
          ],
        ));
  }
}

class UserListItem extends StatefulWidget {
  final Contact user;
  final DbMessage lastMessage;
  final bool isSending;

  const UserListItem({
    super.key,
    required this.user,
    required this.isSending,
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
    //_loadAsync();
  }

  Future _loadAsync() async {
    // flames = await widget.user.getFlames();
    // lastMessageInSeconds = await widget.user.getLastMessageInSeconds();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    MessageSendState state;
    // int lastMessageInSeconds = widget.lastMessage.sendOrReceivedAt;
    //print(widget.lastMessage.sendOrReceivedAt);
    int lastMessageInSeconds = DateTime.now()
        .difference(widget.lastMessage.sendOrReceivedAt)
        .inSeconds;

    if (widget.isSending) {
      state = MessageSendState.sending;
    } else {
      if (widget.lastMessage.messageOtherId == null) {
        // message send
        if (widget.lastMessage.messageOpenedAt == null) {
          state = MessageSendState.send;
        } else {
          state = MessageSendState.sendOpened;
        }
      } else {
        // message received
        if (widget.lastMessage.messageOpenedAt == null) {
          state = MessageSendState.received;
        } else {
          state = MessageSendState.receivedOpened;
        }
      }
    }

    return UserContextMenu(
      user: widget.user,
      child: ListTile(
        title: Text(widget.user.displayName),
        subtitle: Row(
          children: [
            MessageSendStateIcon(state),
            Text("•"),
            const SizedBox(width: 5),
            Text(
              formatDuration(lastMessageInSeconds),
              style: TextStyle(fontSize: 12),
            ),
            if (flames > 0)
              Row(
                children: [
                  const SizedBox(width: 5),
                  Text("•"),
                  const SizedBox(width: 5),
                  Text(
                    flames.toString(),
                    style: TextStyle(fontSize: 12),
                  ),
                  Icon(
                    Icons.local_fire_department_sharp,
                    color: const Color.fromARGB(255, 215, 73, 58),
                    size: 16,
                  ),
                ],
              ),
          ],
        ),
        leading: InitialsAvatar(displayName: widget.user.displayName),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SampleItemDetailsView(
                user: widget.user,
              ),
            ),
          );
        },
      ),
    );
  }
}
