import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/notification_badge.comp.dart';
import 'package:twonly/src/visual/themes/light.dart';

class ContactRequestBadgeComp extends StatelessWidget {
  const ContactRequestBadgeComp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: twonlyDB.contactsDao.watchContactsRequestedCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        if (count == 0) {
          return const SizedBox.shrink();
        }
        return Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Center(
              child: NotificationBadgeComp(
                backgroundColor: isDarkMode(context) ? Colors.white : Colors.black,
                textColor: isDarkMode(context) ? Colors.black : Colors.white,
                count: count.toString(),
                child: IconButton(
                  color: Colors.black,
                  icon: const FaIcon(
                    FontAwesomeIcons.userPlus,
                    size: 18,
                  ),
                  onPressed: () => context.push(Routes.chatsAddNewUser),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
