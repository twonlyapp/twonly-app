import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/daos/contacts_dao.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/services/api/utils.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/components/better_list_title.dart';
import 'package:twonly/src/views/components/flame.dart';
import 'package:twonly/src/views/components/initialsavatar.dart';
import 'package:twonly/src/views/components/verified_shield.dart';
import 'package:twonly/src/views/contact/contact_verify.view.dart';

class ContactView extends StatefulWidget {
  const ContactView(this.userId, {super.key});

  final int userId;

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  Future<void> handleUserRemoveRequest(Contact contact) async {
    final remove = await showAlertDialog(
      context,
      context.lang.contactRemoveTitle(getContactDisplayName(contact)),
      context.lang.contactRemoveBody,
    );
    if (remove) {
      // trigger deletion for the other user...
      await rejectUser(contact.userId);
      await deleteContact(contact.userId);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  Future<void> handleUserBlockRequest(Contact contact) async {
    final block = await showAlertDialog(
      context,
      context.lang.contactBlockTitle(getContactDisplayName(contact)),
      context.lang.contactBlockBody,
    );
    if (block) {
      const update = ContactsCompanion(blocked: Value(true));
      if (context.mounted) {
        await twonlyDB.contactsDao.updateContact(contact.userId, update);
      }
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = twonlyDB.contactsDao
        .getContactByUserId(widget.userId)
        .watchSingleOrNull();

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: StreamBuilder(
        stream: contact,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return Container();
          }
          final contact = snapshot.data!;
          final flameCounter = getFlameCounterFromContact(contact);
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
                      padding: const EdgeInsets.only(right: 10),
                      child: VerifiedShield(contact)),
                  Text(
                    getContactDisplayName(contact),
                    style: const TextStyle(fontSize: 20),
                  ),
                  if (flameCounter > 0)
                    FlameCounterWidget(
                      contact,
                      flameCounter,
                      prefix: true,
                    ),
                ],
              ),
              if (getContactDisplayName(contact) != contact.username)
                Center(child: Text('(${contact.username})')),
              const SizedBox(height: 50),
              BetterListTile(
                icon: FontAwesomeIcons.pencil,
                text: context.lang.contactNickname,
                onTap: () async {
                  final nickName =
                      await showNicknameChangeDialog(context, contact);

                  if (context.mounted && nickName != null && nickName != '') {
                    final update = ContactsCompanion(nickName: Value(nickName));
                    await twonlyDB.contactsDao
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
                icon: FontAwesomeIcons.eraser,
                iconSize: 16,
                text: context.lang.deleteAllContactMessages,
                onTap: () async {
                  final block = await showAlertDialog(
                    context,
                    context.lang.deleteAllContactMessages,
                    context.lang.deleteAllContactMessagesBody(
                        getContactDisplayName(contact)),
                  );
                  if (block) {
                    if (context.mounted) {
                      await twonlyDB.messagesDao
                          .deleteMessagesByContactId(contact.userId);
                    }
                  }
                },
              ),
              BetterListTile(
                icon: FontAwesomeIcons.ban,
                color: Colors.red,
                text: context.lang.contactBlock,
                onTap: () => handleUserBlockRequest(contact),
              ),
              BetterListTile(
                icon: FontAwesomeIcons.userMinus,
                iconSize: 16,
                color: Colors.red,
                text: context.lang.contactRemove,
                onTap: () => handleUserRemoveRequest(contact),
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
  final controller =
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
