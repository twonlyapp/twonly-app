import 'dart:collection';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/best_friends_selector.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/headline.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/verified_shield.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/providers/api/api.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
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
  List<Contact> _users = [];
  List<Contact> _otherUsers = [];
  List<Contact> _bestFriends = [];
  int maxTotalMediaCounter = 0;
  Uint8List? imageBytes;
  final HashSet<Int64> _selectedUserIds = HashSet<Int64>();
  final TextEditingController searchUserName = TextEditingController();
  bool showRealTwonlyWarning = false;

  @override
  void initState() {
    super.initState();
    _loadAsync();
  }

  Future<void> _loadAsync() async {
    _users = await DbContacts.getActiveUsers();
    _updateUsers(_users);
    imageBytes = await widget.imageBytesFuture;
    setState(() {});
  }

  Future _updateUsers(List<Contact> users) async {
    Map<int, int> flameCounters =
        context.read<MessagesChangeProvider>().flamesCounter;

    // Sort contacts by flameCounter and then by totalMediaCounter
    users.sort((a, b) {
      // First, compare by flameCounter
      int flameComparison = (flameCounters[b.userId.toInt()] ?? 0)
          .compareTo((flameCounters[a.userId.toInt()] ?? 0));
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
      if ((flameCounters[contact.userId.toInt()] ?? 0) > 0 &&
          bestFriends.length < 6) {
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
      _updateUsers(_users);
      return;
    }
    List<Contact> usersFiltered = _users
        .where((user) =>
            user.displayName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    _updateUsers(usersFiltered);
  }

  void updateStatus(Int64 userId, bool checked) {
    if (widget.isRealTwonly) {
      Contact user = _users.firstWhere((x) => x.userId == userId);
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
                icon: imageBytes == null
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
                  sendImage(
                    _selectedUserIds.toList(),
                    imageBytes!,
                    widget.isRealTwonly,
                    widget.maxShowTime,
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                  globalUpdateOfHomeViewPageIndex(1);
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
  final Function(Int64, bool) updateStatus;
  final List<Contact> users;
  final int maxTotalMediaCounter;
  final bool isRealTwonly;
  final HashSet<Int64> selectedUserIds;

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort the users alphabetically
    users.sort((a, b) => a.displayName.compareTo(b.displayName));

    Map<int, int> flameCounters =
        context.watch<MessagesChangeProvider>().flamesCounter;

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: users.length,
      itemBuilder: (BuildContext context, int i) {
        Contact user = users[i];
        int flameCounter = flameCounters[user.userId.toInt()] ?? 0;
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
              Text(user.displayName),
              if (flameCounter >= 1)
                FlameCounterWidget(
                  user,
                  flameCounter,
                  maxTotalMediaCounter,
                  prefix: true,
                ),
            ],
          ),
          leading: InitialsAvatar(
            displayName: user.displayName,
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
