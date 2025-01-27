import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:twonly/src/model/contacts_model.dart';

class UserContextMenu extends StatefulWidget {
  final Widget child;
  final Contact user;

  const UserContextMenu({super.key, required this.user, required this.child});

  @override
  State<UserContextMenu> createState() => _UserContextMenuState();
}

class _UserContextMenuState extends State<UserContextMenu> {
  @override
  Widget build(BuildContext context) {
    return PieMenu(
      onPressed: () => print('pressed'),
      actions: [
        PieAction(
          tooltip: const Text('Verify user'),
          onSelect: () {
            print('Verify user selected');
          },
          child: const Icon(Icons.gpp_maybe_rounded), // Can be any widget
        ),
        PieAction(
          tooltip: const Text('Send image'),
          onSelect: () {
            print('Send image selected');
          },
          child: const FaIcon(FontAwesomeIcons.camera),
        ),
      ],
      child: widget.child,
    );
  }
}
