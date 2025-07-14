import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/twonly_database.dart';
import 'package:twonly/src/views/contact/contact_verify.view.dart';

class VerifiedShield extends StatelessWidget {
  const VerifiedShield(this.contact, {super.key, this.size = 18});
  final Contact contact;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) {
            return ContactVerifyView(contact);
          },
        ));
      },
      child: Tooltip(
        message: contact.verified
            ? 'You verified this contact'
            : 'You have not verifies this contact.',
        child: FaIcon(
          contact.verified
              ? FontAwesomeIcons.shieldHeart
              : Icons.gpp_maybe_rounded,
          color: contact.verified
              ? Theme.of(context).colorScheme.primary
              : Colors.red,
          size: size,
        ),
      ),
    );
  }
}
