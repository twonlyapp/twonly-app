import 'package:flutter/material.dart';
import 'package:twonly/src/database/daos/contacts.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/components/verification_success_animation.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

/// A premium popup dialog shown when a contact's public key has been successfully verified.
class VerificationSuccessDialog extends StatelessWidget {
  const VerificationSuccessDialog({
    required this.contact,
    this.message,
    super.key,
  });

  final Contact contact;
  final String? message;

  /// Utility method to easily present this dialog.
  static Future<void> show(BuildContext context, Contact contact, {String? message}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationSuccessDialog(contact: contact, message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = getContactDisplayName(contact);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AvatarIcon(
                  contactId: contact.userId,
                  fontSize: 16,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const VerificationSuccessAnimation(
              size: 160,
            ),
            const SizedBox(height: 24),
            Text(
              message ?? context.lang.verifiedPublicKey(displayName),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 28),
            MyButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.lang.close),
            ),
          ],
        ),
      ),
    );
  }
}
