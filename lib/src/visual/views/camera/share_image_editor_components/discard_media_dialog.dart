import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

/// Asks the user whether the media and all its edits should be thrown away.
Future<bool> askToDiscardMedia(BuildContext context) async {
  final shouldDiscard = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(context.lang.dialogAskDeleteMediaFilePopTitle),
        actions: [
          MyButton(
            variant: MyButtonVariant.primaryMiddle,
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text(context.lang.dialogAskDeleteMediaFilePopDelete),
          ),
          TextButton(
            child: Text(context.lang.cancel),
            onPressed: () {
              Navigator.pop(context, false);
            },
          ),
        ],
      );
    },
  );
  return shouldDiscard ?? false;
}
