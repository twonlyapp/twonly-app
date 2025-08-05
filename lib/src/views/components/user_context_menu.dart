import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/chats/chat_messages.view.dart';
import 'package:twonly/src/views/contact/contact.view.dart';

class UserContextMenu extends StatefulWidget {
  const UserContextMenu({
    required this.contact,
    required this.child,
    super.key,
  });
  final Widget child;
  final Contact contact;

  @override
  State<UserContextMenu> createState() => _UserContextMenuState();
}

class _UserContextMenuState extends State<UserContextMenu> {
  @override
  Widget build(BuildContext context) {
    return PieMenu(
      onPressed: () => (),
      onToggle: (menuOpen) {
        if (menuOpen) {
          HapticFeedback.heavyImpact();
        }
      },
      actions: [
        if (!widget.contact.archived)
          PieAction(
            tooltip: Text(context.lang.contextMenuArchiveUser),
            onSelect: () async {
              const update = ContactsCompanion(archived: Value(true));
              if (context.mounted) {
                await twonlyDB.contactsDao
                    .updateContact(widget.contact.userId, update);
              }
            },
            child: const FaIcon(FontAwesomeIcons.boxArchive),
          ),
        if (widget.contact.archived)
          PieAction(
            tooltip: Text(context.lang.contextMenuUndoArchiveUser),
            onSelect: () async {
              const update = ContactsCompanion(archived: Value(false));
              if (context.mounted) {
                await twonlyDB.contactsDao
                    .updateContact(widget.contact.userId, update);
              }
            },
            child: const FaIcon(FontAwesomeIcons.boxOpen),
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
  const UserContextMenuBlocked({
    required this.contact,
    required this.child,
    super.key,
  });
  final Widget child;
  final Contact contact;

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
              const update = ContactsCompanion(archived: Value(true));
              if (context.mounted) {
                await twonlyDB.contactsDao
                    .updateContact(widget.contact.userId, update);
              }
            },
            child: const FaIcon(FontAwesomeIcons.boxArchive),
          ),
        if (widget.contact.archived)
          PieAction(
            tooltip: Text(context.lang.contextMenuUndoArchiveUser),
            onSelect: () async {
              const update = ContactsCompanion(archived: Value(false));
              if (context.mounted) {
                await twonlyDB.contactsDao
                    .updateContact(widget.contact.userId, update);
              }
            },
            child: const FaIcon(FontAwesomeIcons.boxOpen),
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
    tooltipPadding: const EdgeInsets.all(20),
    overlayColor: isDarkMode(context)
        ? const Color.fromARGB(69, 0, 0, 0)
        : const Color.fromARGB(40, 0, 0, 0),
    // spacing: 0,
    tooltipTextStyle: const TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w600,
    ),
  );
}
