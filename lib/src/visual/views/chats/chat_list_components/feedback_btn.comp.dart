import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';

class FeedbackIconButtonComp extends StatelessWidget {
  const FeedbackIconButtonComp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: userService.onUserUpdated,
      builder: (context, asyncSnapshot) {
        if (!userService.currentUser.showFeedbackShortcut) {
          return const SizedBox.shrink();
        }
        return IconButton(
          onPressed: () => context.push(Routes.settingsHelpContactUs),
          color: Colors.grey,
          tooltip: context.lang.feedbackTooltip,
          icon: const FaIcon(FontAwesomeIcons.commentDots, size: 19),
        );
      },
    );
  }
}
