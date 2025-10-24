import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/services/api/messages.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Testing'),
      ),
      body: ListView(
        children: [
          if (kDebugMode)
            ListTile(
              title: const Text('Sending a lot of messages.'),
              subtitle: Text(lotsOfMessagesStatus),
              onTap: () async {
                final username = await showUserNameDialog(context);
                if (username == null) return;

                final contacts =
                    await twonlyDB.contactsDao.getContactsByUsername(username);

                for (final contact in contacts) {
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
) {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
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
}
