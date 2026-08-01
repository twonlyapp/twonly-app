import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/notification_badge.comp.dart';

class NewsIconButtonComp extends StatelessWidget {
  const NewsIconButtonComp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: userService.onUserUpdated,
      builder: (context, snapshot) {
        if (!userService.currentUser.showNewsShortcut) {
          return const SizedBox.shrink();
        }
        return ValueListenableBuilder<int>(
          valueListenable: newsService.unreadCountNotifier,
          builder: (context, count, child) {
            return NotificationBadgeComp(
              count: count.toString(),
              backgroundColor: context.color.primary,
              textColor: Colors.black87,
              child: IconButton(
                onPressed: () => context.push(Routes.settingsHelpNews),
                color: Colors.grey,
                tooltip: context.lang.settingsHelpNews,
                icon: const FaIcon(FontAwesomeIcons.bullhorn, size: 19),
              ),
            );
          },
        );
      },
    );
  }
}
