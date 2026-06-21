import 'package:flutter/material.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/contact_chip.element.dart';
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
                return ContactChip(
                  key: ValueKey(contact.userId),
                  contact: contact,
                  onTap: onRemoveContact,
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
                      ? context.lang.passwordlessRecoverySelectFriendsNeeded(
                          missingCount,
                        )
                      : context.lang.passwordlessRecoverySelectFriends,
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
            context.lang.passwordlessRecoveryNoFriendsSelected,
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
