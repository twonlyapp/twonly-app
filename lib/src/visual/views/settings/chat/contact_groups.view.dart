import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/contact_groups.dart'
    as rust_contact_groups;
import 'package:twonly/core/database/app/contact_groups/table.dart'
    as db_contact_groups;
import 'package:twonly/core/database/app/contact_groups/table.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/contact/contact_group_settings.view.dart';

class ContactGroupsView extends StatefulWidget {
  const ContactGroupsView({super.key});

  @override
  State<ContactGroupsView> createState() => _ContactGroupsViewState();
}

class _ContactGroupsViewState extends State<ContactGroupsView> {
  late final Stream<List<ContactGroup>> _contactGroups;

  @override
  void initState() {
    super.initState();
    _contactGroups = watchRustDatabase(
      (control) => rust_contact_groups.watchContactGroups(
        filter: db_contact_groups.ContactGroupFilter.all,
        control: control,
      ),
    );
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
              child: FilledButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.add),
                label: Text(context.lang.createContactGroup),
              ),
            );
          }
          return ListView.builder(
            itemCount: contactGroups.length,
            itemBuilder: (context, index) {
              final contactGroup = contactGroups[index];
              return ListTile(
                key: ValueKey(contactGroup.id),
                leading: contactGroup.emoji == null
                    ? const Icon(Icons.people_outline)
                    : Text(
                        contactGroup.emoji!,
                        style: const TextStyle(fontSize: 24),
                      ),
                title: Text(contactGroup.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openSettings(contactGroup),
              );
            },
          );
        },
      ),
    );
  }
}
