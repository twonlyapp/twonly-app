import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/contact_groups.dart'
    as rust_contact_groups;
import 'package:twonly/core/database/app/contact_groups/table.dart'
    as db_contact_groups;
import 'package:twonly/core/database/app/contact_groups/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/contact/contact_group_settings.view.dart';

class ContactGroupsView extends StatefulWidget {
  const ContactGroupsView({super.key});

  @override
  State<ContactGroupsView> createState() => _ContactGroupsViewState();
}

class _ContactGroupsViewState extends State<ContactGroupsView> {
  late final Stream<List<ContactGroup>> _contactGroups;
  final Map<int, int> _memberCounts = {};
  StreamSubscription<List<ContactGroupMemberCount>>? _memberCountsSub;

  @override
  void initState() {
    super.initState();
    _contactGroups = watchRustDatabase(
      (control) => rust_contact_groups.watchContactGroups(
        filter: db_contact_groups.ContactGroupFilter.all,
        control: control,
      ),
    );
    _memberCountsSub =
        watchRustDatabase(
          (control) => rust_contact_groups.watchContactGroupMemberCounts(
            control: control,
          ),
        ).listen((counts) {
          if (!mounted) return;
          setState(() {
            _memberCounts
              ..clear()
              ..addAll({
                for (final count in counts)
                  count.contactGroupId: count.memberCount,
              });
          });
        });
  }

  @override
  void dispose() {
    unawaited(_memberCountsSub?.cancel());
    super.dispose();
  }

  Future<void> _openSettings([ContactGroup? contactGroup]) async {
    await context.navPush(
      ContactGroupSettingsView(contactGroup: contactGroup),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.contactGroupsTitle),
        actions: [
          IconButton(
            tooltip: context.lang.createContactGroup,
            icon: const Icon(Icons.add),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: StreamBuilder<List<ContactGroup>>(
        stream: _contactGroups,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final contactGroups = snapshot.data!;
          if (contactGroups.isEmpty) {
            return Center(
              child: MyButton(
                variant: MyButtonVariant.primaryDense,
                onPressed: _openSettings,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add),
                    const SizedBox(width: 8),
                    Text(context.lang.createContactGroup),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: contactGroups.length,
            itemBuilder: (context, index) {
              final contactGroup = contactGroups[index];
              final subtitle = [
                context.lang.contactGroupMemberCount(
                  _memberCounts[contactGroup.id] ?? 0,
                ),
                if (contactGroup.showAsLabel)
                  context.lang.contactGroupLabelFeature,
                if (contactGroup.showAsShortcut)
                  context.lang.contactGroupShortcutFeature,
                if (contactGroup.shareStories)
                  context.lang.contactGroupStoriesFeature,
              ].join(' · ');
              return ListTile(
                key: ValueKey(contactGroup.id),
                title: Text(contactGroup.name),
                subtitle: Text(subtitle),
                onTap: () => _openSettings(contactGroup),
              );
            },
          );
        },
      ),
    );
  }
}
