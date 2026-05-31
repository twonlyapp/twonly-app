import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery.view.dart';

class UserDiscoveryContactSettingsComp extends StatelessWidget {
  const UserDiscoveryContactSettingsComp({
    required this.contact,
    super.key,
  });

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    if (!userService.currentUser.isUserDiscoveryEnabled) {
      return const SizedBox.shrink();
    }

    if (userService.currentUser.userDiscoveryRequiresManualApproval &&
        contact.userDiscoveryManualApproved != true) {
      return BetterListTile(
        icon: FontAwesomeIcons.usersViewfinder,
        text: context.lang.userDiscoverySettingsTitle,
        subtitle: Text(
          context.lang.contactUserDiscoveryManualApprovalPending,
          style: const TextStyle(fontSize: 10),
        ),
        trailing: TextButton(
          onPressed: () async {
            await twonlyDB.contactsDao.updateContact(
              contact.userId,
              const ContactsCompanion(
                userDiscoveryManualApproved: Value(true),
              ),
            );
          },
          child: Text(
            context.lang.contactUserDiscoveryManualApprovalApprove,
          ),
        ),
      );
    }

    return BetterListTile(
      icon: FontAwesomeIcons.usersViewfinder,
      text: context.lang.userDiscoverySettingsTitle,
      onTap: () => context.navPush(const UserDiscoverySettingsView()),
      subtitle:
          !contact.userDiscoveryExcluded &&
              contact.mediaSendCounter <
                  userService.currentUser.requiredSendImages
          ? Text(
              context.lang.contactUserDiscoveryImagesLeft(
                userService.currentUser.requiredSendImages -
                    contact.mediaSendCounter,
                getContactDisplayName(contact),
              ),
              style: const TextStyle(fontSize: 9),
            )
          : null,
      trailing: Transform.scale(
        scale: 0.8,
        child: Switch.adaptive(
          value: !contact.userDiscoveryExcluded,
          onChanged: (a) async {
            await UserDiscoveryService.changeExclusionForContact(
              contact.userId,
              !a,
            );
          },
        ),
      ),
    );
  }
}
