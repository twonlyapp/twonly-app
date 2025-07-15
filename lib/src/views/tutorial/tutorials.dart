import 'package:flutter/material.dart';
import 'package:mutex/mutex.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/tutorial/show_tutorial.dart';

final lockDisplayTutorial = Mutex();

Future<void> showChatListTutorialSearchOtherUsers(
  BuildContext context,
  GlobalKey searchForOtherUsers,
) async {
  await lockDisplayTutorial.protect(() async {
    if (await checkIfTutorialAlreadyShown('chat_list:search_users')) {
      return;
    }
    if (!context.mounted) return;
    final targets = <TargetFocus>[
      getTargetFocus(
        context,
        searchForOtherUsers,
        context.lang.tutorialChatListSearchUsersTitle,
        context.lang.tutorialChatListSearchUsersDesc,
      )
    ];
    await showTutorial(context, targets);
  });
}

Future<void> showChatListTutorialContextMenu(
  BuildContext context,
  GlobalKey firstUserListItemKey,
) async {
  await lockDisplayTutorial.protect(() async {
    if (await checkIfTutorialAlreadyShown('chat_list:context_menu')) {
      return;
    }
    if (!context.mounted) return;
    final targets = <TargetFocus>[
      getTargetFocus(
        context,
        firstUserListItemKey,
        context.lang.tutorialChatListContextMenuTitle,
        context.lang.tutorialChatListContextMenuDesc,
      )
    ];
    await showTutorial(context, targets);
  });
}

Future<void> showVerifyShieldTutorial(
  BuildContext context,
  GlobalKey firstUserListItemKey,
) async {
  await lockDisplayTutorial.protect(() async {
    if (await checkIfTutorialAlreadyShown('chat_messages:verify_shield')) {
      return;
    }
    if (!context.mounted) return;
    final targets = <TargetFocus>[
      getTargetFocus(
        context,
        firstUserListItemKey,
        context.lang.tutorialChatMessagesVerifyShieldTitle,
        context.lang.tutorialChatMessagesVerifyShieldDesc,
      )
    ];
    await showTutorial(context, targets);
  });
}

Future<void> showReopenMediaFilesTutorial(
  BuildContext context,
  GlobalKey firstUserListItemKey,
) async {
  await lockDisplayTutorial.protect(() async {
    if (await checkIfTutorialAlreadyShown('chat_messages:reopen_message')) {
      return;
    }
    if (!context.mounted) return;
    final targets = <TargetFocus>[
      getTargetFocus(
        context,
        firstUserListItemKey,
        context.lang.tutorialChatMessagesReopenMessageTitle,
        context.lang.tutorialChatMessagesReopenMessageDesc,
      )
    ];
    await showTutorial(context, targets);
  });
}
