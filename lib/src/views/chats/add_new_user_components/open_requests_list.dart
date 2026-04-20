import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/daos/user_discovery.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/themes/light.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/add_new_user_components/friend_suggestions.dart';
import 'package:twonly/src/views/components/avatar_icon.component.dart';
import 'package:twonly/src/views/components/headline.dart';

class OpenRequestsList extends StatelessWidget {
  const OpenRequestsList({
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
          const update = ContactsCompanion(deletedByUser: Value(true));
          await twonlyDB.contactsDao.updateContact(contact.userId, update);
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
              const Icon(
                Icons.person_off_rounded,
                color: Color.fromARGB(164, 244, 67, 54),
              ),
              Text(
                context.lang.contactActionBlock,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          onPressed: () async {
            const update = ContactsCompanion(blocked: Value(true));
            await twonlyDB.contactsDao.updateContact(contact.userId, update);
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
              const Icon(Icons.check, color: Colors.green),
              Text(
                context.lang.contactActionAccept,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
          onPressed: () async {
            await twonlyDB.contactsDao.updateContact(
              contact.userId,
              const ContactsCompanion(
                accepted: Value(true),
                requested: Value(false),
              ),
            );
            await twonlyDB.groupsDao.createNewDirectChat(
              contact.userId,
              GroupsCompanion(
                groupName: Value(getContactDisplayName(contact)),
              ),
            );
            await sendCipherText(
              contact.userId,
              EncryptedContent(
                contactRequest: EncryptedContent_ContactRequest(
                  type: EncryptedContent_ContactRequest_Type.ACCEPT,
                ),
              ),
            );
            await sendContactMyProfileData(contact.userId);
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
          await sendCipherText(
            contact.userId,
            EncryptedContent(
              contactRequest: EncryptedContent_ContactRequest(
                type: EncryptedContent_ContactRequest_Type.REJECT,
              ),
            ),
          );
          await twonlyDB.contactsDao.updateContact(
            contact.userId,
            const ContactsCompanion(
              accepted: Value(false),
              requested: Value(false),
              deletedByUser: Value(true),
            ),
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
        HeadLineComponent(
          context.lang.searchUsernameNewFollowerTitle,
        ),
        ...contacts.map((contact) {
          Widget? subtitle;

          Log.info('Relations count: ${relations.entries.length}');

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
            title: Text(substringBy(contact.username, 25)),
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
