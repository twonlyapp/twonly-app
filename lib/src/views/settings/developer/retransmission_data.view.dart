import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';

class RetransmissionDataView extends StatefulWidget {
  const RetransmissionDataView({super.key});

  @override
  State<RetransmissionDataView> createState() => _RetransmissionDataViewState();
}

class RetransMsg {
  RetransMsg({
    required this.receipt,
    required this.contact,
  });
  final Receipt receipt;
  final Contact? contact;

  static List<RetransMsg> fromRaw(
    List<Receipt> receipts,
    Map<int, Contact> contacts,
  ) {
    final res = <RetransMsg>[];
    for (final receipt in receipts) {
      res.add(
        RetransMsg(
          receipt: receipt,
          contact: contacts[receipt.contactId],
        ),
      );
    }
    return res;
  }
}

class _RetransmissionDataViewState extends State<RetransmissionDataView> {
  List<Receipt> retransmissions = [];
  Map<int, Contact> contacts = {};
  StreamSubscription<List<Receipt>>? subscriptionRetransmission;
  StreamSubscription<List<Contact>>? subscriptionContacts;
  List<RetransMsg> messages = [];

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  @override
  void dispose() {
    subscriptionRetransmission?.cancel();
    subscriptionContacts?.cancel();
    super.dispose();
  }

  Future<void> initAsync() async {
    subscriptionContacts =
        twonlyDB.contactsDao.watchAllContacts().listen((updated) {
      for (final contact in updated) {
        contacts[contact.userId] = contact;
      }
      if (retransmissions.isNotEmpty) {
        messages = RetransMsg.fromRaw(retransmissions, contacts);
      }
      setState(() {});
    });
    subscriptionRetransmission =
        twonlyDB.receiptsDao.watchAll().listen((updated) {
      retransmissions = updated;
      if (contacts.isNotEmpty) {
        messages = RetransMsg.fromRaw(retransmissions, contacts);
      }
      setState(() {});
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
          Expanded(
            child: ListView(
              children: messages
                  .map(
                    (retrans) => ListTile(
                      title: Text(
                        retrans.receipt.receiptId,
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To ${retrans.contact?.username}',
                          ),
                          Text(
                            'Server-Ack: ${retrans.receipt.ackByServerAt}',
                          ),
                          Text(
                            'Retry: ${retrans.receipt.retryCount} : ${retrans.receipt.lastRetry}',
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
