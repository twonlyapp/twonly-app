import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
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
      stream: twonlyDB.groupsDao.watchGroupMembers(widget.group.groupId),
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
                          await twonlyDB.contactsDao.updateContact(
                            contact.userId,
                            const ContactsCompanion(
                              userDiscoveryExcluded: Value(true),
                            ),
                          );
                        },
                        child: Text(
                          context.lang.userDiscoveryManualApprovalHideContact,
                        ),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await twonlyDB.contactsDao.updateContact(
                            contact.userId,
                            const ContactsCompanion(
                              userDiscoveryManualApproved: Value(true),
                            ),
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
