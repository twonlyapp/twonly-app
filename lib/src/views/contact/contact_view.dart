import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/alert_dialog.dart';
import 'package:twonly/src/components/better_list_title.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/components/verified_shield.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/providers/contacts_change_provider.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/contact/contact_verify_view.dart';

class ContactView extends StatefulWidget {
  const ContactView(this.userId, {super.key});

  final int userId;

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  @override
  Widget build(BuildContext context) {
    Contact contact = context
        .watch<ContactChangeProvider>()
        .allContacts
        .firstWhere((c) => c.userId == widget.userId);

    int flameCounter = context
            .watch<MessagesChangeProvider>()
            .flamesCounter[contact.userId.toInt()] ??
        0;

    return Scaffold(
      appBar: AppBar(
        title: Text(""),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: InitialsAvatar(
              displayName: contact.displayName,
              fontSize: 30,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: VerifiedShield(contact)),
              Text(
                contact.displayName,
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
          SizedBox(height: 50),
          BetterListTile(
            icon: FontAwesomeIcons.pencil,
            text: context.lang.contactNickname,
            onTap: () async {
              String? newUsername =
                  await showNicknameChangeDialog(context, contact);
              if (newUsername != null && newUsername != "") {
                await DbContacts.changeDisplayName(
                    contact.userId.toInt(), newUsername);
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
            icon: FontAwesomeIcons.ban,
            color: Colors.red,
            text: context.lang.contactBlock,
            onTap: () async {
              bool block = await showAlertDialog(
                context,
                context.lang.contactBlockTitle(contact.displayName),
                context.lang.contactBlockBody,
              );
              if (block) {
                await DbContacts.blockUser(contact.userId.toInt());
                // go back to the first
                if (context.mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

Future<String?> showNicknameChangeDialog(
    BuildContext context, Contact contact) {
  final TextEditingController controller =
      TextEditingController(text: contact.displayName);

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Change nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: "New nickname"),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            child: Text('Submit'),
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
