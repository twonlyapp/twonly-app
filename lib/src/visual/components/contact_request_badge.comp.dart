import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/core/bridge/database/contacts.dart' as rust_contacts;
import 'package:twonly/core/database/app/contacts/table.dart' as db_contacts;
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/notification_badge.comp.dart';

class ContactRequestBadgeComp extends StatelessWidget {
  const ContactRequestBadgeComp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int?>(
      stream: watchRustDatabase(
        (control) => rust_contacts.watchContactsCount(
          metric: db_contacts.ContactCount.requested,
          control: control,
        ),
      ),
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
                  decoration: BoxDecoration(
                    color: context.color.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Center(
              child: NotificationBadgeComp(
                backgroundColor: context.color.inverseSurface,
                textColor: context.color.onInverseSurface,
                count: count.toString(),
                child: IconButton(
                  color: context.color.onPrimary,
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
