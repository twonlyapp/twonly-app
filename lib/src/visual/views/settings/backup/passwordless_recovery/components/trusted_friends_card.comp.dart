import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class TrustedFriendsCard extends StatelessWidget {
  const TrustedFriendsCard({
    required this.selectedContacts,
    required this.needsMoreFriends,
    required this.missingCount,
    required this.onSelectFriends,
    required this.onRemoveContact,
    super.key,
  });

  final List<Contact> selectedContacts;
  final bool needsMoreFriends;
  final int missingCount;
  final VoidCallback onSelectFriends;
  final void Function(int userId) onRemoveContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.color.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selectedContacts.isEmpty)
            _buildEmptyState(context)
          else
            Wrap(
              spacing: 4,
              alignment: WrapAlignment.center,
              children: selectedContacts.map((contact) {
                return _ContactChip(
                  key: ValueKey(contact.userId),
                  contact: contact,
                  onRemove: onRemoveContact,
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          MyButton(
            variant: needsMoreFriends
                ? MyButtonVariant.error
                : MyButtonVariant.secondaryDense,
            onPressed: onSelectFriends,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_moderator_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  needsMoreFriends
                      ? 'Select friends ($missingCount more needed)'
                      : 'Select trusted friends',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 48,
            color: context.color.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'No trusted friends selected yet',
            style: TextStyle(
              fontSize: 14,
              color: context.color.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ContactChip extends StatelessWidget {
  const _ContactChip({
    required this.contact,
    required this.onRemove,
    super.key,
  });

  final Contact contact;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onRemove(contact.userId),
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
            const SizedBox(width: 15),
            const FaIcon(
              FontAwesomeIcons.xmark,
              color: Colors.grey,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
