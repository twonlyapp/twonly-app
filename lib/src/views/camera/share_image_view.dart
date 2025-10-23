// ignore_for_file: strict_raw_type

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_components/best_friends_selector.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/headline.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/views/settings/subscription/subscription.view.dart';

class ShareImageView extends StatefulWidget {
  const ShareImageView({
    required this.selectedGroupIds,
    required this.updateSelectedGroupIds,
    required this.mediaStoreFuture,
    required this.mediaFileService,
    super.key,
  });
  final HashSet<String> selectedGroupIds;
  final void Function(String, bool) updateSelectedGroupIds;
  final Future<bool>? mediaStoreFuture;
  final MediaFileService mediaFileService;

  @override
  State<ShareImageView> createState() => _ShareImageView();
}

class _ShareImageView extends State<ShareImageView> {
  List<Contact> contacts = [];
  List<Contact> _otherUsers = [];
  List<Contact> _bestFriends = [];
  List<Contact> _pinnedContacts = [];
  Uint8List? imageBytes;
  bool sendingImage = false;
  bool hideArchivedUsers = true;
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Contact>> contactSub;
  String lastQuery = '';

  @override
  void initState() {
    super.initState();

    final allContacts = twonlyDB.contactsDao.watchContactsForShareView();

    contactSub = allContacts.listen((allContacts) async {
      setState(() {
        contacts = allContacts;
      });
      await updateUsers(allContacts.where((x) => !x.archived).toList());
    });

    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    if (widget.mediaStoreFuture != null) {
      await widget.mediaStoreFuture;
    }
    await widget.mediaFileService.setUploadState(UploadState.preprocessing);
    unawaited(startBackgroundMediaUpload(widget.mediaFileService));
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    unawaited(contactSub.cancel());
    super.dispose();
  }

  Future<void> updateUsers(List<Contact> users) async {
    // Sort contacts by flameCounter and then by totalMediaCounter
    users.sort((a, b) {
      // First, compare by flameCounter
      final flameComparison = getFlameCounterFromContact(b)
          .compareTo(getFlameCounterFromContact(a));
      if (flameComparison != 0) {
        return flameComparison; // Sort by flameCounter in descending order
      }
      // If flameCounter is the same, compare by totalMediaCounter
      return b.totalMediaCounter.compareTo(
        a.totalMediaCounter,
      ); // Sort by totalMediaCounter in descending order
    });

    // Separate best friends and other users
    final bestFriends = <Contact>[];
    final otherUsers = <Contact>[];
    final pinnedContacts = users.where((c) => c.pinned).toList();

    for (final contact in users) {
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
      _pinnedContacts = pinnedContacts;
      _otherUsers = otherUsers;
    });
  }

  Future<void> _filterUsers(String query) async {
    lastQuery = query;
    if (query.isEmpty) {
      await updateUsers(
        contacts
            .where(
              (x) =>
                  !x.archived ||
                  !hideArchivedUsers ||
                  widget.selectedUserIds.contains(x.userId),
            )
            .toList(),
      );
      return;
    }
    final usersFiltered = contacts
        .where(
          (user) => getContactDisplayName(user)
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
    await updateUsers(usersFiltered);
  }

  void updateStatus(int userId, bool checked) {
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
          padding:
              const EdgeInsets.only(bottom: 40, left: 10, top: 20, right: 10),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  onChanged: _filterUsers,
                  decoration: getInputDecoration(
                    context,
                    context.lang.shareImageSearchAllContacts,
                  ),
                ),
              ),
              if (_pinnedContacts.isNotEmpty) const SizedBox(height: 10),
              BestFriendsSelector(
                users: _pinnedContacts,
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
                            style: const TextStyle(fontSize: 10),
                          ),
                          Transform.scale(
                            scale: 0.75,
                            child: Checkbox(
                              value: !hideArchivedUsers,
                              side: WidgetStateBorderSide.resolveWith(
                                (Set states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const BorderSide(width: 0);
                                  }
                                  return BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  );
                                },
                              ),
                              onChanged: (a) async {
                                hideArchivedUsers = !hideArchivedUsers;
                                await _filterUsers(lastQuery);
                                if (mounted) setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              Expanded(
                child: UserList(
                  List.from(_otherUsers),
                  selectedUserIds: widget.selectedUserIds,
                  isRealTwonly: widget.isRealTwonly,
                  updateStatus: updateStatus,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 120,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    : const FaIcon(FontAwesomeIcons.solidPaperPlane),
                onPressed: () async {
                  if (imageBytes == null || widget.selectedUserIds.isEmpty) {
                    return;
                  }

                  final err = await isAllowedToSend();
                  if (!context.mounted) return;

                  if (err != null) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return SubscriptionView(
                            redirectError: err,
                          );
                        },
                      ),
                    );
                  } else {
                    setState(() {
                      sendingImage = true;
                    });

                    await finalizeUpload(
                      widget.mediaUploadId,
                      widget.selectedUserIds.toList(),
                      widget.isRealTwonly,
                      widget.videoUploadHandler != null,
                      widget.mirrorVideo,
                      widget.maxShowTime,
                    );

                    /// trigger the upload of the media file.
                    unawaited(handleNextMediaUploadSteps(widget.mediaUploadId));

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
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  ),
                  backgroundColor: WidgetStateProperty.all<Color>(
                    imageBytes == null || widget.selectedUserIds.isEmpty
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                label: Text(
                  context.lang.shareImagedEditorSendImage,
                  style: const TextStyle(fontSize: 17),
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
    required this.selectedUserIds,
    required this.updateStatus,
    required this.isRealTwonly,
    super.key,
  });
  final void Function(int, bool) updateStatus;
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
        final user = users[i];
        final flameCounter = getFlameCounterFromContact(user);
        return ListTile(
          title: Row(
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
                  return const BorderSide(width: 0);
                }
                return BorderSide(color: Theme.of(context).colorScheme.outline);
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
