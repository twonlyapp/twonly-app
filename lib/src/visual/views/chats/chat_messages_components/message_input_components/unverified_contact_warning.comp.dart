import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/daos/key_verification.dao.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/profile.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/verification_badge.comp.dart';

class UnverifiedContactWarningComp extends StatelessWidget {
  const UnverifiedContactWarningComp({
    required this.group,
    required this.child,
    super.key,
  });

  final Group group;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        if (!userService
            .currentUser
            .securityProfile
            .showWarningForNonVerifiedContacts) {
          return child;
        }
        return StreamBuilder<VerificationStatus>(
          stream: twonlyDB.keyVerificationDao.watchAllGroupMembersVerified(
            group.groupId,
          ),
          builder: (context, snapshot) {
            final status = snapshot.data;
            if (status == null || status == VerificationStatus.trusted) {
              return child;
            }

            return Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: context.color.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: context.color.error.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    child: Row(
                      children: [
                        VerificationBadgeComp(
                          group: group,
                          size: 24,
                          clickable: false,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.isDirectChat
                                    ? context.lang.unverifiedWarningDirectTitle
                                    : context.lang.unverifiedWarningGroupTitle,
                                style: TextStyle(
                                  color: context.color.onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: context.color.onErrorContainer,
                                    fontSize: 11,
                                  ),
                                  children: formattedText(
                                    context,
                                    context.lang.unverifiedWarningBody,
                                    textColor: context.color.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 30,
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: context.color.onErrorContainer,
                              foregroundColor: context.color.errorContainer,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () async {
                              if (group.isDirectChat) {
                                await context.push(
                                  Routes.settingsHelpFaqVerifyBadge,
                                );
                              } else {
                                await context.push(
                                  Routes.profileGroup(group.groupId),
                                );
                              }
                            },
                            child: Text(context.lang.unverifiedWarningButton),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 5,
                    ),
                    child: child,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
