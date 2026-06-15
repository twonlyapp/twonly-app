import 'package:flutter/material.dart';
import 'package:twonly/src/model/protobuf/client/generated/qr.pb.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

/// A premium popup dialog shown when a new user profile is scanned via QR code.
/// Allows the user to request connection ("Anfragen") or cancel ("Abbrechen").
class AddContactDialog extends StatelessWidget {
  const AddContactDialog({
    required this.profile,
    super.key,
  });

  final PublicProfile profile;

  /// Utility method to easily present this dialog.
  /// Returns `true` if the user chose to request the contact, `false` otherwise.
  static Future<bool?> show(BuildContext context, PublicProfile profile) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddContactDialog(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AvatarIcon(
                  fontSize: 16,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    profile.username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              context.lang.userFoundBody(profile.username),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: MyButton(
                    variant: MyButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(context.lang.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MyButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(context.lang.friendSuggestionsRequest),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
