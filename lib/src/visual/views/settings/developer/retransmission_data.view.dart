import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/client/generated/messages.pb.dart'
    as pb;
import 'package:twonly/src/services/api/messages.api.dart';
import 'package:twonly/src/services/notifications/pushkeys.notifications.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';

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

  Map<int, int> _contactCount = {};

  int? _filterForUserId;

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
    subscriptionContacts = twonlyDB.contactsDao.watchAllContacts().listen((
      updated,
    ) {
      if (!mounted) return;
      for (final contact in updated) {
        contacts[contact.userId] = contact;
      }
      if (retransmissions.isNotEmpty) {
        messages = RetransMsg.fromRaw(retransmissions, contacts);
      }
      setState(() {});
    });
    subscriptionRetransmission = twonlyDB.receiptsDao.watchAll().listen((
      updated,
    ) {
      if (!mounted) return;
      retransmissions = updated.reversed.toList();
      if (contacts.isNotEmpty) {
        messages = RetransMsg.fromRaw(retransmissions, contacts);
      }
      _contactCount = {};
      for (final retransmission in updated) {
        _contactCount[retransmission.contactId] =
            (_contactCount[retransmission.contactId] ?? 0) + 1;
      }
      setState(() {});
    });
  }

  Future<void> deleteAllForSelectedUser() async {
    final ok = await showAlertDialog(
      context,
      'Sure?',
      'This will delete all retransmission messages for ${contacts[_filterForUserId!]!.username}',
    );
    if (ok) {
      await twonlyDB.receiptsDao.deleteReceiptForUser(_filterForUserId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    var messagesToShow = messages;
    if (_filterForUserId != null) {
      messagesToShow = messagesToShow
          .where((m) => m.contact?.userId == _filterForUserId)
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retransmission Database'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: 1 + messagesToShow.length + _contactCount.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Center(
                    child: FilledButton(
                      onPressed: _filterForUserId == null
                          ? null
                          : deleteAllForSelectedUser,
                      child: const Text('Delete all shown entries'),
                    ),
                  );
                }
                index -= 1;
                if (index < _contactCount.length) {
                  final contact = contacts[_contactCount.keys.elementAt(index)];
                  if (contact == null) return Container();
                  return ListTile(
                    leading: AvatarIcon(
                      contactId: contact.userId,
                    ),
                    title: Text(
                      getContactDisplayName(contact),
                    ),
                    trailing: Text(
                      _contactCount.values.elementAt(index).toString(),
                    ),
                    onTap: () {
                      if (_filterForUserId == contact.userId) {
                        setState(() {
                          _filterForUserId = null;
                        });
                      } else {
                        setState(() {
                          _filterForUserId = contact.userId;
                        });
                      }
                    },
                  );
                }
                index -= _contactCount.length;
                final retrans = messagesToShow[index];
                return ListTile(
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
                      if (retrans.receipt.messageId != null)
                        Text(
                          'MessageId: ${retrans.receipt.messageId}',
                        ),
                      if (retrans.receipt.messageId != null)
                        FutureBuilder(
                          future: getPushNotificationFromEncryptedContent(
                            retrans.receipt.contactId,
                            retrans.receipt.messageId,
                            pb.EncryptedContent.fromBuffer(
                              pb.Message.fromBuffer(
                                retrans.receipt.message,
                              ).encryptedContent,
                            ),
                          ),
                          builder: (d, a) {
                            if (!a.hasData) return Container();
                            return Text(
                              'PushKind: ${a.data?.kind}',
                            );
                          },
                        ),
                      Text(
                        'Retry: ${retrans.receipt.retryCount} : ${retrans.receipt.lastRetry}',
                      ),
                    ],
                  ),
                  trailing: FilledButton.icon(
                    onPressed: () async {
                      final newReceiptId = uuid.v4();
                      await twonlyDB.receiptsDao.updateReceipt(
                        retrans.receipt.receiptId,
                        ReceiptsCompanion(
                          receiptId: Value(newReceiptId),
                          ackByServerAt: const Value(null),
                        ),
                      );
                      await tryToSendCompleteMessage(
                        receiptId: newReceiptId,
                      );
                    },
                    label: const FaIcon(FontAwesomeIcons.arrowRotateRight),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
