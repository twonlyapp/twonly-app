import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:provider/provider.dart';
import 'package:twonly/src/model/contacts_model.dart';
import 'package:twonly/src/providers/send_next_media_to.dart';
import 'package:twonly/src/views/chats/chat_item_details_view.dart';
import 'package:twonly/src/views/contact/contact_verify_view.dart';
import 'package:twonly/src/views/home_view.dart';

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
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return ContactVerifyView(widget.user);
              },
            ));
          },
          child: widget.user.verified
              ? FaIcon(FontAwesomeIcons.shieldHeart)
              : const Icon(Icons.gpp_maybe_rounded), // Can be any widget
        ),
        PieAction(
          tooltip: const Text('Open chat'),
          onSelect: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                return ChatItemDetailsView(user: widget.user);
              },
            ));
          },
          child: const FaIcon(FontAwesomeIcons.solidComments),
        ),
        PieAction(
          tooltip: const Text('Send image'),
          onSelect: () {
            context
                .read<SendNextMediaTo>()
                .updateSendNextMediaTo(widget.user.userId.toInt());
            globalUpdateOfHomeViewPageIndex(0);
          },
          child: const FaIcon(FontAwesomeIcons.camera),
        ),
      ],
      child: widget.child,
    );
  }
}
