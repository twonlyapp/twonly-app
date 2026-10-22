import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/core/bridge/database/recovery.dart' as rust_recovery;
import 'package:twonly/core/database/app/recovery/table.dart' as db_recovery;
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/settings.passwordless_recovery.view.dart';

class PasswordLessRecoveryStatus extends StatelessWidget {
  const PasswordLessRecoveryStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: watchRustDatabase(
        (control) => rust_recovery.watchRecoveryCount(
          selection: db_recovery.RecoveryContacts.trusted,
          control: control,
        ),
      ),
      builder: (context, snapshot) {
        final trustedFriendsCount = snapshot.data ?? 0;

        return Card(
          elevation: 0,
          color: context.color.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.navPush(const PasswordLessRecoverySettings());
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.color.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.shieldHeart,
                      color: context.color.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.lang.passwordlessRecovery,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.lang.passwordlessRecoveryStatusEnabled(
                            trustedFriendsCount,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.color.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.color.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
