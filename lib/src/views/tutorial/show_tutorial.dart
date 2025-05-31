import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

Future showTutorial(BuildContext context, List<TargetFocus> targets) async {
  Completer completer = Completer();
  TutorialCoachMark(
    targets: targets,
    colorShadow: context.color.primary,
    textSkip: context.lang.ok,
    alignSkip: Alignment.bottomCenter,
    textStyleSkip: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
    onClickTarget: (target) {
      print(target);
    },
    onClickTargetWithTapPosition: (target, tapDetails) {
      print("target: $target");
      print(
          "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
    },
    onClickOverlay: (target) {
      print(target);
    },
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
  await updateUser(user);
  return false;
}

TargetFocus getTargetFocus(
    BuildContext context, GlobalKey key, String title, String body) {
  RenderBox renderBox = key.currentContext?.findRenderObject() as RenderBox;
  Offset position = renderBox.localToGlobal(Offset.zero);
  double screenHeight = MediaQuery.of(context).size.height;
  double centerY = screenHeight / 2;

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
            left: 0, right: 0, top: top, bottom: bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            )
          ],
        ),
      )
    ],
  );
}
