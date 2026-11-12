import 'dart:async';
import 'dart:collection';

import 'package:clock/clock.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:twonly/core/bridge.dart' show FlameState;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/groups.dart' as rust_groups;
import 'package:twonly/core/bridge/stories.dart' as stories;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/protobuf/client/generated/data.pb.dart';
import 'package:twonly/src/model/story_availability.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/contact_request_badge.comp.dart';
import 'package:twonly/src/visual/components/flame_counter.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/headline.element.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/helpers/screenshot.helper.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/best_friends_selector.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/contact_group_shortcut_row.comp.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/story_availability_picker.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/story_target_selector.comp.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layers/background.layer.dart';
import 'package:twonly/src/visual/views/chats/chat_list_components/empty_chat_list.comp.dart';

bool canSendSharedMedia({
  required bool mediaReady,
  required bool sending,
  required bool hasChatRecipients,
  required bool storyPossible,
  required bool hasStoryTarget,
  required int? storyAudienceSize,
}) {
  return mediaReady &&
      !sending &&
      (hasChatRecipients ||
          (storyPossible && hasStoryTarget && (storyAudienceSize ?? 0) > 0));
}

/// Every chat a send reaches: those picked directly and, with a story, the
/// 1:1 chat of everybody the story goes to. Someone picked directly who also
/// gets the story counts once.
int sharedMediaRecipientCount({
  required Set<String> selectedGroupIds,
  required Set<String>? storyAudienceChats,
}) => {...selectedGroupIds, ...?storyAudienceChats}.length;

class ShareImageView extends StatefulWidget {
  const ShareImageView({
    required this.selectedGroupIds,
    required this.updateSelectedGroupIds,
    required this.mediaStoreFuture,
    required this.mediaFileService,
    required this.additionalData,
    required this.sendToWidget,
    this.storyTarget,
    super.key,
  });
  final HashSet<String> selectedGroupIds;
  final void Function(String, bool) updateSelectedGroupIds;
  final Future<ScreenshotImageHelper?>? mediaStoreFuture;
  final MediaFileService mediaFileService;
  final AdditionalMessageData? additionalData;
  final bool sendToWidget;
  final StoryTarget? storyTarget;

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
  int _updateGroupsGeneration = 0;
  Map<String, FlameState> _flameStates = {};
  late final StoryTarget _storyTarget = widget.storyTarget ?? StoryTarget();
  Set<String>? _storyAudienceChats;
  StoryAvailability _availability = const StoryAvailability.duration();
  bool _settingsLoaded = false;
  Timer? _expiryTimer;

  bool get _storyPossible =>
      !widget.sendToWidget &&
      !widget.mediaFileService.mediaFile.requiresAuthentication &&
      (widget.mediaFileService.mediaFile.type == MediaType.image ||
          widget.mediaFileService.mediaFile.type == MediaType.video);

  bool get _hasStory => _storyPossible && !_storyTarget.isEmpty;

  bool get _canSend =>
      canSendSharedMedia(
        mediaReady: mediaStoreFutureReady,
        sending:
            sendingImage ||
            (_hasStory &&
                (!_settingsLoaded || !_availability.isValidAt(clock.now()))),
        hasChatRecipients: widget.selectedGroupIds.isNotEmpty,
        storyPossible: _storyPossible,
        hasStoryTarget: !_storyTarget.isEmpty,
        storyAudienceSize: _storyAudienceChats?.length,
      ) &&
      (!_hasStory || (_storyAudienceChats?.isNotEmpty ?? false));

