import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';

class FeedbackIconButtonComp extends StatefulWidget {
  const FeedbackIconButtonComp({super.key});

  @override
  State<FeedbackIconButtonComp> createState() => _FeedbackIconButtonCompState();
}

class _FeedbackIconButtonCompState extends State<FeedbackIconButtonComp> {
  bool showFeedbackShortcut = false;

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
  }

  Future<void> initAsync() async {
    final user = await getUser();
    if (user == null || !mounted) return;
    setState(() {
      showFeedbackShortcut = user.showFeedbackShortcut;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!showFeedbackShortcut) {
      return const SizedBox.shrink();
    }

    return IconButton(
      onPressed: () => context.push(Routes.settingsHelpContactUs),
      color: Colors.grey,
      tooltip: context.lang.feedbackTooltip,
      icon: const FaIcon(FontAwesomeIcons.commentDots, size: 19),
    );
  }
}
