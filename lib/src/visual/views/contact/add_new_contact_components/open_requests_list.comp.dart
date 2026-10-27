import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/elements/headline.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/contact/add_new_contact_components/friend_suggestions.comp.dart';

class OpenRequestsListComp extends StatelessWidget {
  const OpenRequestsListComp({
    required this.contacts,
    required this.relations,
    super.key,
  });
  final List<Contact> contacts;
  final AnnouncedUsersWithRelations relations;

  List<Widget> sendRequestActions(BuildContext context, Contact contact) {
    return [
      Text(context.lang.searchUserNamePending),
      IconButton(
        style: IconButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.close, size: 18),
        onPressed: () async {
          const update = ContactPatch(deletedByUser: true);
          await rust_contacts.updateContact(
            id: contact.userId,
            patch: update,
            transaction: currentDatabaseSession(),
          );
        },
      ),
    ];
  }

  List<Widget> requestedActions(BuildContext context, Contact contact) {
    return [
      SizedBox(
        height: 26,
        child: FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 4,
            ),
          ).merge(secondaryGreyButtonStyle(context)),
          child: Row(
            children: [
              Icon(
                Icons.person_off_rounded,
                color: context.color.error,
              ),
              Text(
                context.lang.contactActionBlock,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          onPressed: () async {
            final block = await showAlertDialog(
              context,
              context.lang.contactBlockTitle(getContactDisplayName(contact)),
              context.lang.contactBlockBody,
            );
            if (block) {
              const update = ContactPatch(blocked: true);
              if (context.mounted) {
                await rust_contacts.updateContact(
                  id: contact.userId,
                  patch: update,
                  transaction: currentDatabaseSession(),
                );
              }
            }
          },
        ),
      ),
      const SizedBox(width: 9),
      SizedBox(
        height: 26,
        child: FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.only(right: 8, left: 4),
          ).merge(secondaryGreyButtonStyle(context)),
          child: Row(
            children: [
              Icon(Icons.check, color: context.appColor(AppColor.success)),
              Text(
                context.lang.contactActionAccept,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          onPressed: () async {
            await rust_contacts.updateContact(
              id: contact.userId,
              patch: const ContactPatch(accepted: true, requested: false),
              transaction: currentDatabaseSession(),
            );
            await rust_groups.createDirectGroup(
              contact: contact.userId,
              ownId: userService.currentUser.userId,
              patch: GroupPatch(groupName: getContactDisplayName(contact)),
              transaction: currentDatabaseSession(),
            );
            await RustApi.sendEncryptedContent(
              contactId: contact.userId,
              content: EncryptedContent(
                contactRequest: EncryptedContent_ContactRequest(
                  type: EncryptedContent_ContactRequest_Type.ACCEPT,
                ),
              ).writeToBuffer(),
              onlySendIfNoReceiptsAreOpen: false,
              onlyReturnEncryptedData: false,
              blocking: true,
            );
            await RustApi.sendContactProfile(contactId: contact.userId);
          },
        ),
      ),
      IconButton(
        style: IconButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.close, size: 18),
        onPressed: () async {
          await RustApi.sendEncryptedContent(
            contactId: contact.userId,
            content: EncryptedContent(
              contactRequest: EncryptedContent_ContactRequest(
                type: EncryptedContent_ContactRequest_Type.REJECT,
              ),
            ).writeToBuffer(),
            onlySendIfNoReceiptsAreOpen: false,
            onlyReturnEncryptedData: false,
            blocking: true,
          );
          await rust_contacts.updateContact(
            id: contact.userId,
            patch: const ContactPatch(
              accepted: false,
              requested: false,
              deletedByUser: true,
            ),
            transaction: currentDatabaseSession(),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) return Container();
    return Column(
      children: [
        const SizedBox(height: 20),
        HeadLineComp(
          context.lang.searchUsernameNewFollowerTitle,
        ),
        ...contacts.map((contact) {
          Widget? subtitle;
          for (final relation in relations.entries) {
            if (relation.key.announcedUserId == contact.userId) {
              subtitle = RichText(
                text: TextSpan(
                  children: buildFriendsListText(context, relation.value),
                  style: const TextStyle(fontSize: 11),
                ),
              );

              break;
            }
          }
          return ListTile(
            key: ValueKey(contact.userId),
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Text(substringBy(contact.username, 25)),
                const SizedBox(width: 3),
                VerificationBadgeComp(contact: contact),
              ],
            ),
            subtitle: subtitle,
            leading: AvatarIcon(
              contactId: contact.userId,
              fontSize: 17,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: contact.requested
                  ? requestedActions(context, contact)
                  : sendRequestActions(context, contact),
            ),
          );
        }),
      ],
    );
  }
}
