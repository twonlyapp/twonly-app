import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/camera_to_share/camera_send_to_view.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';
import 'package:twonly/src/views/contact/contact_verify_view.dart';

class UserContextMenu extends StatefulWidget {
  final Widget child;
  final Contact contact;

  const UserContextMenu(
      {super.key, required this.contact, required this.child});

  @override
  State<UserContextMenu> createState() => _UserContextMenuState();
}

class _UserContextMenuState extends State<UserContextMenu> {
  @override
  Widget build(BuildContext context) {
    return PieMenu(
      onPressed: () => (),
      actions: [
        if (!widget.contact.archived)
          PieAction(
            tooltip: Text(context.lang.contextMenuArchiveUser),
            onSelect: () async {
              final update = ContactsCompanion(archived: Value(true));
              if (context.mounted) {
                await twonlyDatabase.contactsDao
                    .updateContact(widget.contact.userId, update);
              }
            },
            child: FaIcon(FontAwesomeIcons.boxArchive),
          ),
        if (widget.contact.archived)
          PieAction(
            tooltip: Text(context.lang.contextMenuUndoArchiveUser),
            onSelect: () async {
              final update = ContactsCompanion(archived: Value(false));
              if (context.mounted) {
                await twonlyDatabase.contactsDao
                    .updateContact(widget.contact.userId, update);
              }
            },
            child: FaIcon(FontAwesomeIcons.boxOpen),
          ),
        if (!widget.contact.verified)
          PieAction(
            tooltip: Text(context.lang.contextMenuVerifyUser),
            onSelect: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return ContactVerifyView(widget.contact);
                },
              ));
            },
            child: const Icon(Icons.gpp_maybe_rounded),
          ),
        PieAction(
          tooltip: Text(context.lang.contextMenuOpenChat),
          onSelect: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return ChatItemDetailsView(widget.contact);
              },
            ));
          },
          child: const FaIcon(FontAwesomeIcons.solidComments),
        ),
        PieAction(
          tooltip: Text(context.lang.contextMenuSendImage),
          onSelect: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return CameraSendToView(widget.contact);
              },
            ));
          },
          child: const FaIcon(FontAwesomeIcons.camera),
        ),
      ],
      child: widget.child,
    );
  }
}
