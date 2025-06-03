import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/contact/contact.view.dart';
import 'package:twonly/src/views/contact/contact_verify.view.dart';

class UserContextMenu extends StatefulWidget {
  final Widget child;
  final Contact contact;

  const UserContextMenu({
    super.key,
    required this.contact,
    required this.child,
  });

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
                await twonlyDB.contactsDao
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
                await twonlyDB.contactsDao
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
                return ChatMessagesView(widget.contact);
              },
            ));
          },
          child: const FaIcon(FontAwesomeIcons.solidComments),
        ),
        PieAction(
          tooltip: Text(
            widget.contact.pinned
                ? context.lang.contextMenuUnpin
                : context.lang.contextMenuPin,
          ),
          onSelect: () async {
            final update =
                ContactsCompanion(pinned: Value(!widget.contact.pinned));
            if (context.mounted) {
              await twonlyDB.contactsDao
                  .updateContact(widget.contact.userId, update);
            }
          },
          child: FaIcon(widget.contact.pinned
              ? FontAwesomeIcons.thumbtackSlash
              : FontAwesomeIcons.thumbtack),
        ),
      ],
      child: widget.child,
    );
  }
}

class UserContextMenuBlocked extends StatefulWidget {
  final Widget child;
  final Contact contact;

  const UserContextMenuBlocked({
    super.key,
    required this.contact,
    required this.child,
  });

  @override
  State<UserContextMenuBlocked> createState() => _UserContextMenuBlocked();
}

class _UserContextMenuBlocked extends State<UserContextMenuBlocked> {
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
                await twonlyDB.contactsDao
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
                await twonlyDB.contactsDao
                    .updateContact(widget.contact.userId, update);
              }
            },
            child: FaIcon(FontAwesomeIcons.boxOpen),
          ),
        PieAction(
          tooltip: Text(context.lang.contextMenuUserProfile),
          onSelect: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return ContactView(widget.contact.userId);
              },
            ));
          },
          child: const FaIcon(FontAwesomeIcons.user),
        ),
      ],
      child: widget.child,
    );
  }
}

PieTheme getPieCanvasTheme(BuildContext context) {
  return PieTheme(
    brightness: Theme.of(context).brightness,
    rightClickShowsMenu: true,
    radius: 70,
    buttonTheme: PieButtonTheme(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      iconColor: Theme.of(context).colorScheme.surfaceBright,
    ),
    buttonThemeHovered: PieButtonTheme(
      backgroundColor: Theme.of(context).colorScheme.primary,
      iconColor: Theme.of(context).colorScheme.surfaceBright,
    ),
    tooltipPadding: EdgeInsets.all(20),
    overlayColor: const Color.fromARGB(41, 0, 0, 0),

    // spacing: 0,
    tooltipTextStyle: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
  );
}
