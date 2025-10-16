import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';

class RetransmissionDataView extends StatefulWidget {
  const RetransmissionDataView({super.key});

  @override
  State<RetransmissionDataView> createState() => _RetransmissionDataViewState();
}

class _RetransmissionDataViewState extends State<RetransmissionDataView> {
  List<MessageRetransmission> retransmissions = [];
  List<Contact> contacts = [];
  StreamSubscription<List<MessageRetransmission>>? subscriptionRetransmission;
  StreamSubscription<List<Contact>>? subscriptionContacts;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  @override
  void dispose() {
    // ignore: discarded_futures
    subscriptionRetransmission?.cancel();
    // ignore: discarded_futures
    subscriptionContacts?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    subscriptionContacts =
        twonlyDB.contactsDao.watchAllContacts().listen((updated) {
      setState(() {
        contacts = updated;
      });
    });
    subscriptionRetransmission =
        twonlyDB.messageRetransmissionDao.watchAllMessages().listen((updated) {
      setState(() {
        retransmissions = updated;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retransmission Database'),
      ),
      body: Column(
        children: [
          ListView(
            children: retransmissions
                .map(
                  (retrans) => ListTile(
                    title: Text(retrans.retransmissionId.toString()),
                    subtitle: Text('Message to ${retrans.contactId}'),
                  ),
                )
                .toList(),
          )
        ],
      ),
    );
  }
}
