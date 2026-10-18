import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
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
    _contactGroups = twonlyDB.contactGroupsDao.watchAllContactGroups();
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
