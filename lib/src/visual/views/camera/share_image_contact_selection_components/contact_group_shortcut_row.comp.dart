import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_chip.element.dart';
import 'package:twonly/src/visual/views/camera/share_image_contact_selection_components/first_seen_order.dart';
import 'package:twonly/src/visual/views/contact/contact_group_settings.view.dart';

class ContactGroupShortcutRow extends StatefulWidget {
  const ContactGroupShortcutRow({
    required this.selectedGroupIds,
    required this.updateSelectedGroupIds,
    super.key,
  });

  final HashSet<String> selectedGroupIds;
  final void Function(String, bool) updateSelectedGroupIds;

  @override
  State<ContactGroupShortcutRow> createState() =>
      _ContactGroupShortcutRowState();
}

class _ContactGroupShortcutRowState extends State<ContactGroupShortcutRow> {
  List<ContactGroup> _contactGroups = [];
  final List<int> _order = [];

  /// The chats each shortcut selects, by contact group.
  Map<int, Set<String>> _targets = {};
  int _targetsGeneration = 0;
  late final StreamSubscription<List<ContactGroup>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = twonlyDB.contactGroupsDao
        .watchShortcutContactGroups()
        .listen((contactGroups) {
          if (!mounted) return;
          setState(
            () => _contactGroups = inFirstSeenOrder(contactGroups, _order),
          );
          unawaited(_loadTargets());
        });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  Future<void> _loadTargets() async {
    final generation = ++_targetsGeneration;
    final targets = {
      for (final contactGroup in _contactGroups)
        contactGroup.id: await _resolveTargets(contactGroup),
    };
    if (!mounted || generation != _targetsGeneration) return;
    setState(() => _targets = targets);
  }

  Future<Set<String>> _resolveTargets(ContactGroup contactGroup) async {
    final members = await twonlyDB.contactGroupsDao.getMembers(contactGroup.id);
    final targetGroupIds = <String>{};
    for (final member in members) {
      if (member.groupId != null) {
        targetGroupIds.add(member.groupId!);
      } else if (member.userId != null) {
        final directChat = await twonlyDB.groupsDao.getDirectChat(
          member.userId!,
        );
        if (directChat != null) targetGroupIds.add(directChat.groupId);
      }
    }
    return targetGroupIds;
  }

  /// A shortcut is on while every chat it stands for is selected, however
  /// they came to be.
  bool _isSelected(Set<String>? targets) =>
      targets != null &&
      targets.isNotEmpty &&
      widget.selectedGroupIds.containsAll(targets);

  Future<void> _openSettings([ContactGroup? contactGroup]) async {
    await context.navPush(
      ContactGroupSettingsView(
        contactGroup: contactGroup,
        initialShowAsShortcut: contactGroup == null,
      ),
    );
    // Members may have changed, which the contact groups alone do not show.
    if (mounted) await _loadTargets();
  }

  Future<void> _apply(ContactGroup contactGroup) async {
    final targetGroupIds = await _resolveTargets(contactGroup);
    if (!mounted) return;
    // Tapping a shortcut that is on turns it off again.
    if (_isSelected(targetGroupIds)) {
      for (final groupId in targetGroupIds) {
        widget.updateSelectedGroupIds(groupId, false);
      }
      return;
    }
    await twonlyDB.contactGroupsDao.incrementUsage(contactGroup.id);
    for (final groupId in widget.selectedGroupIds.toList()) {
      widget.updateSelectedGroupIds(groupId, false);
    }
    for (final groupId in targetGroupIds) {
      widget.updateSelectedGroupIds(groupId, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          MyChip(
            tooltip: context.lang.createContactGroup,
            onTap: _openSettings,
            label: _contactGroups.isEmpty
                ? Text(context.lang.createContactGroup)
                : const Icon(Icons.add_reaction_outlined),
          ),
          for (final contactGroup in _contactGroups) ...[
            const SizedBox(width: 8),
            MyChip(
              tooltip: contactGroup.name,
              selected: _isSelected(_targets[contactGroup.id]),
              onTap: () => _apply(contactGroup),
              onLongPress: () => _openSettings(contactGroup),
              label: Text(
                contactGroup.emoji ?? contactGroup.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
