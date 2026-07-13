import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/context_menu/context_menu.helper.dart';

class UserContextMenu extends StatelessWidget {
  const UserContextMenu({
    required this.contact,
    required this.child,
    super.key,
  });
  final Widget child;
  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return ContextMenu(
      minWidth: 150,
      items: [
        ContextMenuItem(
          title: context.lang.contextMenuUserProfile,
          onTap: () => navigator.context.push(Routes.profileContact(contact.userId)),
          icon: FontAwesomeIcons.user,
        ),
      ],
      child: child,
    );
  }
}
