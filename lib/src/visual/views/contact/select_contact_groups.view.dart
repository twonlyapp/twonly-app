import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/contact_groups.comp.dart';
import 'package:twonly/src/visual/views/contact/contact_group_settings.view.dart';

class SelectContactGroupsView extends StatefulWidget {
  const SelectContactGroupsView({this.userId, this.groupId, super.key})
    : assert(
        userId != null || groupId != null,
        'pass either a userId or a groupId',
      );

  final int? userId;
  final String? groupId;

  @override
  State<SelectContactGroupsView> createState() =>
      _SelectContactGroupsViewState();
}

class _SelectContactGroupsViewState extends State<SelectContactGroupsView> {
  Contact? _contact;
  Group? _group;
  List<ContactGroup> _contactGroups = [];
  Set<int> _selectedIds = {};
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  String? get _groupId => widget.groupId;

  @override
  void initState() {
    super.initState();
    final groupId = _groupId;
    if (groupId != null) {
      _subscriptions.add(
        twonlyDB.groupsDao.watchGroup(groupId).listen((group) {
          if (mounted) setState(() => _group = group);
        }),
      );
    } else {
      _subscriptions.add(
        twonlyDB.contactsDao.watchContact(widget.userId!).listen((contact) {
          if (mounted) setState(() => _contact = contact);
        }),
      );
    }
    _subscriptions.add(
      twonlyDB.contactGroupsDao.watchAllContactGroups().listen((groups) {
        if (mounted) setState(() => _contactGroups = groups);
      }),
    );
    _subscriptions.add(
      (groupId != null
              ? twonlyDB.contactGroupsDao.watchContactGroupIdsForGroup(groupId)
              : twonlyDB.contactGroupsDao.watchContactGroupIdsForUser(
                  widget.userId!,
                ))
          .listen((ids) {
            if (mounted) setState(() => _selectedIds = ids);
          }),
    );
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }

  Future<void> _toggle(ContactGroup contactGroup) async {
    final selected = _selectedIds.contains(contactGroup.id);
    setState(() {
      if (selected) {
        _selectedIds.remove(contactGroup.id);
      } else {
        _selectedIds.add(contactGroup.id);
      }
    });
    final groupId = _groupId;
    if (groupId != null) {
      await twonlyDB.contactGroupsDao.setGroupMembership(
        contactGroup.id,
        groupId,
        !selected,
      );
    } else {
      await twonlyDB.contactGroupsDao.setUserMembership(
        contactGroup.id,
        widget.userId!,
        !selected,
      );
    }
  }

  Future<void> _openSettings([ContactGroup? contactGroup]) async {
    await context.navPush(
      ContactGroupSettingsView(contactGroup: contactGroup),
    );
  }

  Widget _preview(ContactGroup contactGroup) {
    final hasBackground = contactGroupHasBackground(
      contactGroup.backgroundColor,
    );
    return Container(
      padding: hasBackground
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 3)
          : EdgeInsets.zero,
      decoration: hasBackground
          ? BoxDecoration(
              color: Color(contactGroup.backgroundColor),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Text(
        contactGroup.name,
        style: TextStyle(
          color: Color(contactGroup.textColor),
          fontSize: contactGroupFontSize(11, contactGroup.backgroundColor),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _header() {
    final group = _group;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (group != null)
            AvatarIcon(group: group, fontSize: 24)
          else
            AvatarIcon(contactId: widget.userId, fontSize: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group != null
                      ? group.groupName
                      : getContactDisplayName(_contact!, maxLength: 25),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ContactGroupBadges(
                  userId: widget.userId,
                  groupId: widget.groupId,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.contactGroupsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.lang.createContactGroup,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_contact != null || _group != null) _header(),
          Expanded(
            child: _contactGroups.isEmpty
                ? Center(
                    child: FilledButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.add),
                      label: Text(context.lang.createContactGroup),
                    ),
                  )
                : ListView.builder(
                    itemCount: _contactGroups.length,
                    itemBuilder: (context, index) {
                      final contactGroup = _contactGroups[index];
                      final selected = _selectedIds.contains(contactGroup.id);
                      final features = [
                        if (contactGroup.showAsLabel)
                          context.lang.contactGroupLabelFeature,
                        if (contactGroup.showAsShortcut)
                          context.lang.contactGroupShortcutFeature,
                      ].join(' · ');
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                        horizontalTitleGap: 4,
                        leading: Checkbox.adaptive(
                          value: selected,
                          onChanged: (_) => _toggle(contactGroup),
                        ),
                        title: Align(
                          alignment: Alignment.centerLeft,
                          child: _preview(contactGroup),
                        ),
                        subtitle: features.isEmpty
                            ? null
                            : Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  features,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).disabledColor,
                                  ),
                                ),
                              ),
                        trailing: IconButton(
                          tooltip: context.lang.contactGroupSettings,
                          onPressed: () => _openSettings(contactGroup),
                          icon: const FaIcon(FontAwesomeIcons.gear, size: 17),
                        ),
                        onTap: () => _toggle(contactGroup),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
