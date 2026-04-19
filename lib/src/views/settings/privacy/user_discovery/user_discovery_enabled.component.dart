import 'package:flutter/material.dart';

class UserDiscoveryEnabledComponent extends StatefulWidget {
  const UserDiscoveryEnabledComponent({required this.onUpdate, super.key});

  final VoidCallback onUpdate;

  @override
  State<UserDiscoveryEnabledComponent> createState() =>
      _UserDiscoveryEnabledComponentState();
}

class _UserDiscoveryEnabledComponentState
    extends State<UserDiscoveryEnabledComponent> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ListView(
        children: [
          const ExpansionTile(
            shape: RoundedRectangleBorder(),
            collapsedShape: RoundedRectangleBorder(),
            tilePadding: EdgeInsets.symmetric(horizontal: 17),
            title: Text('Freunde die du teilst'),
            subtitle: Text(
              'Du teilst nur Freunde, die diese Funktion ebenfalls aktiviert haben und die den von dir festgelegten Schwellenwert erreicht haben.',
              style: TextStyle(fontSize: 10),
            ),
            children: [],
          ),
          ListTile(
            title: Text('Einstellungen ändern'),
            // onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: Text('Deaktivieren'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
