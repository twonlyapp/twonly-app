import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';

class UserDiscoveryManualApprovalComp extends StatefulWidget {
  const UserDiscoveryManualApprovalComp({required this.group, super.key});

  final Group group;

  @override
  State<UserDiscoveryManualApprovalComp> createState() =>
      _UserDiscoveryManualApprovalCompState();
}

class _UserDiscoveryManualApprovalCompState
    extends State<UserDiscoveryManualApprovalComp> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<(Contact, GroupMember)>>(
      stream: watchRustDatabase(
        (control) => rust_groups
            .watchGroupContacts(
              input: db_groups.GroupMembersQuery(
                groupId: widget.group.groupId,
              ),
              control: control,
            )
            .map(joinedGroupContacts),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final contactsToApprove = snapshot.data!
            .map((e) => e.$1)
            .where(UserDiscoveryService.shouldRequestManualApproval)
            .toList();

        if (contactsToApprove.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: contactsToApprove.map((contact) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AvatarIcon(contactId: contact.userId, fontSize: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.lang
                              .userDiscoveryManualApprovalReachedThreshold(
                                getContactDisplayName(contact),
                              ),
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await rust_contacts.updateContact(
                            id: contact.userId,
                            patch: const ContactPatch(
                              userDiscoveryExcluded: true,
                            ),
                            transaction: currentDatabaseSession(),
                          );
                        },
                        child: Text(
                          context.lang.userDiscoveryManualApprovalHideContact,
                        ),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await rust_contacts.updateContact(
                            id: contact.userId,
                            patch: ContactPatch(
                              userDiscoveryManualApproved: NullableInt(
                                value: databaseNullableFlag(true),
                              ),
                            ),
                            transaction: currentDatabaseSession(),
                          );
                        },
                        child: Text(
                          context.lang.userDiscoveryManualApprovalShareContact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
