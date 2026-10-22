import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/groups.dart' as rust_groups;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/groups/table.dart' as db_groups;
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

class AutomatedTestingView extends StatefulWidget {
  const AutomatedTestingView({super.key});

  @override
  State<AutomatedTestingView> createState() => _AutomatedTestingViewState();
}

class _AutomatedTestingViewState extends State<AutomatedTestingView> {
  String lotsOfMessagesStatus = '';
  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {}

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return Container();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Testing'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Sending a lot of messages.'),
            subtitle: Text(lotsOfMessagesStatus),
            onTap: () async {
              final username = await showUserNameDialog(context);
              if (username == null) return;
              Log.info('Requested to send to $username');

              final contacts = await rust_contacts.listContacts(
                input: db_contacts.ContactQuery(
                  filter: db_contacts.ContactFilter.usernames,
                  ids: Int64List(0),
                  username: username.toLowerCase(),
                  username2: '_______',
                ),
                transaction: currentDatabaseSession(),
              );

              for (final contact in contacts) {
                Log.info('Sending to ${contact.username}');
                final group = await rust_groups
                    .listGroups(
                      input: db_groups.GroupQuery(
                        filter: db_groups.GroupFilter.directContact,
                        contactId: contact.userId,
                      ),
                      transaction: currentDatabaseSession(),
                    )
                    .then((rows) => rows.isEmpty ? null : rows.single);
                for (var i = 0; i < 200; i++) {
                  setState(() {
                    lotsOfMessagesStatus =
                        'At message $i to ${contact.username}.';
                  });
                  await RustApi.insertAndSendText(
                    groupId: group!.groupId,
                    text: 'Message $i.',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<String?> showUserNameDialog(
  BuildContext context,
) async {
  final controller = TextEditingController();

  await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Username'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.lang.cancel),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text(context.lang.ok),
            onPressed: () {
              Navigator.of(
                context,
              ).pop(controller.text); // Return the input text
            },
          ),
        ],
      );
    },
  );
  return controller.text;
}
