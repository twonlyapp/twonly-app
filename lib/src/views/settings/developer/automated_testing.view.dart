import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/services/api/messages.dart';

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
                await twonlyDB.messageRetransmissionDao
                    .clearRetransmissionTable();

                final contacts =
                    await twonlyDB.contactsDao.getAllNotBlockedContacts();

                for (final contact in contacts) {
                  for (var i = 0; i < 200; i++) {
                    setState(() {
                      lotsOfMessagesStatus =
                          'At message $i to ${contact.username}.';
                    });
                    await sendTextMessage(
                      contact.userId,
                      TextMessageContent(
                        text: 'TestMessage $i',
                      ),
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
