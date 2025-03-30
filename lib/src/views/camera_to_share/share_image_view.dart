import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/best_friends_selector.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/headline.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/verified_shield.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/providers/api/media.dart';
import 'package:twonly/src/providers/send_next_media_to.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/home_view.dart';

class ShareImageView extends StatefulWidget {
  const ShareImageView(
      {super.key,
      required this.imageBytesFuture,
      required this.isRealTwonly,
      required this.maxShowTime});
  final Future<Uint8List?> imageBytesFuture;
  final bool isRealTwonly;
  final int maxShowTime;

  @override
  State<ShareImageView> createState() => _ShareImageView();
}

class _ShareImageView extends State<ShareImageView> {
  List<Contact> contacts = [];
  List<Contact> _otherUsers = [];
  List<Contact> _bestFriends = [];
  int maxTotalMediaCounter = 0;
  Uint8List? imageBytes;
  bool sendingImage = false;
  final HashSet<int> _selectedUserIds = HashSet<int>();
  final TextEditingController searchUserName = TextEditingController();
  bool showRealTwonlyWarning = false;
  late StreamSubscription<List<Contact>> contactSub;

  @override
  void initState() {
    super.initState();

    int? sendNextMediaToUserId =
        context.read<SendNextMediaTo>().sendNextMediaToUserId;
    if (sendNextMediaToUserId != null) {
      _selectedUserIds.add(sendNextMediaToUserId);
    }

    Stream<List<Contact>> allContacts =
        twonlyDatabase.contactsDao.watchContactsForChatList();

    contactSub = allContacts.listen((allContacts) {
      setState(() {
        contacts = allContacts;
      });
      updateUsers(allContacts);
    });

    //_users = await DbContacts.getActiveUsers();
    // _updateUsers(_users);
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

    maxTotalMediaCounter = 0;
    if (users.isNotEmpty) {
      maxTotalMediaCounter =
          users.map((x) => x.totalMediaCounter).reduce((a, b) => a > b ? a : b);
    }

    // Separate best friends and other users
    List<Contact> bestFriends = [];
    List<Contact> otherUsers = [];

    for (var contact in users) {
      if ((getFlameCounterFromContact(contact)) > 0 && bestFriends.length < 6) {
        bestFriends.add(contact);
      } else {
        otherUsers.add(contact);
      }
    }

    setState(() {
      _bestFriends = bestFriends;
      _otherUsers = otherUsers;
    });
  }

  Future _filterUsers(String query) async {
    if (query.isEmpty) {
      updateUsers(contacts);
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
    if (checked) {
      if (widget.isRealTwonly) {
        _selectedUserIds.clear();
      }
      _selectedUserIds.add(userId);
    } else {
      _selectedUserIds.remove(userId);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.shareImageTitle),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                onChanged: _filterUsers,
                decoration: getInputDecoration(
                    context, context.lang.searchUsernameInput),
              ),
            ),
            if (showRealTwonlyWarning) const SizedBox(height: 10),
            if (showRealTwonlyWarning)
              Text(
                context.lang.shareImageAllTwonlyWarning,
                style: TextStyle(color: Colors.orange),
              ),
            const SizedBox(height: 10),
            BestFriendsSelector(
              users: _bestFriends,
              selectedUserIds: _selectedUserIds,
              maxTotalMediaCounter: maxTotalMediaCounter,
              isRealTwonly: widget.isRealTwonly,
              updateStatus: updateStatus,
            ),
            const SizedBox(height: 10),
            if (_otherUsers.isNotEmpty)
              HeadLineComponent(context.lang.shareImageAllUsers),
            Expanded(
              child: UserList(
                List.from(_otherUsers),
                maxTotalMediaCounter,
                selectedUserIds: _selectedUserIds,
                isRealTwonly: widget.isRealTwonly,
                updateStatus: updateStatus,
              ),
            )
          ],
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
                  if (imageBytes == null || _selectedUserIds.isEmpty) {
                    return;
                  }
                  setState(() {
                    sendingImage = true;
                  });
                  sendImage(
                    _selectedUserIds.toList(),
                    imageBytes!,
                    widget.isRealTwonly,
                    widget.maxShowTime,
                  );
                  if (context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                    globalUpdateOfHomeViewPageIndex(1);
                  }
                },
                style: ButtonStyle(
                    padding: WidgetStateProperty.all<EdgeInsets>(
                      EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    ),
                    backgroundColor: WidgetStateProperty.all<Color>(
                      imageBytes == null || _selectedUserIds.isEmpty
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
    this.users,
    this.maxTotalMediaCounter, {
    super.key,
    required this.selectedUserIds,
    required this.updateStatus,
    required this.isRealTwonly,
  });
  final Function(int, bool) updateStatus;
  final List<Contact> users;
  final int maxTotalMediaCounter;
  final bool isRealTwonly;
  final HashSet<int> selectedUserIds;

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort the users alphabetically
    users.sort(
        (a, b) => getContactDisplayName(a).compareTo(getContactDisplayName(b)));

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
                  maxTotalMediaCounter,
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
