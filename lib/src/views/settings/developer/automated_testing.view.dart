import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:libsignal_protocol_dart/libsignal_protocol_dart.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/api/messages.dart';
import 'package:twonly/src/services/signal/utils.signal.dart';
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
            title: const Text('Trigger Signal Out-Of-Sync'),
            onTap: () async {
              final username = await showUserNameDialog(context);
              if (username == null) return;
              final contacts = await twonlyDB.contactsDao
                  .getContactsByUsername(username.toLowerCase());
              if (contacts.length != 1) {
                Log.error('No single user fund');
                return;
              }
              final userId = contacts.first.userId;

              final group = await twonlyDB.groupsDao.getDirectChat(userId);
              if (group == null) {
                Log.error('Target user must have a group!');
                return;
              }

              final sessionStore = await getSignalStore();

              // 1. Store a valid session
              final originalSession =
                  await sessionStore!.loadSession(getSignalAddress(userId));
              final serializedSession = originalSession.serialize();

              for (var i = 0; i < 10; i++) {
                await insertAndSendTextMessage(
                  group.groupId,
                  'DesyncTest_1',
                  null,
                );
              }

              final corruptedSession =
                  SessionRecord.fromSerialized(serializedSession);
              await sessionStore.storeSession(
                getSignalAddress(userId),
                corruptedSession,
              );

              await insertAndSendTextMessage(
                group.groupId,
                'DesyncTest_2',
                null,
              );

              // The other client should res
            },
          ),
          ListTile(
            title: const Text('Sending a lot of messages.'),
            subtitle: Text(lotsOfMessagesStatus),
            onTap: () async {
              final username = await showUserNameDialog(context);
              if (username == null) return;
              Log.info('Requested to send to $username');

              final contacts = await twonlyDB.contactsDao
                  .getContactsByUsername(username.toLowerCase());

              for (final contact in contacts) {
                Log.info('Sending to ${contact.username}');
                final group =
                    await twonlyDB.groupsDao.getDirectChat(contact.userId);
                for (var i = 0; i < 200; i++) {
                  setState(() {
                    lotsOfMessagesStatus =
                        'At message $i to ${contact.username}.';
                  });
                  await insertAndSendTextMessage(
                    group!.groupId,
                    'Message $i.',
                    null,
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
              Navigator.of(context)
                  .pop(controller.text); // Return the input text
            },
          ),
        ],
      );
    },
  );
  return controller.text;
}
