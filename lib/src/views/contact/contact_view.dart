import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/components/alert_dialog.dart';
import 'package:twonly/src/components/better_list_title.dart';
import 'package:twonly/src/components/flame.dart';
import 'package:twonly/src/components/initialsavatar.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/providers/messages_change_provider.dart';
import 'package:twonly/src/views/contact/contact_verify_view.dart';

class ContactView extends StatefulWidget {
  const ContactView(this.contact, {super.key});

  final Contact contact;

  @override
  State<ContactView> createState() => _ContactViewState();
}

class _ContactViewState extends State<ContactView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int flameCounter = context
            .watch<MessagesChangeProvider>()
            .flamesCounter[widget.contact.userId.toInt()] ??
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
              displayName: widget.contact.displayName,
              fontSize: 30,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.contact.displayName,
                style: TextStyle(fontSize: 20),
              ),
              if (flameCounter > 0)
                FlameCounterWidget(widget.contact, flameCounter, 110000000),
            ],
          ),
          SizedBox(height: 50),
          BetterListTile(
            icon: FontAwesomeIcons.pencil,
            text: "Nickname",
            onTap: () async {
              String? newUsername =
                  await showNicknameChangeDialog(context, widget.contact);
              if (newUsername != null && newUsername != "") {
                await DbContacts.changeDisplayName(
                    widget.contact.userId.toInt(), newUsername);
              }
            },
          ),
          const Divider(),
          BetterListTile(
            icon: FontAwesomeIcons.shieldHeart,
            text: "Verify safety number",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return ContactVerifyView(widget.contact);
                },
              ));
            },
          ),
          BetterListTile(
            icon: FontAwesomeIcons.ban,
            color: Colors.red,
            text: "Block",
            onTap: () async {
              bool block = await showAlertDialog(
                  context,
                  "Block ${widget.contact.displayName}",
                  "A blocked user will no longer be able to send you messages and their profile will be hidden from view. To unblock a user, simply navigate to Settings > Privacy > Blocked Users..");
              if (block) {
                await DbContacts.blockUser(widget.contact.userId.toInt());
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
              String inputText = controller.text;
              Navigator.of(context).pop(inputText); // Return the input text
            },
          ),
        ],
      );
    },
  );
}
