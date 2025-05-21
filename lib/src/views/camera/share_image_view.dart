import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/protobuf/api/error.pb.dart';
import 'package:twonly/src/providers/api/media_send.dart';
import 'package:twonly/src/views/camera/components/best_friends_selector.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/headline.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/subscription/subscription_view.dart';

class ShareImageView extends StatefulWidget {
  const ShareImageView(
      {super.key,
      required this.imageBytesFuture,
      required this.isRealTwonly,
      required this.mirrorVideo,
      required this.maxShowTime,
      required this.selectedUserIds,
      required this.updateStatus,
      required this.videoFilePath,
      this.enableVideoAudio});
  final Future<Uint8List?> imageBytesFuture;
  final bool isRealTwonly;
  final bool mirrorVideo;
  final int maxShowTime;
  final File? videoFilePath;
  final HashSet<int> selectedUserIds;
  final bool? enableVideoAudio;
  final Function(int, bool) updateStatus;

  @override
  State<ShareImageView> createState() => _ShareImageView();
}

class _ShareImageView extends State<ShareImageView> {
  List<Contact> contacts = [];
  List<Contact> _otherUsers = [];
  List<Contact> _bestFriends = [];
  List<Contact> _pinnedContacs = [];
  Uint8List? imageBytes;
  bool sendingImage = false;
  bool hideArchivedUsers = true;
  final TextEditingController searchUserName = TextEditingController();
  bool showRealTwonlyWarning = false;
  late StreamSubscription<List<Contact>> contactSub;
  String lastQuery = "";

  @override
  void initState() {
    super.initState();

    Stream<List<Contact>> allContacts =
        twonlyDatabase.contactsDao.watchContactsForShareView();

    contactSub = allContacts.listen((allContacts) {
      setState(() {
        contacts = allContacts;
      });
      updateUsers(allContacts.where((x) => !x.archived).toList());
    });

    initAsync();
  }

  Future initAsync() async {
    imageBytes = await widget.imageBytesFuture;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    contactSub.cancel();
  }

  Future updateUsers(List<Contact> users) async {
    // Sort contacts by flameCounter and then by totalMediaCounter
    users.sort((a, b) {
      // First, compare by flameCounter
      int flameComparison = (getFlameCounterFromContact(b))
          .compareTo((getFlameCounterFromContact(a)));
      if (flameComparison != 0) {
        return flameComparison; // Sort by flameCounter in descending order
      }
      // If flameCounter is the same, compare by totalMediaCounter
      return b.totalMediaCounter.compareTo(
          a.totalMediaCounter); // Sort by totalMediaCounter in descending order
    });

    // Separate best friends and other users
    List<Contact> bestFriends = [];
    List<Contact> otherUsers = [];
    List<Contact> pinnedContacts = users.where((c) => c.pinned).toList();

    for (var contact in users) {
      if (contact.pinned) continue;
      if (!contact.archived &&
          (getFlameCounterFromContact(contact)) > 0 &&
          bestFriends.length < 6) {
        bestFriends.add(contact);
      } else {
        otherUsers.add(contact);
      }
    }

    setState(() {
      _bestFriends = bestFriends;
      _pinnedContacs = pinnedContacts;
      _otherUsers = otherUsers;
    });
  }

