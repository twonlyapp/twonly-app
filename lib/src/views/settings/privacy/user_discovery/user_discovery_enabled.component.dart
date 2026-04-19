import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/user_discovery/types.pb.dart';
import 'package:twonly/src/services/user_discovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/privacy/user_discovery/user_discovery_settings.view.dart';

class UserDiscoveryEnabledComponent extends StatefulWidget {
  const UserDiscoveryEnabledComponent({required this.onUpdate, super.key});

  final VoidCallback onUpdate;

  @override
  State<UserDiscoveryEnabledComponent> createState() =>
      _UserDiscoveryEnabledComponentState();
}

class _UserDiscoveryEnabledComponentState
    extends State<UserDiscoveryEnabledComponent> {
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
      'Wirklich deaktivieren?',
      'Wenn du das Feature „Freunde finden“ deaktivierst, werden dir keine Vorschläge mehr angezeigt. Du teilst neuen Kontakten dann auch nicht mehr deine Freunde.',
    );

    if (ok) {
      await UserDiscoveryService.disable();
    }

    // This will show the DisabledComponent as the gUser has been updated...
    widget.onUpdate();
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
            title: const Text('Freunde die du teilst'),
            subtitle: const Text(
              'Du teilst nur Freunde, die diese Funktion ebenfalls aktiviert haben und die den von dir festgelegten Schwellenwert erreicht haben.',
              style: TextStyle(fontSize: 10),
            ),
            children: _contactsGettingAnnounced.isEmpty
                ? [
                    const Padding(
                      padding: EdgeInsetsGeometry.symmetric(vertical: 12),
                      child: Text(
                        'Bisher teilst du noch niemanden.',
                      ),
                    ),
                  ]
                : _contactsGettingAnnounced.map((contact) {
                    return Text(getContactDisplayName(contact));
                  }).toList(),
          ),
          ListTile(
            title: const Text('Einstellungen ändern'),
            onTap: () async {
              await context.navPush(const UserDiscoverySettingsView());
              await _initAsync();
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('Mehr erfahren'),
            subtitle: Text(
              'In unserem FAQ erklären wir dir wie das Feature "Freunde finden" funktioniert.',
            ),
            // onTap: _disableUserDiscovery,
          ),
          const Divider(),
          ListTile(
            title: const Text('Deaktivieren'),
            onTap: _disableUserDiscovery,
          ),
          if (_version != null)
            ListTile(
              title: Text(
                'Your version: ${_version!.announcement}.${_version!.promotion}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
