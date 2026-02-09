import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/components/context_menu.component.dart';

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
    return ContextMenu(
      items: [
        ContextMenuItem(
          title: context.lang.contextMenuUserProfile,
          onTap: () => context.push(Routes.profileContact(contact.userId)),
          icon: FontAwesomeIcons.user,
        ),
      ],
      child: child,
    );
  }
}
