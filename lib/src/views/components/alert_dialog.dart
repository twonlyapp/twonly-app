import 'dart:async';

import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

Future<bool> showAlertDialog(
  BuildContext context,
  String title,
  String? content, {
  String? customOk,
  String? customCancel,
}) async {
  final completer = Completer<bool>();

  final Widget okButton = TextButton(
    child: Text(customOk ?? context.lang.ok),
    onPressed: () {
      completer.complete(true);
      Navigator.pop(context);
    },
  );

  final Widget cancelButton = TextButton(
    child: Text(customCancel ?? context.lang.cancel),
    onPressed: () {
      completer.complete(false);
      Navigator.pop(context);
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
  // ignore: inference_failure_on_function_invocation
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
  return completer.future;
}
