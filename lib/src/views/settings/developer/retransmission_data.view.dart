import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/json/message_old.dart';
import 'package:twonly/src/services/api/messages.dart';

class RetransmissionDataView extends StatefulWidget {
  const RetransmissionDataView({super.key});

  @override
  State<RetransmissionDataView> createState() => _RetransmissionDataViewState();
}

class RetransMsg {
  RetransMsg({
    required this.json,
    required this.retrans,
    required this.contact,
  });
  final MessageJson json;
  final MessageRetransmission retrans;
  final Contact? contact;

  static List<RetransMsg> fromRaw(
    List<MessageRetransmission> retrans,
    Map<int, Contact> contacts,
  ) {
    final res = <RetransMsg>[];

    for (final retrans in retrans) {
      final json = MessageJson.fromJson(
        jsonDecode(
          utf8.decode(
            gzip.decode(retrans.plaintextContent),
          ),
        ) as Map<String, dynamic>,
      );
      res.add(
        RetransMsg(
          json: json,
          retrans: retrans,
          contact: contacts[retrans.contactId],
        ),
      );
    }
    return res;
  }
}

class _RetransmissionDataViewState extends State<RetransmissionDataView> {
  List<MessageRetransmission> retransmissions = [];
  Map<int, Contact> contacts = {};
  StreamSubscription<List<MessageRetransmission>>? subscriptionRetransmission;
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
        twonlyDB.messageRetransmissionDao.watchAllMessages().listen((updated) {
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
                        '${retrans.retrans.retransmissionId}: ${retrans.json.kind}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To ${retrans.contact?.username}',
                          ),
                          Text(
                            'Server-Ack: ${retrans.retrans.acknowledgeByServerAt}',
                          ),
                          Text(
                            'Retry: ${retrans.retrans.retryCount} : ${retrans.retrans.lastRetry}',
                          ),
                        ],
                      ),
                      trailing: SizedBox(
                        width: 80,
                        child: Row(
                          children: [
                            SizedBox(
                              height: 20,
                              width: 40,
                              child: Center(
                                child: GestureDetector(
                                  onDoubleTap: () async {
                                    await twonlyDB.messageRetransmissionDao
                                        .deleteRetransmissionById(
                                      retrans.retrans.retransmissionId,
                                    );
                                  },
                                  child: const FaIcon(
                                    FontAwesomeIcons.trash,
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: OutlinedButton(
                                style: ButtonStyle(
                                  padding: WidgetStateProperty.all<EdgeInsets>(
                                    EdgeInsets.zero,
                                  ),
                                ),
                                onPressed: () async {
                                  await twonlyDB.messageRetransmissionDao
                                      .updateRetransmission(
                                    retrans.retrans.retransmissionId,
                                    const MessageRetransmissionsCompanion(
                                      acknowledgeByServerAt: Value(null),
                                    ),
                                  );
                                  await sendRetransmitMessage(
                                    retrans.retrans.retransmissionId,
                                  );
                                },
                                child: const FaIcon(
                                  FontAwesomeIcons.arrowRotateLeft,
                                  size: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
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
