import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/services/flame.service.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/decorations/input_text.decoration.dart';
import 'package:twonly/src/visual/elements/headline.element.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/best_friends_selector.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/background.layer.dart';

class ShareImageView extends StatefulWidget {
  const ShareImageView({
    required this.selectedGroupIds,
    required this.updateSelectedGroupIds,
    required this.mediaStoreFuture,
    required this.mediaFileService,
    required this.additionalData,
    super.key,
  });
  final HashSet<String> selectedGroupIds;
  final void Function(String, bool) updateSelectedGroupIds;
  final Future<ScreenshotImageHelper?>? mediaStoreFuture;
  final MediaFileService mediaFileService;
  final AdditionalMessageData? additionalData;

  @override
  State<ShareImageView> createState() => _ShareImageView();
}

class _ShareImageView extends State<ShareImageView> {
  List<Group> _allGroups = [];
  List<Group> _otherUsers = [];
  List<Group> _bestFriends = [];
  List<Group> _pinnedContacts = [];

  bool sendingImage = false;
  bool mediaStoreFutureReady = false;
  ScreenshotImageHelper? _screenshotImage;
  bool hideArchivedUsers = true;
  final TextEditingController searchUserName = TextEditingController();
  late StreamSubscription<List<Group>> allGroupSub;
  String lastQuery = '';

  @override
  void initState() {
    super.initState();

    allGroupSub = twonlyDB.groupsDao.watchGroupsForShareImage().listen((
      allGroups,
    ) async {
      setState(() {
        _allGroups = allGroups;
      });
      await updateGroups(_allGroups.where((x) => !x.archived).toList());
    });

    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    if (widget.mediaStoreFuture != null) {
      _screenshotImage = await widget.mediaStoreFuture;
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

      final flameComparison = getFlameCounterFromGroup(
        b,
      ).compareTo(getFlameCounterFromGroup(a));
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
        _allGroups
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
    final usersFiltered = _allGroups
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
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 10,
            top: 20,
            right: 10,
          ),
          child: Column(
            children: [
              if (_allGroups.isEmpty)
                Expanded(
                  child: Center(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.person_add),
                      onPressed: () => context.push(Routes.chatsAddNewUser),
                      label: Text(
                        context.lang.chatListViewSearchUserNameBtn,
                      ),
                    ),
                  ),
                ),

              if (_allGroups.isNotEmpty)
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
                    HeadLineComp(context.lang.shareImageAllUsers),
                    if (_allGroups.any((x) => x.archived))
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
                                (states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return const BorderSide(width: 0);
                                  }
                                  return BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
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
              if (_otherUsers.isNotEmpty)
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
                  _screenshotImage?.image != null &&
                  userService.currentUser.showShowImagePreviewWhenSending)
                SizedBox(
                  height: 100,
                  width: 100 * 9 / 16,
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: context.color.primary,
                        width: 2,
                      ),
                      color: context.color.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CustomPaint(
                        painter: UiImagePainter(_screenshotImage!.image!),
                      ),
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

                  // in case mediaStoreFutureReady is ready, the image is stored in the originalPath
                  await insertMediaFileInMessagesTable(
                    widget.mediaFileService,
                    widget.selectedGroupIds.toList(),
                    additionalData: widget.additionalData,
                  );

                  if (context.mounted) {
                    Navigator.pop(context, true);
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
    groups.sort(
      (a, b) => b.lastMessageExchange.compareTo(a.lastMessageExchange),
    );

    return ListView.builder(
      restorationId: 'new_message_users_list',
      itemCount: groups.length,
      itemBuilder: (context, i) {
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
              (states) {
                if (states.contains(WidgetState.selected)) {
                  return const BorderSide(width: 0);
                }
                return BorderSide(color: Theme.of(context).colorScheme.outline);
              },
            ),
            onChanged: (value) {
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
