import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
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
  State<UserContextMenu> createState() => _UserContextMenuBlocked();
}

class _UserContextMenuBlocked extends State<UserContextMenu> {
  @override
  Widget build(BuildContext context) {
    return PieMenu(
      onPressed: () => (),
      actions: [
        PieAction(
          tooltip: Text(context.lang.contextMenuUserProfile),
          onSelect: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ContactView(widget.contact.userId);
                },
              ),
            );
          },
          child: const FaIcon(FontAwesomeIcons.user),
        ),
      ],
      child: widget.child,
    );
  }
}
