import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

Future<bool> showAlertDialog(
  BuildContext context,
  String title,
  String? content, {
  String? customOk,
  String? customCancel,
}) async {
  final Widget okButton = TextButton(
    child: Text(customOk ?? context.lang.ok),
    onPressed: () {
      Navigator.pop(context, true);
    },
  );

  final Widget cancelButton = TextButton(
    child: Text(customCancel ?? context.lang.cancel),
    onPressed: () {
      Navigator.pop(context, false);
    },
  );

  // set up the AlertDialog
  final alert = AlertDialog(
    title: Text(title),
    content: (content == null) ? null : Text(content),
    actions: [
      cancelButton,
      okButton,
    ],
  );

  // show the dialog
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return alert;
        },
      ) ??
      false;
}
