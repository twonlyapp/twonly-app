import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

Future<bool> showAlertDialog(
    BuildContext context, String title, String content) async {
  Completer<bool> completer = Completer<bool>();

  Widget okButton = TextButton(
    child: Text(context.lang.ok),
    onPressed: () {
      completer.complete(true);
      Navigator.pop(context);
    },
  );

  Widget cancelButton = TextButton(
    child: Text(context.lang.cancel),
    onPressed: () {
      completer.complete(false);
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      cancelButton,
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
  return completer.future;
}
