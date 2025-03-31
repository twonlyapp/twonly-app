import 'package:drift/drift.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/components/alert_dialog.dart';
import 'package:twonly/src/components/better_list_title.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/verified_shield.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact_verify_view.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';

class ContactView extends StatefulWidget {
  const ContactView(this.userId, {super.key});

  final int userId;

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  @override
  Widget build(BuildContext context) {
    Stream<Contact?> contact = twonlyDatabase.contactsDao
        .getContactByUserId(widget.userId)
        .watchSingleOrNull();

    return Scaffold(
      appBar: AppBar(
        title: Text(""),
      ),
      body: StreamBuilder(
        stream: contact,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container();
          }
          final contact = snapshot.data!;
          int flameCounter = getFlameCounterFromContact(contact);
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: ContactAvatar(contact: contact, fontSize: 30),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: VerifiedShield(contact)),
                  Text(
                    getContactDisplayName(contact),
                    style: TextStyle(fontSize: 20),
                  ),
                  if (flameCounter > 0)
                    FlameCounterWidget(
                      contact,
                      flameCounter,
                      110000000,
                      prefix: true,
                    ),
                ],
              ),
              if (getContactDisplayName(contact) != contact.username)
                Center(child: Text("(${contact.username})")),
              SizedBox(height: 50),
              BetterListTile(
                icon: FontAwesomeIcons.pencil,
                text: context.lang.contactNickname,
                onTap: () async {
                  String? nickName =
                      await showNicknameChangeDialog(context, contact);

                  if (context.mounted && nickName != null && nickName != "") {
                    final update = ContactsCompanion(nickName: Value(nickName));
                    twonlyDatabase.contactsDao
                        .updateContact(contact.userId, update);
                  }
                },
              ),
              const Divider(),
              BetterListTile(
                icon: FontAwesomeIcons.shieldHeart,
                text: context.lang.contactVerifyNumberTitle,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) {
                      return ContactVerifyView(contact);
                    },
                  ));
                },
              ),
              BetterListTile(
                icon: FontAwesomeIcons.trashCan,
                text: context.lang.deleteAllContactMessages,
                onTap: () async {
                  bool block = await showAlertDialog(
                    context,
                    context.lang.deleteAllContactMessages,
                    context.lang.deleteAllContactMessagesBody(
                        getContactDisplayName(contact)),
                  );
                  if (block) {
                    if (context.mounted) {
                      await twonlyDatabase.messagesDao
                          .deleteMessagesByContactId(contact.userId);
                    }
                  }
                },
              ),
              BetterListTile(
                icon: FontAwesomeIcons.ban,
                color: Colors.red,
                text: context.lang.contactBlock,
                onTap: () async {
                  bool block = await showAlertDialog(
                    context,
                    context.lang
                        .contactBlockTitle(getContactDisplayName(contact)),
                    context.lang.contactBlockBody,
                  );
                  if (block) {
                    final update = ContactsCompanion(blocked: Value(true));
                    if (context.mounted) {
                      await twonlyDatabase.contactsDao
                          .updateContact(contact.userId, update);
                    }
                    if (context.mounted) {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<String?> showNicknameChangeDialog(
    BuildContext context, Contact contact) {
  final TextEditingController controller =
      TextEditingController(text: getContactDisplayName(contact));

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(context.lang.contactNickname),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration:
              InputDecoration(hintText: context.lang.contactNicknameNew),
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
