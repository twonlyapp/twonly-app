import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
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
  late final StreamSubscription<List<ContactGroup>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = twonlyDB.contactGroupsDao
        .watchShortcutContactGroups()
        .listen((contactGroups) {
          if (mounted) setState(() => _contactGroups = contactGroups);
        });
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }

  Future<void> _openSettings([ContactGroup? contactGroup]) async {
    await context.navPush(
      ContactGroupSettingsView(
        contactGroup: contactGroup,
        initialShowAsShortcut: contactGroup == null,
      ),
    );
  }

  Future<void> _apply(ContactGroup contactGroup) async {
    await twonlyDB.contactGroupsDao.incrementUsage(contactGroup.id);
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
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ActionChip(
            padding: EdgeInsets.zero,
            tooltip: context.lang.createContactGroup,
            onPressed: _openSettings,
            label: _contactGroups.isEmpty
                ? Text(
                    context.lang.createContactGroup,
                    style: const TextStyle(fontSize: 9),
                  )
                : const Icon(Icons.add_reaction_outlined, size: 20),
            shape: const StadiumBorder(),
          ),
          for (final contactGroup in _contactGroups)
            GestureDetector(
              onLongPress: () => _openSettings(contactGroup),
              child: ActionChip(
                padding: EdgeInsets.zero,
                tooltip: contactGroup.name,
                onPressed: () => _apply(contactGroup),
                label: Text(
                  contactGroup.emoji ?? contactGroup.name,
                  style: const TextStyle(fontSize: 18),
                ),
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
  }
}
