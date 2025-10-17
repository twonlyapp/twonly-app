import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

Future<void> showTutorial(
  BuildContext context,
  List<TargetFocus> targets,
) async {
  final completer = Completer<dynamic>();
  TutorialCoachMark(
    targets: targets,
    colorShadow: context.color.primary,
    textSkip: context.lang.ok,
    alignSkip: Alignment.bottomCenter,
    textStyleSkip: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    onSkip: () {
      completer.complete();
      return true;
    },
    onFinish: () {
      completer.complete();
    },
  ).show(context: context);

  await completer.future;
}

Future<bool> checkIfTutorialAlreadyShown(String tutorialId) async {
  final user = await getUser();
  if (user == null) return true;
  user.tutorialDisplayed ??= [];
  if (user.tutorialDisplayed!.contains(tutorialId)) {
    return true;
  }
  user.tutorialDisplayed!.add(tutorialId);

  await updateUserdata((u) {
    u.tutorialDisplayed = user.tutorialDisplayed;
    return u;
  });

  return false;
}

TargetFocus getTargetFocus(
  BuildContext context,
  GlobalKey key,
  String title,
  String body,
) {
  final renderBox = key.currentContext!.findRenderObject()! as RenderBox;
  final position = renderBox.localToGlobal(Offset.zero);
  final screenHeight = MediaQuery.of(context).size.height;
  final centerY = screenHeight / 2;

  double top = 0;
  double bottom = 0;

  if (position.dy < centerY) {
    bottom = 0;
    top = position.dy;
  } else {
    bottom = centerY;
    top = 0;
  }

  return TargetFocus(
    identify: title,
    keyTarget: key,
    contents: [
      TargetContent(
        align: ContentAlign.custom,
        customPosition: CustomTargetContentPosition(
          left: 0,
          right: 0,
          top: top,
          bottom: bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
