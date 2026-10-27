import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart'
    show Int64List;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hashlib/random.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/bridge/database/receipts.dart' as rust_receipts;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/core/database/app/receipts/table.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/contact_name.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
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
    subscriptionContacts =
        watchRustDatabase(
          (control) => rust_contacts.watchContacts(
            input: db_contacts.ContactQuery(
              filter: db_contacts.ContactFilter.all,
              ids: Int64List(0),
            ),
            control: control,
          ),
        ).listen((
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
    subscriptionRetransmission =
        watchRustDatabase(
          (control) => rust_receipts.watchReceipts(control: control),
        ).listen((
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
      await rust_receipts.deleteReceipts(
        target: rust_receipts.ReceiptSelection.contact,
        id: '',
        contact: _filterForUserId!,
        transaction: currentDatabaseSession(),
      );
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

                      Text(
                        'Retry: ${retrans.receipt.retryCount} : ${retrans.receipt.lastRetry}',
                      ),
                    ],
                  ),
                  trailing: FilledButton.icon(
                    onPressed: () async {
                      final newReceiptId = uuid.v4();
                      await rust_receipts.updateReceipts(
                        target: rust_receipts.ReceiptSelection.id,
                        id: retrans.receipt.receiptId,
                        contact: 0,
                        patch: ReceiptPatch(
                          receiptId: newReceiptId,
                          ackByServerAt: NullableInt(
                            value: databaseNullableSeconds(null),
                          ),
                        ),
                        transaction: currentDatabaseSession(),
                      );
                      await RustApi.sendQueuedMessage(receiptId: newReceiptId);
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
