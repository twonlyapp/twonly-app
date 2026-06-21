import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/elements/reactive_tap_feedback.element.dart';
import 'package:twonly/src/visual/views/contact/contact.view.dart';

class ContactChip extends StatelessWidget {
  const ContactChip({
    required this.contact,
    this.onTap,
    super.key,
  });

  final Contact contact;
  final void Function(int)? onTap;

  @override
  Widget build(BuildContext context) {
    return ReactiveTapFeedback(
      onTap: () {
        if (onTap != null) {
          onTap!(contact.userId);
        } else {
          context.navPush(
            ContactView(
              contact.userId,
              key: ValueKey(contact.userId),
            ),
          );
        }
      },
      child: Chip(
        avatar: AvatarIcon(
          contactId: contact.userId,
          fontSize: 10,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getContactDisplayName(contact),
              style: const TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 6),
            VerificationBadgeComp(
              contact: contact,
              size: 12,
              clickable: false,
            ),
            if (onTap != null) ...[
              const SizedBox(width: 15),
              const FaIcon(
                FontAwesomeIcons.xmark,
                color: Colors.grey,
                size: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
