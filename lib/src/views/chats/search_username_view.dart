import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:twonly/src/components/alert_dialog.dart';
import 'package:twonly/src/database/contacts_db.dart';
import 'package:twonly/src/database/database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/headline.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/json/message.dart';
import 'package:twonly/src/providers/api/api.dart';
// ignore: library_prefixes
import 'package:twonly/src/utils/signal.dart' as SignalHelper;

class SearchUsernameView extends StatefulWidget {
  const SearchUsernameView({super.key});

  @override
  State<SearchUsernameView> createState() => _SearchUsernameView();
}

class _SearchUsernameView extends State<SearchUsernameView> {
  final TextEditingController searchUserName = TextEditingController();
  bool _isLoading = false;

  Future _addNewUser(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    final res = await apiProvider.getUserData(searchUserName.text);

    if (!context.mounted) {
      return;
    }

    if (res.isSuccess) {
      final addUser = await showAlertDialog(
          context, "User found", "Do you want to create a follow request?");
      if (!addUser || !context.mounted) {
        return;
      }

      int added = await twonlyDatabase.insertContact(ContactsCompanion(
        username: Value(searchUserName.text),
        userId: Value(res.value.userdata.userId),
        requested: Value(false),
      ));

      if (added > 0) {
        if (await SignalHelper.addNewContact(res.value.userdata)) {
          encryptAndSendMessage(
            res.value.userdata.userId,
            MessageJson(
              kind: MessageKind.contactRequest,
              timestamp: DateTime.now(),
              content: MessageContent(),
            ),
          );
        }
      }
    } else {
      showAlertDialog(context, context.lang.searchUsernameNotFound,
          context.lang.searchUsernameNotFoundBody(searchUserName.text));
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration getInputDecoration(hintText) {
      final primaryColor =
          Theme.of(context).colorScheme.primary; // Get the primary color
      return InputDecoration(
        hintText: hintText,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9.0),
          borderSide: BorderSide(color: primaryColor, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline, width: 1.0),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      );
    }

    Stream<List<Contact>> contacts = twonlyDatabase.watchNotAcceptedContacts();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.searchUsernameTitle),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: 20, left: 10, top: 20, right: 10),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                onSubmitted: (_) {
                  _addNewUser(context);
                },
                controller: searchUserName,
                decoration:
                    getInputDecoration(context.lang.searchUsernameInput),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: Icon(Icons.qr_code),
              onPressed: () {
                showAlertDialog(context, "Coming soon",
                    "This feature is not yet implemented!");
              },
              label: Text(context.lang.searchUsernameQrCodeBtn),
            ),
            SizedBox(height: 30),
            StreamBuilder(
              stream: contacts,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data != null) {
                  return Container();
                }
                final contacts = snapshot.data!;
                if (contacts.isEmpty) {
                  return Container();
                }
                return Row(children: [
                  HeadLineComponent(
                      context.lang.searchUsernameNewFollowerTitle),
                  Expanded(
                    child: ContactsListView(contacts),
                  )
                ]);
              },
            )
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: FloatingActionButton(
          onPressed: () {
            if (!_isLoading) _addNewUser(context);
          },
          child: (_isLoading)
              ? const Center(child: CircularProgressIndicator())
              : Icon(Icons.arrow_right_rounded),
        ),
      ),
    );
  }
}

class ContactsListView extends StatefulWidget {
  const ContactsListView(this.contacts, {super.key});

  final List<Contact> contacts;

  @override
  State<ContactsListView> createState() => _ContactsListViewState();
}

class _ContactsListViewState extends State<ContactsListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.contacts.length,
      itemBuilder: (context, index) {
        final contact = widget.contacts[index];
        final displayName = getContactDisplayName(contact);
        return ListTile(
          title: Text(displayName),
          leading: InitialsAvatar(displayName),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!contact.requested) Text('Pending'),
              if (contact.requested) ...[
                Tooltip(
                  message: "Block the user without informing.",
                  child: IconButton(
                    icon: Icon(Icons.person_off_rounded,
                        color: const Color.fromARGB(164, 244, 67, 54)),
                    onPressed: () async {
                      final update = ContactsCompanion(blocked: Value(true));
                      await twonlyDatabase.updateContact(
                          contact.userId, update);
                    },
                  ),
                ),
                Tooltip(
                  message: "Reject the request and let the requester know.",
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () async {
                      await twonlyDatabase
                          .deleteContactByUserId(contact.userId);
                      encryptAndSendMessage(
                        contact.userId,
                        MessageJson(
                          kind: MessageKind.rejectRequest,
                          timestamp: DateTime.now(),
                          content: MessageContent(),
                        ),
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: () async {
                    final update = ContactsCompanion(accepted: Value(true));
                    await twonlyDatabase.updateContact(contact.userId, update);
                    encryptAndSendMessage(
                      contact.userId,
                      MessageJson(
                        kind: MessageKind.acceptRequest,
                        timestamp: DateTime.now(),
                        content: MessageContent(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