  Future _filterUsers(String query) async {
    lastQuery = query;
    if (query.isEmpty) {
      updateUsers(contacts
          .where((x) =>
              !x.archived ||
              !hideArchivedUsers ||
              widget.selectedUserIds.contains(x.userId))
          .toList());
      return;
    }
    List<Contact> usersFiltered = contacts
        .where((user) => getContactDisplayName(user)
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
    updateUsers(usersFiltered);
  }

  void updateStatus(int userId, bool checked) {
    if (widget.isRealTwonly) {
      Contact user = contacts.firstWhere((x) => x.userId == userId);
      if (!user.verified) {
        showRealTwonlyWarning = true;
        setState(() {});
        return;
      }
    }
    showRealTwonlyWarning = false;
    widget.updateStatus(userId, checked);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.shareImageTitle),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 40, left: 10, top: 20, right: 10),
          child: Column(
            children: [
              if (showRealTwonlyWarning)
                Text(
                  context.lang.shareImageAllTwonlyWarning,
                  style: TextStyle(color: Colors.orange, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              if (showRealTwonlyWarning) const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  onChanged: _filterUsers,
                  decoration: getInputDecoration(
                    context,
                    context.lang.shareImageSearchAllContacts,
                  ),
                ),
              ),
              if (_pinnedContacs.isNotEmpty) const SizedBox(height: 10),
              BestFriendsSelector(
                users: _pinnedContacs,
                selectedUserIds: widget.selectedUserIds,
                isRealTwonly: widget.isRealTwonly,
                updateStatus: updateStatus,
                title: context.lang.shareImagePinnedContacts,
              ),
              const SizedBox(height: 10),
              BestFriendsSelector(
                users: _bestFriends,
                selectedUserIds: widget.selectedUserIds,
                isRealTwonly: widget.isRealTwonly,
                updateStatus: updateStatus,
                title: context.lang.shareImageBestFriends,
              ),
              const SizedBox(height: 10),
              if (_otherUsers.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    HeadLineComponent(context.lang.shareImageAllUsers),
                    if (contacts.any((x) => x.archived))
                      Row(
                        children: [
                          Text(
                            context.lang.shareImageShowArchived,
                            style: TextStyle(fontSize: 10),
                          ),
                          Transform.scale(
                            scale: 0.75,
                            child: Checkbox(
                              value: !hideArchivedUsers,
                              side: WidgetStateBorderSide.resolveWith(
                                (Set states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return BorderSide(width: 0);
                                  }
                                  return BorderSide(
                                      width: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline);
                                },
                              ),
                              onChanged: (a) {
                                setState(() {
                                  hideArchivedUsers = !hideArchivedUsers;
                                  _filterUsers(lastQuery);
                                });
                              },
                            ),
                          )
                        ],
                      )
                  ],
                ),
              Expanded(
                child: UserList(
                  List.from(_otherUsers),
                  selectedUserIds: widget.selectedUserIds,
                  isRealTwonly: widget.isRealTwonly,
                  updateStatus: updateStatus,
                ),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 120,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                icon: imageBytes == null || sendingImage
                    ? SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      )
                    : FaIcon(FontAwesomeIcons.solidPaperPlane),
                onPressed: () async {
                  if (imageBytes == null || widget.selectedUserIds.isEmpty) {
                    return;
                  }

                  ErrorCode? err = await isAllowedToSend();
                  if (!context.mounted) return;

                  if (err != null) {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return SubscriptionView(
                        redirectError: err,
                      );
                    }));
                  } else {
                    setState(() {
                      sendingImage = true;
                    });

                    sendMediaFile(
                      widget.selectedUserIds.toList(),
                      imageBytes!,
                      widget.isRealTwonly,
                      widget.maxShowTime,
                      widget.videoFilePath,
                      widget.enableVideoAudio,
                      widget.mirrorVideo,
                    );
                    if (context.mounted) {
                      Navigator.pop(context, true);
                      // if (widget.preselectedUser != null) {
                      //   Navigator.pop(context, true);
                      // } else {
                      // Navigator.popUntil(context, (route) => route.isFirst, true);
                      // globalUpdateOfHomeViewPageIndex(1);
                      // }
                    }
                  }
                },
                style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    ),
                    backgroundColor: WidgetStateProperty.all<Color>(
                      imageBytes == null || widget.selectedUserIds.isEmpty
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.primary,
                    )),
                label: Text(
                  context.lang.shareImagedEditorSendImage,
                  style: TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserList extends StatelessWidget {
  const UserList(
    this.users, {
    super.key,
    required this.selectedUserIds,
    required this.updateStatus,
    required this.isRealTwonly,
  });
  final Function(int, bool) updateStatus;
  final List<Contact> users;
  final bool isRealTwonly;
  final HashSet<int> selectedUserIds;

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort the users alphabetically
    users
        .sort((a, b) => b.lastMessageExchange.compareTo(a.lastMessageExchange));

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: users.length,
      itemBuilder: (BuildContext context, int i) {
        Contact user = users[i];
        int flameCounter = getFlameCounterFromContact(user);
        return ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start, // Center horizontally
            crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
            children: [
              if (isRealTwonly)
                Padding(
                  padding: const EdgeInsets.only(right: 1),
                  child: VerifiedShield(user),
                ),
              Text(getContactDisplayName(user)),
              if (flameCounter >= 1)
                FlameCounterWidget(
                  user,
                  flameCounter,
                  prefix: true,
                ),
            ],
          ),
          leading: ContactAvatar(
            contact: user,
            fontSize: 15,
          ),
          trailing: Checkbox(
            value: selectedUserIds.contains(user.userId),
            side: WidgetStateBorderSide.resolveWith(
              (Set states) {
                if (states.contains(WidgetState.selected)) {
                  return BorderSide(width: 0);
                }
                return BorderSide(
                    width: 1, color: Theme.of(context).colorScheme.outline);
              },
            ),
            onChanged: (bool? value) {
              if (value == null) return;
              updateStatus(user.userId, value);
            },
          ),
          onTap: () {
            updateStatus(user.userId, !selectedUserIds.contains(user.userId));
          },
        );
      },
    );
  }
}
