// ignore_for_file: strict_raw_type

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/groups.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/api/mediafiles/upload.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera/share_image_components/best_friends_selector.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/headline.dart';

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
  final Future<Uint8List?>? mediaStoreFuture;
  final MediaFileService mediaFileService;

  @override
  State<ShareImageView> createState() => _ShareImageView();
}

class _ShareImageView extends State<ShareImageView> {
  List<Group> contacts = [];
  List<Group> _otherUsers = [];
  List<Group> _bestFriends = [];
  List<Group> _pinnedContacts = [];

  bool sendingImage = false;
  bool mediaStoreFutureReady = false;
  Uint8List? _imageBytes;
  bool hideArchivedUsers = true;
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Group>> allGroupSub;
  String lastQuery = '';

  @override
  void initState() {
    super.initState();

    allGroupSub =
        twonlyDB.groupsDao.watchGroupsForShareImage().listen((allGroups) async {
      setState(() {
        contacts = allGroups;
      });
      await updateGroups(allGroups.where((x) => !x.archived).toList());
    });

    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    if (widget.mediaStoreFuture != null) {
      _imageBytes = await widget.mediaStoreFuture;
    }
    mediaStoreFutureReady = true;
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    unawaited(allGroupSub.cancel());
    super.dispose();
  }

  Future<void> updateGroups(List<Group> groups) async {
    // Sort contacts by flameCounter and then by totalMediaCounter
    groups.sort((a, b) {
      // First, compare by flameCounter

      final flameComparison =
          getFlameCounterFromGroup(b).compareTo(getFlameCounterFromGroup(a));
      if (flameComparison != 0) {
        return flameComparison; // Sort by flameCounter in descending order
      }
      // If flameCounter is the same, compare by totalMediaCounter
      return b.totalMediaCounter.compareTo(
        a.totalMediaCounter,
      ); // Sort by totalMediaCounter in descending order
    });

    // Separate best friends and other users
    final bestFriends = <Group>[];
    final otherUsers = <Group>[];
    final pinnedContacts = groups.where((c) => c.pinned).toList();

    for (final group in groups) {
      if (group.pinned) continue;
      if (!group.archived &&
          (getFlameCounterFromGroup(group)) > 0 &&
          bestFriends.length < 6) {
        bestFriends.add(group);
      } else {
        otherUsers.add(group);
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
      await updateGroups(
        contacts
            .where(
              (x) =>
                  !x.archived ||
                  !hideArchivedUsers ||
                  widget.selectedGroupIds.contains(x.groupId),
            )
            .toList(),
      );
      return;
    }
    final usersFiltered = contacts
        .where(
          (user) => user.groupName.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    await updateGroups(usersFiltered);
  }

  void updateSelectedGroupIds(String groupId, bool checked) {
    widget.updateSelectedGroupIds(groupId, checked);
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
                groups: _pinnedContacts,
                selectedGroupIds: widget.selectedGroupIds,
                updateSelectedGroupIds: updateSelectedGroupIds,
                title: context.lang.shareImagePinnedContacts,
                showSelectAll:
                    !widget.mediaFileService.mediaFile.requiresAuthentication,
              ),
              const SizedBox(height: 10),
              BestFriendsSelector(
                groups: _bestFriends,
                selectedGroupIds: widget.selectedGroupIds,
                updateSelectedGroupIds: updateSelectedGroupIds,
                title: context.lang.shareImageBestFriends,
                showSelectAll:
                    !widget.mediaFileService.mediaFile.requiresAuthentication,
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
                  selectedGroupIds: widget.selectedGroupIds,
                  updateSelectedGroupIds: updateSelectedGroupIds,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 168,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20, right: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.mediaFileService.mediaFile.type == MediaType.image &&
                  _imageBytes != null &&
                  gUser.showShowImagePreviewWhenSending)
                SizedBox(
                  height: 100,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: context.color.primary, width: 2),
                      color: context.color.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_imageBytes!),
                    ),
                  ),
                ),
              FilledButton.icon(
                icon: !mediaStoreFutureReady || sendingImage
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
                  if (!mediaStoreFutureReady ||
                      widget.selectedGroupIds.isEmpty) {
                    return;
                  }

                  setState(() {
                    sendingImage = true;
                  });

                  await insertMediaFileInMessagesTable(
                    widget.mediaFileService,
                    widget.selectedGroupIds.toList(),
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
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all<EdgeInsets>(
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                  ),
                  backgroundColor: WidgetStateProperty.all<Color>(
                    !mediaStoreFutureReady || widget.selectedGroupIds.isEmpty
                        ? context.color.onSurface
                        : context.color.primary,
                  ),
                ),
                label: Text(
                  '${context.lang.shareImagedEditorSendImage} (${widget.selectedGroupIds.length})',
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
    this.groups, {
    required this.selectedGroupIds,
    required this.updateSelectedGroupIds,
    super.key,
  });
  final void Function(String, bool) updateSelectedGroupIds;
  final List<Group> groups;
  final HashSet<String> selectedGroupIds;

  @override
  Widget build(BuildContext context) {
    // Step 1: Sort the users alphabetically
    groups
        .sort((a, b) => b.lastMessageExchange.compareTo(a.lastMessageExchange));

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: groups.length,
      itemBuilder: (BuildContext context, int i) {
        final group = groups[i];
        return ListTile(
          key: ValueKey(group.groupId),
          title: Row(
            children: [
              Text(substringBy(group.groupName, 12)),
              FlameCounterWidget(
                groupId: group.groupId,
                prefix: true,
              ),
            ],
          ),
          leading: AvatarIcon(
            group: group,
            fontSize: 15,
          ),
          trailing: Checkbox(
            value: selectedGroupIds.contains(group.groupId),
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
              updateSelectedGroupIds(group.groupId, value);
            },
          ),
          onTap: () {
            updateSelectedGroupIds(
              group.groupId,
              !selectedGroupIds.contains(group.groupId),
            );
          },
        );
      },
    );
  }
}
