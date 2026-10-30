import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:twonly/core/bridge/database/contact_groups.dart'
    as rust_contact_groups;
import 'package:twonly/core/bridge/stories.dart' as stories;
import 'package:twonly/core/database/app/contact_groups/table.dart'
    as db_contact_groups;
import 'package:twonly/core/database/app/contact_groups/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/headline.element.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/first_seen_order.dart';
import 'package:twonly/src/visual/views/contact/contact_group_settings.view.dart';

/// The explicitly selected contact groups that receive a story. Kept by the
/// editor, so the choice survives a trip back to it.
class StoryTarget {
  final Set<int> contactGroupIds = {};

  bool get isEmpty => contactGroupIds.isEmpty;

  void clear() {
    contactGroupIds.clear();
  }

  stories.StoryAudience? toAudience() => isEmpty
      ? null
      : stories.StoryAudience(
          all: false,
          contactGroupIds: Int64List.fromList(contactGroupIds.toList()),
        );
}

/// The story groups at the top of the send screen.
class StoryTargetSelector extends StatefulWidget {
  const StoryTargetSelector({
    required this.target,
    required this.enabled,
    required this.onChanged,
    required this.onAudienceChanged,
    super.key,
  });

  final StoryTarget target;

  /// Off for media a story cannot carry, such as twonly-protected sends.
  final bool enabled;
  final VoidCallback onChanged;

  /// The 1:1 chats the chosen story reaches, or null while nothing is
  /// chosen or the answer is still coming.
  final ValueChanged<Set<String>?> onAudienceChanged;

  @override
  State<StoryTargetSelector> createState() => _StoryTargetSelectorState();
}

class _StoryTargetSelectorState extends State<StoryTargetSelector> {
  List<ContactGroup> _contactGroups = [];
  final List<int> _order = [];
  late final StreamSubscription<List<ContactGroup>> _subscription;
  Set<String>? _audienceChats;
  int _audienceGeneration = 0;

  @override
  void initState() {
    super.initState();
    _subscription =
        watchRustDatabase(
          (control) => rust_contact_groups.watchContactGroups(
            filter: db_contact_groups.ContactGroupFilter.stories,
            control: control,
          ),
        ).listen((
          contactGroups,
        ) {
          if (!mounted) return;
          // A group that stopped sharing stories cannot stay selected.
          final ids = contactGroups.map((group) => group.id).toSet();
          final before = widget.target.contactGroupIds.length;
          widget.target.contactGroupIds.retainAll(ids);
          setState(
            () => _contactGroups = inFirstSeenOrder(contactGroups, _order),
          );
          if (before != widget.target.contactGroupIds.length) _changed();
        });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_updateAudience());
    });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _changed() {
    widget.onChanged();
    if (_audienceChats != null) {
      _audienceChats = null;
      widget.onAudienceChanged(null);
    }
    setState(() {});
    unawaited(_updateAudience());
  }

  Future<void> _updateAudience() async {
    final generation = ++_audienceGeneration;
    final audience = widget.target.toAudience();
    final chats = audience == null
        ? null
        : (await stories.storyAudienceChats(audience: audience)).toSet();
    if (!mounted || generation != _audienceGeneration) return;
    widget.onAudienceChanged(chats);
    setState(() => _audienceChats = chats);
  }

  void _toggleGroup(ContactGroup contactGroup) {
    final ids = widget.target.contactGroupIds;
    if (!ids.remove(contactGroup.id)) ids.add(contactGroup.id);
    _changed();
  }

  Future<void> _createGroup() async {
    final id = await context.navPush(
      const ContactGroupSettingsView(initialShareStories: true),
    );
    if (id is int && mounted) {
      widget.target.contactGroupIds.add(id);
      _changed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    // In line with the other headings on the send screen, which come with
    // this much inset of their own.
    const inset = EdgeInsets.symmetric(horizontal: 4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            children: [
              HeadLineComp(context.lang.shareImageStory),
              const Spacer(),
              if (widget.enabled && _audienceChats != null)
                Text(
                  context.lang.shareImageStoryAudience(_audienceChats!.length),
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
        if (!widget.enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              context.lang.shareImageStoryUnavailable,
              style: TextStyle(
                fontSize: 12,
                color: context.color.onSurface.withAlpha(150),
              ),
            ),
          )
        else
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: inset,
              children: [
                for (final contactGroup in _contactGroups) ...[
                  MyChip(
                    label: Text(
                      [
                        if (contactGroup.emoji != null) contactGroup.emoji!,
                        contactGroup.name,
                      ].join(' '),
                    ),
                    selected: target.contactGroupIds.contains(
                      contactGroup.id,
                    ),
                    onTap: () => _toggleGroup(contactGroup),
                    onLongPress: () => context.navPush(
                      ContactGroupSettingsView(contactGroup: contactGroup),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                MyChip(
                  tooltip: context.lang.shareImageStoryNewGroup,
                  onTap: _createGroup,
                  label: _contactGroups.isEmpty
                      ? Text(context.lang.shareImageStoryNewGroup)
                      : const Icon(Icons.add),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
