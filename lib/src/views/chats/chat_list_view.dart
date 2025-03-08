import 'dart:async';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/message_send_state_icon.dart';
import 'package:twonly/src/components/notification_badge.dart';
import 'package:twonly/src/components/user_context_menu.dart';
import 'package:twonly/src/database/contacts_db.dart';
import 'package:twonly/src/database/database.dart';
import 'package:twonly/src/database/messages_db.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
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
    Stream<List<Contact>> contacts = context.db.watchContactsForChatList();

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
            StreamBuilder(
              stream: context.db.watchContactsRequested(),
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
                    builder: (context) => ProfileView(),
                  ),
                );
              },
              icon: FaIcon(FontAwesomeIcons.gear, size: 19),
            )
          ],
        ),
        body: StreamBuilder(
          stream: contacts,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Container();
            }

            final contacts = snapshot.data!;
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
                                builder: (context) => SearchUsernameView()));
                      },
                      label: Text(context.lang.chatListViewSearchUserNameBtn)),
                ),
              );
            }

            int maxTotalMediaCounter = 0;
            if (contacts.isNotEmpty) {
              maxTotalMediaCounter = contacts
                  .map((x) => x.totalMediaCounter)
                  .reduce((a, b) => a > b ? a : b);
            }

            return ListView.builder(
              restorationId: 'chat_list_view',
              itemCount: contacts.length,
              itemBuilder: (BuildContext context, int index) {
                final user = contacts[index];
                return UserListItem(
                  user: user,
                  maxTotalMediaCounter: maxTotalMediaCounter,
                );
              },
            );
          },
        ));
  }
}

class UserListItem extends StatefulWidget {
  final Contact user;
  final int maxTotalMediaCounter;

  const UserListItem(
      {super.key, required this.user, required this.maxTotalMediaCounter});

  @override
  State<UserListItem> createState() => _UserListItem();
}

class _UserListItem extends State<UserListItem> {
  int lastMessageInSeconds = 0;
  MessageSendState state = MessageSendState.send;
  List<int> token = [];
  Message? currentMessage;

  Timer? updateTime;

  @override
  void initState() {
    super.initState();
    // initAsync();
    lastUpdateTime();
  }

  // Future initAsync() async {
  //   if (currentMessage != null) {
  //     if (currentMessage!.downloadState != DownloadState.downloading) {
  //       final content = widget.lastMessage!.messageContent;
  //       if (content is MediaMessageContent) {
  //         tryDownloadMedia(widget.lastMessage!.messageId,
  //             widget.lastMessage!.otherUserId, content.downloadToken);
  //       }
  //     }
  //   }
  // }

  void lastUpdateTime() {
    // Change the color every 200 milliseconds
    updateTime = Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        if (currentMessage != null) {
          lastMessageInSeconds =
              calculateTimeDifference(DateTime.now(), currentMessage!.sendAt)
                  .inSeconds;
        }
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
    final notOpenedMessages =
        context.db.watchMessageNotOpened(widget.user.userId);
    final lastMessage = context.db.watchLastMessage(widget.user.userId);

    // if (widget.lastMessage != null) {
    //   state = widget.lastMessage!.getSendState();

    //   final content = widget.lastMessage!.messageContent;

    //   if (widget.lastMessage!.messageReceived &&
    //       content is MediaMessageContent) {
    //     token = content.downloadToken;
    //     isDownloading = context
    //         .watch<DownloadChangeProvider>()
    //         .currentlyDownloading
    //         .contains(token.toString());
    //   }
    // }

    int flameCounter = getFlameCounterFromContact(widget.user);

    return UserContextMenu(
      contact: widget.user,
      child: ListTile(
        title: Text(getContactDisplayName(widget.user)),
        subtitle: StreamBuilder(
          stream: lastMessage,
          builder: (context, lastMessageSnapshot) {
            if (!lastMessageSnapshot.hasData) {
              return Container();
            }
            if (lastMessageSnapshot.data == null) {
              return Text(context.lang.chatsTapToSend);
            }
            final lastMessage = lastMessageSnapshot.data!;
            return StreamBuilder(
              stream: notOpenedMessages,
              builder: (context, notOpenedMessagesSnapshot) {
                if (!lastMessageSnapshot.hasData) {
                  return Container();
                }

                var lastMessages = [lastMessage];
                if (notOpenedMessagesSnapshot.data != null) {
                  lastMessages = notOpenedMessagesSnapshot.data!;
                }

                return Row(
                  children: [
                    MessageSendStateIcon(lastMessages),
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
                );
              },
            );
          },
        ),
        leading: InitialsAvatar(getContactDisplayName(widget.user)),
        onTap: () {
          if (currentMessage == null) {
            context
                .read<SendNextMediaTo>()
                .updateSendNextMediaTo(widget.user.userId.toInt());
            globalUpdateOfHomeViewPageIndex(0);
            return;
          }
          Message msg = currentMessage!;
          if (msg.downloadState == DownloadState.downloading) {
            return;
          }
          if (msg.downloadState == DownloadState.pending) {
            tryDownloadMedia(msg.messageId, msg.contactId, token, force: true);
            return;
          }
          if (state == MessageSendState.received &&
              msg.kind == MessageKind.media) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return MediaViewerView(widget.user, msg);
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
