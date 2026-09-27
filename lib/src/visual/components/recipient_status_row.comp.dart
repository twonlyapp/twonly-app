import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';

/// One recipient of something the user sent, with what last happened to it
/// there ("Opened", "Received", ...) and when.
class RecipientStatusRow extends StatelessWidget {
  const RecipientStatusRow({
    required this.contact,
    required this.status,
    required this.at,
    this.badge,
    super.key,
  });

  final Contact contact;
  final String status;
  final DateTime at;

  /// Shown after the name, e.g. that the recipient saved it.
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          AvatarIcon(contactId: contact.userId, fontSize: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    getContactDisplayName(contact),
                    style: const TextStyle(fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badge != null) ...[const SizedBox(width: 6), badge!],
              ],
            ),
          ),
          Column(
            children: [
              Text(
                friendlyDateTime(context, at),
                style: const TextStyle(fontSize: 12),
              ),
              Text(status),
            ],
          ),
        ],
      ),
    );
  }
}
