import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/avatar_icon.comp.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class AddContactDialog extends StatelessWidget {
  const AddContactDialog({
    required this.username,
    super.key,
  });

  final String username;

  static Future<bool?> show(BuildContext context, String username) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddContactDialog(username: username),
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
                    username,
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
              context.lang.userFoundBody(username),
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