  @override
  void initState() {
    super.initState();

    final groups = widget.sendToWidget
        ? watchRustDatabase(
            (control) => rust_groups.watchGroups(
              input: const db_groups.GroupQuery(
                filter: db_groups.GroupFilter.widgetShare,
              ),
              control: control,
            ),
          )
        : watchRustDatabase(
            (control) => rust_groups.watchGroups(
              input: const db_groups.GroupQuery(
                filter: db_groups.GroupFilter.shareImage,
              ),
              control: control,
            ),
          );
    allGroupSub = groups.listen((allGroups) async {
      final generation = ++_updateGroupsGeneration;
      final states = await rust_groups.flameStates(
        groupIds: allGroups.map((group) => group.groupId).toList(),
      );
      if (!mounted || generation != _updateGroupsGeneration) return;
      if (widget.sendToWidget) {
        final allowedGroupIds = allGroups.map((group) => group.groupId).toSet();
        for (final groupId in widget.selectedGroupIds.toList()) {
          if (!allowedGroupIds.contains(groupId)) {
            widget.updateSelectedGroupIds(groupId, false);
          }
        }
      }
      _allGroups = allGroups;
      _flameStates = states;
      _filterUsers(lastQuery);
    });

    unawaited(initAsync());
    if (_storyPossible) {
      unawaited(_loadAvailability());
      _expiryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (mounted && _hasStory) setState(() {});
      });
    }
  }

  Future<void> _loadAvailability() async {
    var availability = const StoryAvailability.duration();
    try {
      availability = await StoryAvailability.load();
    } on Object catch (error) {
      Log.warn('Could not load story availability: $error');
    }
    if (!mounted) return;
    setState(() {
      _availability = availability;
      _settingsLoaded = true;
    });
  }

  Future<void> _chooseAvailability() async {
    final selection = await showStoryAvailabilityPicker(context, _availability);
    if (selection == null || !mounted) return;
    setState(() => _availability = selection);
    try {
      await selection.save();
    } on Object catch (error) {
      Log.warn('Could not remember story availability: $error');
    }
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
    _expiryTimer?.cancel();
    unawaited(allGroupSub.cancel());
    searchUserName.dispose();
    super.dispose();
  }

  void updateGroups(List<Group> groups) {
    // Selection and search use the latest snapshot immediately. Reload the
    // counters only when the database supplies new groups, never on a tap.
    int flameOf(Group group) => _flameStates[group.groupId]?.counter ?? 0;

    // Sort contacts by flameCounter and then by totalMediaCounter
    groups.sort((a, b) {
      // First, compare by flameCounter
      final flameComparison = flameOf(b).compareTo(flameOf(a));
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
      if (!group.archived && flameOf(group) > 0 && bestFriends.length < 6) {
        bestFriends.add(group);
      } else {
        otherUsers.add(group);
      }
    }
    // Selected chats lead the list, archived or not, so a preselected
    // receiver is in view without scrolling for it.
    otherUsers.sort((a, b) {
      final aSelected = widget.selectedGroupIds.contains(a.groupId);
      final bSelected = widget.selectedGroupIds.contains(b.groupId);
      if (aSelected != bSelected) return aSelected ? -1 : 1;
      return b.lastMessageExchange.compareTo(a.lastMessageExchange);
    });

    setState(() {
      _bestFriends = bestFriends;
      _pinnedContacts = pinnedContacts;
      _otherUsers = otherUsers;
    });
  }

  void _filterUsers(String query) {
    lastQuery = query;
    if (query.isEmpty) {
      updateGroups(
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
    updateGroups(usersFiltered);
  }

  /// A selection made outside the list, e.g. through a contact group, moves
  /// the chat to the top of it.
  void updateSelectedGroupIds(String groupId, bool checked) {
    widget.updateSelectedGroupIds(groupId, checked);
    _filterUsers(lastQuery);
  }

  /// A chat ticked in the list itself stays where it is, so the rows do not
  /// move under the finger.
  void _updateSelectedGroupIdsInList(String groupId, bool checked) {
    widget.updateSelectedGroupIds(groupId, checked);
    setState(() {});
  }

  int get _recipientCount => sharedMediaRecipientCount(
    selectedGroupIds: widget.selectedGroupIds,
    storyAudienceChats: _hasStory ? _storyAudienceChats : null,
  );

  Future<void> _send() async {
    if (!_canSend) return;
    setState(() => sendingImage = true);
    var metadata = widget.additionalData;
    if (_hasStory) {
      metadata = metadata == null
          ? AdditionalMessageData()
          : AdditionalMessageData.fromBuffer(metadata.writeToBuffer());
      metadata.storyExpiresAtMs = Int64(
        (_availability.expiresAt(clock.now()).millisecondsSinceEpoch ~/ 1000) *
            1000,
      );
    }
    try {
      await RustApi.sendMediaToGroups(
        mediaId: widget.mediaFileService.mediaFile.mediaId,
        groupIds: widget.selectedGroupIds.toList(),
        additionalMessageData: metadata?.writeToBuffer(),
        widgetOnly: widget.sendToWidget,
        storyAudience: _hasStory ? _storyTarget.toAudience() : null,
      );
    } on Object catch (error, stack) {
      Log.error('Could not share media', error: error, stackTrace: stack);
      if (!mounted) return;
      setState(() => sendingImage = false);
      showSnackbar(
        context,
        _hasStory
            ? context.lang.shareImageStoryFailed(stories.maxMediaRecipients())
            : context.lang.mediaSendFailed,
      );
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  Widget _buildStorySection(BuildContext context) => IgnorePointer(
    ignoring: sendingImage,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoryTargetSelector(
            target: _storyTarget,
            enabled: true,
            onChanged: () => setState(() {}),
            onAudienceChanged: (chats) {
              if (mounted) {
                setState(() => _storyAudienceChats = chats);
              }
            },
            trailing: Tooltip(
              message: context.lang.storyAvailableFor,
              child: MyButton(
                key: const Key('storyAvailabilityButton'),
                variant: MyButtonVariant.secondaryTiny,
                onPressed: _settingsLoaded ? _chooseAvailability : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        _availability.duration != null
                            ? _availability.duration == const Duration(days: 1)
                                  ? context.lang.story24Hours
                                  : context.lang.storyDays(
                                      _availability.duration!.inDays,
                                    )
                            : DateFormat.Md(
                                Localizations.localeOf(
                                  context,
                                ).toString(),
                              ).format(_availability.deadline!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_hasStory && !_availability.isValidAt(clock.now()))
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                context.lang.storyChooseNewDeadline,
                style: TextStyle(color: context.color.error),
              ),
            ),
          if (_hasStory && (widget.additionalData?.hasPhotoLocation() ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(context.lang.storyIncludedOnMap),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.shareImageTitle),
        actions: const [
          ContactRequestBadgeComp(),
          SizedBox(width: 15),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 10,
            right: 10,
          ),
          child: CustomScrollView(
            restorationId: 'share_image_contact_selection',
            slivers: [
              if (_allGroups.isEmpty)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (_storyPossible) ...[
                        ContactGroupShortcutRow(
                          selectedGroupIds: widget.selectedGroupIds,
                          updateSelectedGroupIds: updateSelectedGroupIds,
                        ),
                        const SizedBox(height: 10),
                        _buildStorySection(context),
                      ],
                      const EmptyChatListComp(),
                    ],
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: MyInput(
                          controller: searchUserName,
                          dense: true,
                          fontWeight: FontWeight.normal,
                          hintText: context.lang.shareImageSearchAllContacts,
                          prefixIcon: const Icon(Icons.search, size: 20),
                          onChanged: _filterUsers,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!widget.sendToWidget) ...[
                        ContactGroupShortcutRow(
                          selectedGroupIds: widget.selectedGroupIds,
                          updateSelectedGroupIds: updateSelectedGroupIds,
                        ),
                        if (_storyPossible) ...[
                          const SizedBox(height: 10),
                          _buildStorySection(context),
                        ],
                        // The next section's heading brings its own space.
                        const SizedBox(height: 4),
                      ],
                      BestFriendsSelector(
                        groups: _pinnedContacts,
                        selectedGroupIds: widget.selectedGroupIds,
                        updateSelectedGroupIds: updateSelectedGroupIds,
                        title: context.lang.shareImagePinnedContacts,
                        showSelectAll: !widget.sendToWidget,
                      ),
                      if (_pinnedContacts.isNotEmpty)
                        const SizedBox(height: 10),
                      BestFriendsSelector(
                        groups: _bestFriends,
                        selectedGroupIds: widget.selectedGroupIds,
                        updateSelectedGroupIds: updateSelectedGroupIds,
                        title: context.lang.shareImageBestFriends,
                        showSelectAll: !widget.sendToWidget,
                      ),
                      if (_bestFriends.isNotEmpty) const SizedBox(height: 10),
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
                                    child: Checkbox.adaptive(
                                      value: !hideArchivedUsers,
                                      side: WidgetStateBorderSide.resolveWith((
                                        states,
                                      ) {
                                        if (states.contains(
                                          WidgetState.selected,
                                        )) {
                                          return const BorderSide(width: 0);
                                        }
                                        return BorderSide(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.outline,
                                        );
                                      }),
                                      onChanged: (a) {
                                        hideArchivedUsers = !hideArchivedUsers;
                                        _filterUsers(lastQuery);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_otherUsers.isNotEmpty)
                  UserList(
                    _otherUsers,
                    selectedGroupIds: widget.selectedGroupIds,
                    updateSelectedGroupIds: _updateSelectedGroupIdsInList,
                  ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.noAnimation,
      floatingActionButton: _allGroups.isEmpty && !_storyPossible
          ? null
          : SizedBox(
              height: 168,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20, right: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.mediaFileService.mediaFile.type ==
                            MediaType.image &&
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
                    MyButton(
                      key: const Key('shareMediaSend'),
                      variant: MyButtonVariant.primaryMiddle,
                      onPressed: _canSend ? _send : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!mediaStoreFutureReady || sendingImage)
                            SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  context.color.onPrimary,
                                ),
                              ),
                            )
                          else
                            const FaIcon(
                              FontAwesomeIcons.solidPaperPlane,
                              size: 14,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '${context.lang.shareImagedEditorSendImage} ($_recipientCount)',
                          ),
                        ],
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
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        childCount: groups.length,
        (context, i) {
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
            trailing: Checkbox.adaptive(
              value: selectedGroupIds.contains(group.groupId),
              side: WidgetStateBorderSide.resolveWith(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return const BorderSide(width: 0);
                  }
                  return BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  );
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
      ),
    );
  }
}
