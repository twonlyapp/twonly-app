import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/user_discovery/types.pb.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/context_menu/user.context_menu.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/settings/privacy/user_discovery/user_discovery_settings.view.dart';

class UserDiscoveryEnabledComp extends StatefulWidget {
  const UserDiscoveryEnabledComp({super.key});

  @override
  State<UserDiscoveryEnabledComp> createState() =>
      _UserDiscoveryEnabledCompState();
}

class _UserDiscoveryEnabledCompState extends State<UserDiscoveryEnabledComp> {
  UserDiscoveryVersion? _version;

  List<Contact> _contactsGettingAnnounced = [];
  late StreamSubscription<List<Contact>> _contactsGettingAnnouncedStream;

  @override
  void initState() {
    _contactsGettingAnnouncedStream = twonlyDB.contactsDao
        .watchContactsAnnouncedViaUserDiscovery()
        .listen((contacts) {
          setState(() {
            _contactsGettingAnnounced = contacts;
          });
        });
    _initAsync();
    super.initState();
  }

  @override
  void dispose() {
    _contactsGettingAnnouncedStream.cancel();
    super.dispose();
  }

  Future<void> _initAsync() async {
    final version = await UserDiscoveryService.getCurrentVersionTyped();
    if (mounted) {
      setState(() {
        _version = version;
      });
    }
  }

  Future<void> _disableUserDiscovery() async {
    final ok = await showAlertDialog(
      context,
      context.lang.userDiscoveryEnabledDialogTitle,
      context.lang.userDiscoveryEnabledDisableWarning,
    );

    if (ok) {
      await UserDiscoveryService.disable();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ListView(
        children: [
          ExpansionTile(
            shape: const RoundedRectangleBorder(),
            backgroundColor: context.color.surfaceContainer,
            collapsedShape: const RoundedRectangleBorder(),
            tilePadding: const EdgeInsets.symmetric(horizontal: 17),
            title: Text(context.lang.userDiscoveryEnabledFriendsShared),
            subtitle: Text(
              context.lang.userDiscoveryEnabledFriendsSharedDesc,
              style: const TextStyle(fontSize: 10),
            ),
            children: _contactsGettingAnnounced.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsetsGeometry.symmetric(vertical: 12),
                      child: Text(
                        context.lang.userDiscoveryEnabledNoFriendsShared,
                      ),
                    ),
                  ]
                : _contactsGettingAnnounced.map((contact) {
                    final version =
                        UserDiscoveryService.getContactVersionTypedFromContact(
                          contact,
                        );

                    return UserContextMenu(
                      key: ValueKey(contact.userId),
                      contact: contact,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        minVerticalPadding: 0,
                        title: Text(getContactDisplayName(contact)),
                        leading: AvatarIcon(
                          contactId: contact.userId,
                          fontSize: 17,
                        ),
                        subtitle:
                            (version != null &&
                                (userService.currentUser.isDeveloper ||
                                    !kReleaseMode))
                            ? Text(
                                context.lang.userDiscoveryEnabledVersion(
                                  '${version.announcement}.${version.promotion}',
                                ),
                                style: const TextStyle(fontSize: 10),
                              )
                            : null,
                        trailing: SizedBox(
                          height: 26,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.only(right: 8, left: 8),
                            ).merge(secondaryGreyButtonStyle(context)),
                            child: Text(
                              context.lang.userDiscoveryEnabledStopSharing,
                              style: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () async {
                              await twonlyDB.contactsDao.updateContact(
                                contact.userId,
                                const ContactsCompanion(
                                  userDiscoveryExcluded: Value(true),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
          ),
          ListTile(
            title: Text(context.lang.userDiscoveryEnabledChangeSettings),
            onTap: () async {
              await context.navPush(const UserDiscoverySettingsView());
              await _initAsync();
            },
          ),
          const Divider(),
          ListTile(
            title: Text(context.lang.userDiscoveryDisabledLearnMore),
            subtitle: Text(
              context.lang.userDiscoveryEnabledFaq,
            ),
            onTap: () => context.push(Routes.settingsHelpFaq),
          ),
          const Divider(),
          ListTile(
            title: Text(context.lang.userDiscoveryActionDisable),
            onTap: _disableUserDiscovery,
          ),
          if (_version != null &&
              (userService.currentUser.isDeveloper || !kReleaseMode))
            ListTile(
              title: Text(
                context.lang.userDiscoveryEnabledYourVersion(
                  '${_version!.announcement}.${_version!.promotion}',
                ),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
